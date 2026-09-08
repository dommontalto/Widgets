//
//  WidgetBuilderBarChartView.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import Charts
import SwiftUI

// The seven-day expenditure vs intake bar chart inside the Activity widget.
struct WidgetBuilderBarChartView: View {
    enum BarChartSize {
        case extended
        case split
        case largest
    }

    let size: BarChartSize
    let activityGraphData: ActivityGraphData

    @Environment(\.lighthouseAnimateChartReveal) private var animateReveal
    // Holds the bars flat until the widget is loaded in.
    @Environment(\.lighthouseLoadIn) private var loadIn
    // 0 -> 1 grow progress for the bars-rise reveal. Multiplies the bar values
    // so only the bars animate (grid lines / labels stay put).
    @State private var growProgress: Double = 0

    private var barScale: Double {
        animateReveal ? growProgress : 1
    }

    private var chartHeight: CGFloat {
        switch size {
        case .extended: Constants.extendedHeight
        case .split: Constants.splitHeight
        case .largest: Constants.largestHeight
        }
    }

    var body: some View {
        let maxValue = activityGraphData.highestValue > 0 ? activityGraphData.highestValue : 500
        let marks = GraphHelpers.calculatedYAxisMarks(
            calculatedMaxValue: maxValue,
            desiredCount: size == .extended ? 2 : 3
        )
        // The scale must never sit below the tallest bar.
        let scaleMax = max(marks.last ?? maxValue, maxValue)

        HStack(spacing: .spacing1x) {
            ZStack(alignment: .topLeading) {
                // Vertical grid lines extend down past the chart into the time labels.
                HStack(spacing: .spacing0x) {
                    ForEach(0 ..< 4, id: \.self) { _ in
                        VerticalDashedLineWidget(
                            color: .textColor.opacity(.minimalOpacity),
                            lineWidth: Constants.gridLineWidth,
                            dashPattern: [1, 1, 1, 1]
                        )
                        Spacer()
                    }
                }
                .frame(height: chartHeight + .spacing3x)

                VStack(spacing: .spacing0x) {
                    ZStack {
                        // No top line; the middle is dashed and the baseline solid.
                        VStack {
                            Spacer()
                            DashedLineWidget(
                                color: .textColor.opacity(.minimalOpacity),
                                lineWidth: Constants.gridLineWidth,
                                dashPattern: [1, 1, 1, 1]
                            )
                            Spacer()
                            Rectangle()
                                .fill(Color.textColor.opacity(.minimalOpacity))
                                .frame(height: Constants.gridLineWidth)
                        }

                        Chart {
                            ForEach(activityGraphData.barValues) { barValue in
                                BarMark(
                                    x: .value("Day", barValue.date, unit: .day),
                                    y: .value("Expenditure", barValue.activeValue * barScale),
                                    width: Constants.barWidth
                                )
                                .foregroundStyle(ActivityGraphData.BarValueType.active.barColor)
                                .cornerRadius(.cornerRadius24)
                                .position(by: .value("Type", "expenditure"))

                                BarMark(
                                    x: .value("Day", barValue.date, unit: .day),
                                    y: .value("Intake", barValue.restingValue * barScale),
                                    width: Constants.barWidth
                                )
                                .foregroundStyle(ActivityGraphData.BarValueType.resting.barColor)
                                .cornerRadius(.cornerRadius24)
                                .position(by: .value("Type", "intake"))
                            }
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .chartYScale(domain: 0 ... scaleMax)
                    }
                    .frame(height: chartHeight)

                    HStack(spacing: .spacing0x) {
                        ForEach(["12 AM", "6 AM", "12 PM", "6 PM"], id: \.self) { time in
                            BrightText(time, size: .body5, color: .semiLightTextColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, .spacing1x)
                        }
                    }
                    .padding(.top, .spacing1x)
                }
            }

            VStack(alignment: .leading) {
                BrightText(Int(marks.last ?? 0).withCommas, size: .body5, color: .semiLightTextColor)
                Spacer()
                BrightText("0 \(activityGraphData.unit)", size: .body5, color: .semiLightTextColor)
            }
            .frame(height: chartHeight)
            .padding(.bottom, .spacing205x)
        }
        .onAppear {
            guard animateReveal else { return }
            // Reflect the current load state instantly so a LazyVStack remount
            // lands at full height without replaying.
            growProgress = loadIn ? 1 : 0
        }
        // The load-in moment: grow the bars up from the baseline, once.
        .onChange(of: loadIn) { _, now in
            guard animateReveal, now else { return }
            growProgress = 0
            withAnimation(.easeOut(duration: 0.9)) { growProgress = 1 }
        }
    }

    private enum Constants {
        static let extendedHeight: CGFloat = 60
        static let splitHeight: CGFloat = 80
        static let largestHeight: CGFloat = 210
        static let barWidth: MarkDimension = .fixed(6)
        static let gridLineWidth: CGFloat = 0.5
    }
}

#Preview {
    WidgetBuilderBarChartView(size: .split, activityGraphData: LighthouseDemo.activityGraphData)
        .padding(.spacing3x)
        .background(Color.defaultHomeCards)
}
