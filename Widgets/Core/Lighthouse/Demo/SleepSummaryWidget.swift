//
//  SleepSummaryWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 29/1/2026.
//

import SwiftUI

struct SleepSummaryWidget: View {
    var color: Color = .defaultBlue
    var isPercent = false
    var title: String?
    var label: String?
    var sevenDayAvg: Amount?
    var sevenDayData: [SleepSummaryDataPoint]?
    var sevenDayDateRange: String?
    var twentyEightDayAvg: Amount?
    var twentyEightDayData: [SleepSummaryDataPoint]?
    var weeklyAverages: [WeeklyAverage]?

    private func hoursAndMinutes(from decimalHours: Double) -> (hours: Int, minutes: Int) {
        let totalMinutes = Int(decimalHours * 60)
        return (totalMinutes / 60, totalMinutes % 60)
    }

    private func axisLabel(_ dateString: String?) -> String {
        guard let dateString else { return "" }
        guard let date = Date(brightISOZoned: dateString)
            ?? Date(brightDayKey: dateString)
        else { return dateString }
        return date.formatted(.brightDay)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack {
                BrightText(title ?? "Sleep Score", size: .body1, color: .textColor)
                Spacer()
                if let label {
                    BrightStatus(status: label)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                if isPercent {
                    BrightText(
                        "\(Int(sevenDayAvg?.value ?? 0))",
                        size: .huge2,
                        color: .textColor
                    )
                    BrightText(
                        "% AVG",
                        size: .body1,
                        color: .lightTextColor
                    )
                } else {
                    let time = hoursAndMinutes(from: sevenDayAvg?.value ?? 0)
                    BrightText("\(time.hours)", size: .huge2, color: .textColor)
                    BrightText("HR", size: .body3, color: .lightTextColor)
                    BrightText("\(time.minutes)", size: .huge2, color: .textColor)
                    BrightText("MIN", size: .body3, color: .lightTextColor)
                }

                Spacer()

                BrightText(
                    sevenDayDateRange ?? "—",
                    size: .body3,
                    color: .lightTextColor
                )
            }
            .padding(.top, .spacing3x)

            sevenDayChart

            HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                if isPercent {
                    BrightText(
                        "\(Int(twentyEightDayAvg?.value ?? 0))",
                        size: .huge2,
                        color: .textColor
                    )
                    BrightText(
                        "% AVG",
                        size: .body1,
                        color: .lightTextColor
                    )
                } else {
                    let time = hoursAndMinutes(from: twentyEightDayAvg?.value ?? 0)
                    BrightText("\(time.hours)", size: .huge2, color: .textColor)
                    BrightText("HR", size: .body3, color: .lightTextColor)
                    BrightText("\(time.minutes)", size: .huge2, color: .textColor)
                    BrightText("MIN", size: .body3, color: .lightTextColor)
                    BrightText("AVG", size: .body1, color: .lightTextColor)
                }

                Spacer()

                BrightText(
                    "Past 28 Days",
                    size: .body3,
                    color: .lightTextColor
                )
            }
            .padding(.top, .spacing4x)

            twentyEightDayChart

            weekAveragesView
                .padding(.top, .spacing2x)
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    var sevenDayChart: some View {
        VStack(spacing: .spacing0x) {
            BrightDivider()

            HStack(alignment: .top, spacing: .spacing0x) {
                BrightVerticalDivider()

                let chartData = sevenDayData ?? []
                let maxValue = chartData.compactMap(\.value).max() ?? 100
                let chartMax = isPercent ? 100.0 : maxValue

                ForEach(Array(chartData.enumerated()), id: \.offset) { _, item in
                    let value = item.value ?? 0
                    let day = axisLabel(item.date)

                    HStack(spacing: .spacing0x) {
                        Spacer()

                        VStack(spacing: .spacing1x) {
                            Spacer()

                            if value != 0 {
                                if isPercent {
                                    BrightText(
                                        "\(Int(value))%",
                                        size: .body6,
                                        color: .lightTextColor
                                    )
                                } else {
                                    BrightText(
                                        String(format: "%.1f", value),
                                        size: .body6,
                                        color: .lightTextColor
                                    )
                                }
                            }

                            let fullBarHeight: CGFloat = 110
                            let safeMax = max(CGFloat(chartMax), 0.0001)
                            let barHeight = fullBarHeight * (CGFloat(value) / safeMax)

                            if isPercent {
                                LinearGradient(
                                    stops: [
                                        .init(color: .defaultRed, location: 0),
                                        .init(color: .defaultSkyBlue, location: 0.53),
                                        .init(color: .defaultBrightGreen, location: 1),
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                                .frame(width: 6, height: fullBarHeight)
                                .frame(width: 6, height: barHeight, alignment: .bottom)
                                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius22))
                            } else {
                                RoundedRectangle(cornerRadius: .cornerRadius22)
                                    .fill(color)
                                    .frame(width: 6, height: barHeight)
                            }

                            BrightText(
                                day,
                                size: .body6,
                                color: .lightTextColor
                            )
                        }

                        Spacer()

                        BrightVerticalDivider()
                    }
                }
            }
            .frame(height: 160)
        }
    }

    var twentyEightDayChart: some View {
        VStack(spacing: .spacing0x) {
            BrightDivider()

            HStack(alignment: .bottom, spacing: .spacing0x) {
                BrightVerticalDivider()

                GeometryReader { _ in
                    let chartData = twentyEightDayData ?? []
                    let maxHeight: CGFloat = 100

                    let maxValue = chartData.compactMap(\.value).max() ?? 100
                    let chartMax = isPercent ? 100.0 : maxValue
                    let safeMax = max(CGFloat(chartMax), 0.0001)

                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(Array(chartData.enumerated()), id: \.offset) { _, item in
                            let value = item.value ?? 0
                            let barHeight = maxHeight * (CGFloat(value) / safeMax)

                            VStack(spacing: .spacing1x) {
                                Spacer()

                                if isPercent {
                                    LinearGradient(
                                        stops: [
                                            .init(color: .defaultRed, location: 0),
                                            .init(color: .defaultSkyBlue, location: 0.53),
                                            .init(color: .defaultBrightGreen, location: 1),
                                        ],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                    .frame(width: 4, height: maxHeight)
                                    .mask(alignment: .bottom) {
                                        RoundedRectangle(cornerRadius: .cornerRadius22)
                                            .frame(width: 4, height: barHeight)
                                    }
                                    .opacity(.lowOpacity)
                                } else {
                                    RoundedRectangle(cornerRadius: .cornerRadius22)
                                        .fill(color)
                                        .frame(width: 4, height: barHeight)
                                        .opacity(.lowOpacity)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                BrightVerticalDivider()
            }
            .frame(height: 120)

            let chartData = twentyEightDayData ?? []
            if chartData.count >= 28 {
                HStack(spacing: .spacing0x) {
                    BrightText(axisLabel(chartData[6].date), size: .body6, color: .lightTextColor)
                        .frame(maxWidth: .infinity)
                    BrightText(axisLabel(chartData[13].date), size: .body6, color: .lightTextColor)
                        .frame(maxWidth: .infinity)
                    BrightText(axisLabel(chartData[20].date), size: .body6, color: .lightTextColor)
                        .frame(maxWidth: .infinity)
                    BrightText(axisLabel(chartData[27].date), size: .body6, color: .lightTextColor)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, .spacing1x)
            }
        }
    }

    var weekAveragesView: some View {
        VStack(spacing: .spacing1x) {
            let weeklyAvgs = weeklyAverages ?? []

            ForEach(Array(weeklyAvgs.enumerated()), id: \.offset) { index, weekAvg in
                if index > 0 {
                    BrightDivider()
                }

                HStack {
                    BrightText("Week \(weekAvg.week ?? (index + 1)) AVG", size: .body1, color: .semiLightTextColor)
                    Spacer()

                    if isPercent {
                        if (weekAvg.value ?? 0) != 0 {
                            HStack(spacing: .spacing05x) {
                                BrightText("\(Int(weekAvg.value ?? 0))", size: .standout3, color: .textColor)
                                BrightText("%", size: .body2, color: .lightTextColor)
                            }
                        }
                    } else {
                        let time = hoursAndMinutes(from: weekAvg.value ?? 0)
                        if time.hours != 0 || time.minutes != 0 {
                            HStack(spacing: .spacing05x) {
                                BrightText("\(time.hours)", size: .standout3, color: .textColor)
                                BrightText("HR", size: .body2, color: .lightTextColor)
                                BrightText("\(time.minutes)", size: .standout3, color: .textColor)
                                BrightText("MIN", size: .body2, color: .lightTextColor)
                            }
                        }
                    }
                }
                .padding(.vertical, .spacing1x)
            }
        }
    }
}
