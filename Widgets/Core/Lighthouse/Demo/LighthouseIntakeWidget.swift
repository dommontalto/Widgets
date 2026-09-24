//
//  LighthouseIntakeWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 24/9/2026.
//

import Charts
import SwiftUI

nonisolated struct LighthouseIntake: Equatable {
    nonisolated struct WeekGroup: Identifiable, Equatable {
        let id = UUID()
        let days: String
        let intake: Int
    }

    let title: String
    let unit: String
    let groups: [WeekGroup]
    let days: [String]
    let values: [Double]
    let yTicks: [Int]

    static let demo = LighthouseIntake(
        title: "Daily intake",
        unit: "Cal",
        groups: [
            WeekGroup(days: "Mon - Fri", intake: 2_240),
            WeekGroup(days: "Sat - Sun", intake: 2_610),
        ],
        days: ["M", "T", "W", "T", "F", "S", "S"],
        values: [2_180, 2_310, 2_090, 2_350, 2_270, 2_740, 2_480],
        yTicks: [0, 3_000]
    )
}

struct LighthouseIntakeWidget: View {
    var intake = LighthouseIntake.demo

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            BrightText(intake.title, size: .body1)

            groups
                .padding(.top, .spacing4x)

            graph
                .padding(.top, .spacing5x)
                .padding(.bottom, .spacing1x)
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    private var groups: some View {
        HStack(spacing: .spacing2x) {
            ForEach(Array(intake.groups.enumerated()), id: \.element.id) { index, group in
                VStack(alignment: .leading, spacing: .spacing2x) {
                    BrightText(group.days, size: .body1, color: .semiLightTextColor)

                    HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                        BrightText(group.intake.formatted(), size: .standout2)
                        BrightText(intake.unit, size: .body1, color: .lightTextColor)
                    }
                }

                if index != intake.groups.count - 1 {
                    BrightVerticalDivider(height: Constants.groupHeight)
                }
            }
        }
    }

    private var graph: some View {
        HStack(alignment: .top, spacing: .spacing1x) {
            VStack(spacing: .spacing105x) {
                GraphView(data: intake.values, top: intake.yTicks.last ?? 0)
                    .frame(height: Constants.graphHeight)

                HStack(spacing: .spacing0x) {
                    ForEach(intake.days.indices, id: \.self) { index in
                        BrightText(intake.days[index], size: .body1, color: .lightTextColor)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            VStack(alignment: .leading) {
                BrightText((intake.yTicks.last ?? 0).formatted(), size: .body1, color: .semiLightTextColor)
                Spacer()
                BrightText("\(intake.yTicks.first ?? 0) \(intake.unit)", size: .body1, color: .semiLightTextColor)
            }
            .frame(height: Constants.graphHeight)
            .padding(.leading, .spacing2x)
        }
    }

    private struct GraphView: View {
        let data: [Double]
        let top: Int

        var body: some View {
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    bar(at: index)
                }
            }
            .chartXAxis(.hidden)
            .chartYScale(domain: 0 ... Double(top))
            .chartYAxis(.hidden)
        }

        private func bar(at index: Int) -> some ChartContent {
            let day = String(index)
            let base: Double = 0
            let value: Double = data[index]
            let style = Gradient(colors: [.defaultBrightGreen, .defaultBlue])
            let radius: CGFloat = Constants.barCornerRadius

            return BarMark(
                x: .value("Day", day),
                yStart: .value("Min", base),
                yEnd: .value("Max", value),
                width: .fixed(Constants.barWidth)
            )
            .foregroundStyle(style)
            .cornerRadius(radius)
        }
    }

    private enum Constants {
        static let groupHeight: CGFloat = 62
        static let graphHeight: CGFloat = 95
        static let barWidth: CGFloat = 12
        static let barCornerRadius: CGFloat = 7
    }
}

#Preview {
    LighthouseIntakeWidget()
        .padding(.spacing3x)
        .background(Color.defaultBackground)
}
