//
//  LighthouseSleepTimeWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 24/9/2026.
//

import Charts
import SwiftUI

nonisolated struct LighthouseSleepTime: Equatable {
    let title: String
    let label: String
    let average: Double
    let unit: String
    let days: [String]
    let yTicks: [Int]
    let values: [Double]

    static let demo = LighthouseSleepTime(
        title: "Past 7 nights",
        label: "Average",
        average: 7.1,
        unit: "hr",
        days: ["M", "T", "W", "T", "F", "S", "S"],
        yTicks: [0, 5, 10],
        values: [6.8, 7.4, 5.9, 7.2, 6.6, 8.3, 7.5]
    )
}

struct LighthouseSleepTimeWidget: View {
    var sleep = LighthouseSleepTime.demo

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText("Avg sleep time", size: .body1)
                    BrightText(sleep.title, size: .body1, color: .lightTextColor)
                }

                Spacer()

                BrightStatus(status: sleep.label)
            }

            HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                BrightText(sleep.average.formatted(.number.precision(.fractionLength(1))), size: .standout2)
                BrightText("\(sleep.unit) AVG", size: .subheading, color: .lightTextColor)
            }
            .padding(.top, .spacing4x)

            chart
                .padding(.top, .spacing6x)
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    private var chart: some View {
        VStack(spacing: .spacing0x) {
            HStack(spacing: .spacing0x) {
                ChartView(data: sleep.values, endHour: sleep.yTicks.last ?? 10)
                    .padding(.top, .spacing2x)

                VStack(alignment: .leading) {
                    ForEach(Array(sleep.yTicks.reversed().enumerated()), id: \.offset) { index, tick in
                        if index > 0 {
                            Spacer()
                        }
                        BrightText(index == sleep.yTicks.count - 1 ? "\(tick)\(sleep.unit)" : String(tick), size: .body1, color: .semiLightTextColor)
                    }
                }
                .frame(width: Constants.yAxisWidth, alignment: .leading)
                .padding(.leading, .spacing05x)
            }
            .frame(height: Constants.chartHeight)

            VStack(spacing: .spacing0x) {
                BrightDivider()

                HStack(spacing: .spacing0x) {
                    ForEach(sleep.days.indices, id: \.self) { index in
                        BrightText(sleep.days[index], size: .body1, color: .semiLightTextColor)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, .spacing1x)
            }
            .padding(.trailing, Constants.yAxisWidth + .spacing05x)
        }
    }

    private struct ChartView: View {
        let data: [Double]
        let endHour: Int

        var body: some View {
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    wash(at: index)
                    cap(at: index)
                }
            }
            .chartXAxis(.hidden)
            .chartYScale(domain: 0 ... Double(endHour))
            .chartYAxis(.hidden)
        }

        private func wash(at index: Int) -> some ChartContent {
            let day = String(index)
            let base: Double = 0
            let value: Double = data[index]
            let style = LinearGradient(
                colors: [Color.defaultBlue.opacity(.veryMinimalOpacity), .clear],
                startPoint: .top,
                endPoint: .bottom
            )

            return BarMark(
                x: .value("Night", day),
                yStart: .value("Min", base),
                yEnd: .value("Max", value),
                width: .ratio(1)
            )
            .foregroundStyle(style)
        }

        private func cap(at index: Int) -> some ChartContent {
            let day = String(index)
            let value: Double = data[index]
            let top: Double = value + Constants.capHeight

            return BarMark(
                x: .value("Night", day),
                yStart: .value("Min", value),
                yEnd: .value("Max", top),
                width: .ratio(1)
            )
            .foregroundStyle(Color.defaultBlue)
        }
    }

    private enum Constants {
        static let chartHeight: CGFloat = 116
        static let yAxisWidth: CGFloat = 36
        static let capHeight: Double = 0.2
    }
}

#Preview {
    LighthouseSleepTimeWidget()
        .padding(.spacing3x)
        .background(Color.defaultBackground)
}
