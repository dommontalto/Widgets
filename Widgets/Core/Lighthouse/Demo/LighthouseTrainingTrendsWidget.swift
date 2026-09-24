//
//  LighthouseTrainingTrendsWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 24/9/2026.
//

import Charts
import SwiftUI

nonisolated struct LighthouseTrainingTrends: Equatable {
    let unit: String
    let days: [String]
    let values: [Double?]
    let average: Int
    let previousAverage: Int

    static let demo = LighthouseTrainingTrends(
        unit: "%",
        days: ["M", "T", "W", "T", "F", "S", "S"],
        values: [72, 84, 91, 38, 88, 95, 64],
        average: 76,
        previousAverage: 64
    )
}

struct LighthouseTrainingTrendsWidget: View {
    var trends = LighthouseTrainingTrends.demo

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing5x) {
            HStack(spacing: .spacing0x) {
                average(trends.average, label: "This week", color: .defaultBrightGreen)
                average(trends.previousAverage, label: "Last week", color: .textColor)
            }

            chart
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    private func average(_ value: Int, label: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: .spacing1x) {
            Circle()
                .fill(color)
                .frame(width: Constants.avgCircleSize, height: Constants.avgCircleSize)
                .padding(.top, .spacing2x)

            VStack(alignment: .leading, spacing: .spacing1x) {
                HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                    BrightText(String(value), size: .standout2)
                    BrightText(trends.unit, size: .subheading, color: .lightTextColor)
                    BrightText("Avg", size: .body1, color: .lightTextColor)
                }

                BrightText(label, size: .body1, color: .lightTextColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chart: some View {
        VStack(spacing: .spacing0x) {
            HStack(spacing: .spacing0x) {
                ChartView(data: trends.values, currentAvg: trends.average, pastAvg: trends.previousAverage)

                VStack(alignment: .leading) {
                    BrightText("100", size: .body1, color: .semiLightTextColor)
                    Spacer()
                    BrightText("0", size: .body1, color: .semiLightTextColor)
                }
                .frame(width: Constants.yAxisWidth, alignment: .leading)
                .padding(.leading, .spacing05x)
            }
            .frame(height: Constants.chartHeight)

            VStack(spacing: .spacing0x) {
                BrightDivider()

                HStack(spacing: .spacing0x) {
                    ForEach(trends.days.indices, id: \.self) { index in
                        BrightText(trends.days[index], size: .body1, color: .semiLightTextColor)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, .spacing1x)
            }
            .padding(.top, .spacing05x)
            .padding(.trailing, Constants.yAxisWidth + .spacing05x)
        }
    }

    private struct ChartView: View {
        let data: [Double?]
        let currentAvg: Int
        let pastAvg: Int

        var body: some View {
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    bar(at: index)
                }

                RuleMark(y: .value("Current", Double(currentAvg)))
                    .foregroundStyle(Color.defaultBrightGreen)
                    .lineStyle(StrokeStyle(lineWidth: 1))

                RuleMark(y: .value("Past", Double(pastAvg)))
                    .foregroundStyle(Color.textColor)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: Constants.dash))
            }
            .chartXAxis(.hidden)
            .chartYScale(domain: 0.0 ... 100.0)
            .chartYAxis(.hidden)
        }

        private func bar(at index: Int) -> some ChartContent {
            let day = String(index)
            let base: Double = 0
            let value: Double = data[index] ?? 0
            let style: LinearGradient = gradient(for: value)
            let radius: CGFloat = Constants.barCornerRadius

            return BarMark(
                x: .value("Day", day),
                yStart: .value("Min", base),
                yEnd: .value("Max", value),
                width: .ratio(Constants.barRatio)
            )
            .foregroundStyle(style)
            .cornerRadius(radius)
        }

        private func gradient(for value: Double) -> LinearGradient {
            let colors: [Color] = switch min(max(value / 100, 0), 1) {
            case ..<0.2: [.defaultRed]
            case ..<0.44: [.defaultRed, .defaultOrange]
            case ..<0.76: [.defaultRed, .defaultOrange, .defaultBlue]
            default: [.defaultRed, .defaultOrange, .defaultBlue, .defaultBrightGreen]
            }
            return LinearGradient(colors: colors.map { $0.opacity(.semiLowOpacity) }, startPoint: .bottom, endPoint: .top)
        }
    }

    private enum Constants {
        static let chartHeight: CGFloat = 103
        static let yAxisWidth: CGFloat = 36
        static let avgCircleSize: CGFloat = 8
        static let barRatio: Double = 0.7
        static let barCornerRadius: CGFloat = 7
        static let dash: [CGFloat] = [6, 4]
    }
}

#Preview {
    LighthouseTrainingTrendsWidget()
        .padding(.spacing3x)
        .background(Color.defaultBackground)
}
