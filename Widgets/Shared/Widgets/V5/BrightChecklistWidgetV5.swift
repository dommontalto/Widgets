//
//  BrightChecklistWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 13/10/2026.
//

import SwiftUI

struct BrightChecklistWidgetV5: View {
    let title: String
    let image: String
    let tint: Color
    let days: [Bool]
    let streak: Int
    let unit: String

    @State private var isRevealed = false

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
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .brightRevealV5($isRevealed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(days.filter { $0 }.count) of \(days.count) days, \(streak) \(unit)")
    }

    private var header: some View {
        HStack(spacing: .spacing05x) {
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
                        .fill(tint.opacity(days[index - 1] && days[index] ? .opaque : .veryLowOpacity))
                        .frame(width: Constants.connectorLength, height: Constants.connectorThickness)
                }

                dot(isDone: days[index])
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
            BrightText(isRevealed ? "\(streak)" : "\(streak)".zeroedDigits, size: .huge)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.brightBouncy, value: streak)

            BrightText(unit, size: .body1, color: .lightTextColor)
        }
        .lineLimit(1)
        .padding(.bottom, Font.standardUIFont(size: .huge, weight: .light)?.descender ?? 0)
    }

    private enum Constants {
        static let daysPerRow = 4
        static let iconSize: CGFloat = 18
        static let dotSize: CGFloat = 19
        static let ringWidth: CGFloat = 2
        static let checkSize: CGFloat = 9
        static let connectorLength: CGFloat = 15
        static let connectorThickness: CGFloat = 1
    }
}

#Preview {
    BrightChecklistWidgetV5(
        title: "Journal",
        image: ImageNames.pencilBlueV5,
        tint: .defaultCyan,
        days: [true, false, true, true, true, false, false],
        streak: 3,
        unit: "Day Streak"
    )
    .frame(width: 174, height: 174)
    .padding(.spacing205x)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultBackground)
}
