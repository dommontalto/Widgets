//
//  BrightSendFlight.swift
//  Widgets
//
//  Created by Dom Montalto on 17/9/2026.
//

import SwiftUI
import UIKit

// The coordinate space the chat puts around its input card, so a bubble in
// flight can be laid over the exact field the words were typed in.
enum BrightChatSpace {
    static let input = "brightChatInput"
}

// A sent message lifts out of the input field rather than sliding in from
// nowhere: the bubble is drawn over the field, the thread holds its own copy
// back, and matched geometry carries one into the other.
@MainActor
@Observable
final class BrightSendFlight {
    private(set) var text = ""
    private(set) var attachments = [BrightChatAttachment]()
    // Set the moment the message goes out — before the caller has appended it
    // — so the thread can hold the bubble back on the very first frame it
    // exists, and never flashes it in its landed place.
    private(set) var isWaiting = false
    // A message that fits the field on one line morphs its width on the way
    // up; a taller one only travels, or matching the size squashes its lines
    // together. Stays on until the flight settles.
    private(set) var isFitted = false
    var fieldFrame: CGRect = .zero
    // The thread's last message when the send went out. Until something newer
    // than this arrives the flight has nothing to carry, so the message that
    // was already there is never mistaken for the one being sent.
    private(set) var precedingID: UUID?

    // The bubble's own text size and horizontal padding, so the fit is judged
    // against the width it will actually take.
    func begin(
        text: String,
        attachments: [BrightChatAttachment] = [],
        after precedingID: UUID? = nil,
        textSize: FontSizes = .subheading,
        horizontalPadding: CGFloat = .spacing2x
    ) {
        self.text = text
        self.attachments = attachments
        self.precedingID = precedingID
        isWaiting = true
        isFitted = attachments.isEmpty
            && fitsOneLine(text, textSize: textSize, horizontalPadding: horizontalPadding)
    }

    func isNew(_ id: UUID) -> Bool {
        id != precedingID
    }

    // Called once the message has arrived in the thread. The bubble and the
    // copy over the field share the screen for one turn, so the matched
    // geometry has somewhere to fly from.
    func land() {
        guard isWaiting else { return }
        Task { @MainActor in
            withAnimation(.brightSendFlight, completionCriteria: .removed) {
                isWaiting = false
            } completion: {
                self.isFitted = false
            }
        }
    }

    private func fitsOneLine(_ text: String, textSize: FontSizes, horizontalPadding: CGFloat) -> Bool {
        guard fieldFrame.width > 0,
              let font = Font.standardUIFont(size: textSize, weight: .light)
        else { return false }
        let width = NSString(string: text).size(withAttributes: [.font: font]).width
        return width < fieldFrame.width - horizontalPadding * 2
    }
}

extension View {
    // The copy laid over the input field, where the words were typed.
    func brightSendSource(_ flight: BrightSendFlight, id: UUID, in namespace: Namespace.ID) -> some View {
        frame(maxWidth: flight.isFitted ? .infinity : nil, alignment: .leading)
            .matchedGeometryEffect(
                id: id,
                in: namespace,
                properties: flight.isFitted ? [.position, .size] : [.position]
            )
            .frame(width: flight.fieldFrame.width, alignment: .leading)
            .offset(x: flight.fieldFrame.minX, y: flight.fieldFrame.minY)
            .allowsHitTesting(false)
    }

    // The bubble in the thread, held back while the source is on screen.
    // `isFitted` belongs to the one message in flight: the whole thread reads
    // the same flight, so a shared flag would balloon every other sent bubble
    // to the field's width alongside it.
    func brightSendDestination(
        _ flight: BrightSendFlight,
        isHeld: Bool,
        isFitted: Bool,
        id: UUID,
        in namespace: Namespace.ID
    ) -> some View {
        modifier(BrightSendDestination(flight: flight, isHeld: isHeld, isFitted: isFitted, id: id, namespace: namespace))
    }
}

private struct BrightSendDestination: ViewModifier {
    let flight: BrightSendFlight
    let isHeld: Bool
    let isFitted: Bool
    let id: UUID
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        ZStack {
            if !isHeld {
                content
                    .frame(maxWidth: isFitted ? .infinity : nil, alignment: .leading)
                    .matchedGeometryEffect(
                        id: id,
                        in: namespace,
                        properties: isFitted ? [.position, .size] : [.position]
                    )
            }
        }
        // Hugging its text only once it has landed lets the wide field-shaped
        // source collapse into the bubble on the way.
        .fixedSize(horizontal: isFitted ? !isHeld : false, vertical: true)
        .compositingGroup()
        // The thread takes the bubble's weight as it arrives: it dips and
        // springs back, so the message reads as having been dropped in.
        .keyframeAnimator(initialValue: CGFloat.zero, trigger: isHeld) { [height = flight.fieldFrame.height, push = Constants.pushFraction] content, progress in
            content.offset(y: height * push * progress)
        } keyframes: { _ in
            CubicKeyframe(1, duration: Constants.pushDuration)
            CubicKeyframe(0, duration: Constants.pushDuration)
        }
    }

    private enum Constants {
        static let pushFraction: CGFloat = 0.55
        static let pushDuration: TimeInterval = 0.15
    }
}
