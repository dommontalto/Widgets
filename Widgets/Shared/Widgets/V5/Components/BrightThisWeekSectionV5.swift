//
//  BrightThisWeekSectionV5.swift
//  Widgets
//
//  Created by Dom Montalto on 9/10/2026.
//

import SwiftUI

// The large widgets' grid of this week's days, Monday first: each day's badge and its
// value, or how far it landed from a target. Today's badge is filled in.
struct BrightThisWeekSectionV5: View {
    enum Style {
        case values
        case targets(Double)
    }

    // Monday first; nil for a day without a reading, including the days still to come.
    let days: [Double?]
    var style: Style = .values
    var tint: Color = .defaultCyan
    let format: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(title, size: .body3, color: .semiLightTextColor, weight: .regular)
                .contentTransition(.numericText())

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: .spacing1x, alignment: .leading), count: Constants.columns),
                alignment: .leading,
                spacing: .spacing2x
            ) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, value in
                    cell(index: index, value: value)
                }
            }
        }
    }

    private func cell(index: Int, value: Double?) -> some View {
        let isToday = index == todayIndex

        return HStack(spacing: .spacing1x) {
            BrightText(
                Constants.weekdayInitials[index % Constants.weekdayInitials.count],
                size: .body5,
                color: isToday ? .defaultBlack : tint,
                weight: isToday ? .regular : .light
            )
            .frame(width: Constants.badgeSize, height: Constants.badgeSize)
            .background(Circle().fill(isToday ? tint : tint.opacity(.minimalOpacity)))

            if let value {
                switch style {
                case .values:
                    BrightText(format(value), size: .body3, color: .semiLightTextColor)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                case let .targets(target):
                    HStack(spacing: .spacing05x) {
                        Image(systemName: value >= target ? "arrow.up" : "arrow.down")
                            .font(.standard(size: .body3, weight: .light))

                        BrightText(format(abs(value - target)), size: .body3, color: .semiLightTextColor)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(Color.semiLightTextColor)
                }
            } else {
                BrightText("-", size: .body3, color: .semiLightTextColor)
            }
        }
        .lineLimit(1)
    }

    private var title: String {
        if case .targets = style { "Weekly Targets" } else { "This week" }
    }

    // The latest day with a reading.
    private var todayIndex: Int? {
        days.lastIndex { $0 != nil }
    }

    private enum Constants {
        static let columns = 3
        static let badgeSize: CGFloat = 20
        static let weekdayInitials = ["M", "T", "W", "T", "F", "S", "S"]
    }
}

#Preview {
    VStack(alignment: .leading, spacing: .spacing4x) {
        BrightThisWeekSectionV5(days: [4.52, 3.2, 1.92, 3.42, 2.13, nil, nil]) { "\($0.formatted(.number.precision(.fractionLength(0 ... 2))))L" }

        BrightThisWeekSectionV5(days: [1_720, 1_610, 2_380, 1_790, nil, nil, nil], style: .targets(2_200), tint: .defaultGreen) {
            "\(Int($0)) Cal"
        }
    }
    .padding(.spacing205x)
    .background(Color.defaultHomeCards)
}
