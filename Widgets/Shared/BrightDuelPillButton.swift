//
//  BrightDuelPillButton.swift
//  Bright
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

// Two pills that answer the same question — a get-out beside the action that
// finishes it. The trailing pill runs twice the leading's width, so the
// affirmative choice reads as the bigger target.
struct BrightDuelPillButton: View {
    let leadingTitle: String
    let trailingTitle: String
    let leadingSystemImage: String?
    let trailingSystemImage: String?
    let leadingColor: Color?
    let trailingColor: Color?
    let size: FontSizes?
    let buttonSize: BrightButtonSizes
    let onLeadingTap: () -> Void
    let onTrailingTap: () -> Void

    init(
        _ leadingTitle: String,
        _ trailingTitle: String,
        leadingSystemImage: String? = nil,
        trailingSystemImage: String? = nil,
        leadingColor: Color? = nil,
        trailingColor: Color? = nil,
        size: FontSizes? = nil,
        buttonSize: BrightButtonSizes = .large,
        onLeadingTap: @escaping () -> Void,
        onTrailingTap: @escaping () -> Void
    ) {
        self.leadingTitle = leadingTitle
        self.trailingTitle = trailingTitle
        self.leadingSystemImage = leadingSystemImage
        self.trailingSystemImage = trailingSystemImage
        self.leadingColor = leadingColor
        self.trailingColor = trailingColor
        self.size = size
        self.buttonSize = buttonSize
        self.onLeadingTap = onLeadingTap
        self.onTrailingTap = onTrailingTap
    }

    @State private var width: CGFloat = 0

    var body: some View {
        HStack(spacing: .spacing2x) {
            // The get-out only tints its capsule and writes in its own colour;
            // the affirmative pill fills with its colour and writes over it.
            pill(
                leadingTitle,
                systemImage: leadingSystemImage,
                fill: leadingColor?.opacity(.minimalOpacity),
                textColor: leadingColor ?? .textColor,
                action: onLeadingTap
            )
            // One share of three; the trailing pill's maxWidth takes the other
            // two. Unmeasured on the very first frame, it briefly hugs instead.
            .frame(width: width > 0 ? (width - .spacing2x) / 3 : nil)

            pill(
                trailingTitle,
                systemImage: trailingSystemImage,
                fill: trailingColor,
                // Fixed black rather than the adaptive text colour: it writes over
                // a filled pill, which keeps its colour in both schemes.
                textColor: .defaultBlack.opacity(.mediumOpacity),
                action: onTrailingTap
            )
            .frame(maxWidth: .infinity)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { new in
            width = new
        }
    }

    private func pill(
        _ title: String,
        systemImage: String?,
        fill: Color?,
        textColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: .spacing1x) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: Constants.imageSize, weight: .medium))
                        .foregroundStyle(textColor)
                }

                BrightText(title, size: size ?? Constants.fontSize, color: textColor)
            }
            .padding(.horizontal, .spacing2x)
            .frame(maxWidth: .infinity)
            .frame(height: buttonSize.rawValue)
            .contentShape(Capsule())
        }
        .background(fill ?? .clear, in: Capsule())
        .modifier(GlassEffect(shape: .capsule))
    }

    private enum Constants {
        static let imageSize: CGFloat = 15
        // The pair is designed at 17pt, tighter than the 19 a large button
        // would otherwise take.
        static let fontSize: FontSizes = .subheading2
    }
}

#Preview {
    VStack(spacing: .spacing4x) {
        BrightDuelPillButton(
            "Discard",
            "Finish",
            leadingSystemImage: "trash",
            trailingSystemImage: "flag.pattern.checkered",
            leadingColor: .defaultRed,
            trailingColor: .defaultGreen,
            onLeadingTap: {},
            onTrailingTap: {}
        )

        BrightDuelPillButton(
            "Cancel",
            "Save",
            onLeadingTap: {},
            onTrailingTap: {}
        )
    }
    .padding(.spacing3x)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultBackground)
}
