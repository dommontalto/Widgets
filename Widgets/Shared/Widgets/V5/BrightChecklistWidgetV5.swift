//
//  BrightChecklistWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 13/10/2026.
//

import SwiftUI

struct BrightChecklistWidgetV5: View {
    struct Day: Hashable {
        let date: Date
        let isDone: Bool
    }

    let title: String
    let image: String
    let tint: Color
    let days: [Day]
    let streak: Int
    let unit: String
    var allowsSelection = true

    @State private var isRevealed = false
    @State private var heldIndex: Int?
    @State private var touch: UnitPoint?
    @State private var cardSize: CGSize = .zero
    @State private var dotCentres: [Int: CGPoint] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            header

            Spacer(minLength: .spacing0x)

            checklist

            Spacer(minLength: .spacing0x)

            reading
        }
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .coordinateSpace(.named(Constants.space))
        .onGeometryChange(for: CGSize.self, of: \.size) { cardSize = $0 }
        .overlay {
            if allowsSelection {
                BrightWidgetTouchLayerV5(touch: $touch)
            }
        }
        .onChange(of: touch) { resolveTouch() }
        .animation(.brightEaseInOut, value: heldIndex)
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .brightRevealV5($isRevealed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(days.filter(\.isDone).count) of \(days.count) days, \(streak) \(unit)")
    }

    private var header: some View {
        HStack(spacing: .spacing1x) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.iconSize, height: Constants.iconSize)

            BrightText(title, size: .body1, weight: .regular)
        }
        .lineLimit(1)
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            ForEach(Array(stride(from: 0, to: days.count, by: Constants.daysPerRow)), id: \.self) { start in
                row(start ..< min(start + Constants.daysPerRow, days.count))
            }
        }
    }

    private func row(_ indices: Range<Int>) -> some View {
        HStack(spacing: .spacing05x) {
            ForEach(indices, id: \.self) { index in
                if index != indices.lowerBound {
                    Capsule()
                        .fill(tint.opacity(days[index - 1].isDone && days[index].isDone ? .opaque : .veryLowOpacity))
                        .frame(width: Constants.connectorLength, height: Constants.connectorThickness)
                }

                dot(isDone: days[index].isDone)
                    .scaleEffect(heldIndex == index ? Constants.heldScale : 1)
                    .opacity(heldIndex == nil || heldIndex == index ? .opaque : .semiLowOpacity)
                    .onGeometryChange(for: CGPoint.self) { proxy in
                        let frame = proxy.frame(in: .named(Constants.space))
                        return CGPoint(x: frame.midX, y: frame.midY)
                    } action: {
                        dotCentres[index] = $0
                    }
            }
        }
    }

    private func dot(isDone: Bool) -> some View {
        ZStack {
            if isDone {
                Circle()
                    .fill(tint)

                Image(systemName: "checkmark")
                    .font(.system(size: Constants.checkSize, weight: .bold))
                    .foregroundStyle(.black)
            } else {
                Circle()
                    .strokeBorder(tint.opacity(.lowOpacity), lineWidth: Constants.ringWidth)
            }
        }
        .frame(width: Constants.dotSize, height: Constants.dotSize)
        .animation(.brightBouncy, value: isDone)
    }

    private var reading: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            BrightText(heldDay?.date.formatted(.brightWeekdayShort) ?? (isRevealed ? "\(streak)" : "\(streak)".zeroedDigits), size: .huge)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.brightBouncy, value: streak)

            BrightText(heldDay.map { status(of: $0) } ?? unit, size: .body1, color: .lightTextColor)
                .contentTransition(.numericText())
        }
        .lineLimit(1)
        .padding(.bottom, Font.standardUIFont(size: .huge, weight: .light)?.descender ?? 0)
    }

    private func status(of day: Day) -> String {
        if day.isDone {
            return "Logged"
        }
        return day.date > .now ? "Upcoming" : "Missed"
    }

    private enum Constants {
        static let space = "checklistCard"
        static let heldScale: CGFloat = 1.3
        static let daysPerRow = 4
        static let iconSize: CGFloat = 18
        static let dotSize: CGFloat = 19
        static let ringWidth: CGFloat = 2
        static let checkSize: CGFloat = 9
        static let connectorLength: CGFloat = 15
        static let connectorThickness: CGFloat = 1
    }
}

extension BrightChecklistWidgetV5 {
    // MARK: - Holding

    private var heldDay: Day? {
        heldIndex.flatMap { days.indices.contains($0) ? days[$0] : nil }
    }

    private func resolveTouch() {
        guard let touch else {
            heldIndex = nil
            return
        }
        let point = CGPoint(x: touch.x * cardSize.width, y: touch.y * cardSize.height)
        let nearest = dotCentres.min { hypot($0.value.x - point.x, $0.value.y - point.y) < hypot($1.value.x - point.x, $1.value.y - point.y) }?.key
        guard nearest != heldIndex else { return }
        heldIndex = nearest
        BrightHaptic.light.play()
    }
}

#Preview {
    BrightChecklistWidgetV5(
        title: "Journal",
        image: ImageNames.pencilBlueV5,
        tint: .defaultCyan,
        days: (0 ..< 7).map { .init(date: .now.addingTimeInterval(Double($0 - 4) * 86_400), isDone: [true, false, true, true, true, false, false][$0]) },
        streak: 3,
        unit: "Day Streak"
    )
    .frame(width: 174, height: 174)
    .padding(.spacing205x)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultBackground)
}
