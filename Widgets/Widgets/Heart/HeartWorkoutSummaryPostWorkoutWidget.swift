//
//  HeartWorkoutSummaryPostWorkoutWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import Charts
import SwiftUI

struct HeartWorkoutSummaryPostWorkoutWidget: View {
    let data: HeartWorkoutSummaryPostWorkoutHeartGraphData

    private var hasGridLines: Bool {
        (data.data ?? []).count >= Constants.minimumBarsForGridLines
    }

    private var hasXAxis: Bool {
        (data.xDatesDisplay ?? []).count >= 3
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            BrightText("Post-Workout Heart Rate Drop", size: .body1)

            HStack(spacing: .spacing1x) {
                Image(ImageNames.heartRedDownV5)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.iconSize, height: Constants.iconSize)

                HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                    BrightText(String(data.bpmDrop ?? 0), size: .huge)

                    BrightText("BPM", size: .body1, color: .lightTextColor)
                }
            }
            .padding(.top, .spacing3x)

            ZStack(alignment: .top) {
                chartBorderLayout
                    .frame(height: Constants.graphLayoutHeight)
                    .padding(.trailing, Constants.yAxisWidth + .spacing105x)

                HStack(spacing: .spacing105x) {
                    chart
                        .frame(height: Constants.graphHeight)

                    VStack(alignment: .leading) {
                        BrightText(String(data.yTicks?.last ?? 100), size: .body3, color: .semiLightTextColor)
                        Spacer()
                        BrightText(String(data.yTicks?.first ?? 70), size: .body3, color: .semiLightTextColor)
                    }
                    .frame(width: Constants.yAxisWidth, height: Constants.graphHeight, alignment: .leading)
                }
            }
            .padding(.top, .spacing1x)

            if hasXAxis {
                HStack(spacing: .spacing0x) {
                    xAxisLabel((data.xDates?.first ?? "").isoStringToDate().stringFromDate(strFormatter: "hh:mm"))
                    xAxisLabel(data.xDatesDisplay![1])
                    xAxisLabel(data.xDatesDisplay![2])
                }
            }
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .sheetModalCards))
    }

    private func xAxisLabel(_ text: String) -> some View {
        BrightText(text, size: .body3, color: .lightTextColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, .spacing05x)
    }

    var chart: some View {
        let start = Double(data.yTicks?.first ?? 30)
        let end = Double(data.yTicks?.last ?? 30)

        return Chart {
            ForEach((data.data ?? []).indices, id: \.self) { index in
                let heartData = data.data![index]

                BarMark(
                    x: .value("State", "\(index)"),
                    yStart: .value("Heart Rate", heartData.min ?? 0),
                    yEnd: .value("Heart Rate", heartData.max ?? 0),
                    width: MarkDimension(floatLiteral: Constants.barMarkWidth)
                )
                .foregroundStyle(Color.defaultWarningRed)
                .cornerRadius(.cornerRadius8)
            }
        }
        .chartYScale(domain: start ... end)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartOverlay { _ in
            GeometryReader { geometry in
                Path { path in
                    let midY = geometry.size.height / 2
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: midY))
                }
                .stroke(
                    Color.textColor.opacity(.veryLowOpacity),
                    style: StrokeStyle(lineWidth: 0.5, dash: [6, 4])
                )
            }
        }
    }

    var chartBorderLayout: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                gradient: Gradient(colors: [Color.defaultWarningRed.opacity(.ultraLowOpacity), .clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Constants.chartGradientHeight)

            if hasGridLines {
                BrightDivider(color: .defaultWarningRed)

                HStack(alignment: .top) {
                    ForEach(0 ..< Constants.gridLineCount, id: \.self) { index in
                        // Every fifth line marks a minute boundary and runs full height.
                        let isMinuteMark = index % 5 == 0

                        BrightVerticalDivider(
                            color: isMinuteMark ? .textColor : .defaultWarningRed,
                            height: isMinuteMark ? Constants.graphLayoutHeight : Constants.graphHeight
                        )

                        if index != Constants.gridLineCount - 1 {
                            Spacer()
                        }
                    }
                }
            }

            if hasXAxis {
                VStack {
                    Spacer()
                    HStack(spacing: .spacing0x) {
                        XAxisText(value: data.xBpm?[0] ?? nil)
                        XAxisText(value: data.xBpm?[1] ?? nil)
                        XAxisText(value: data.xBpm?[2] ?? nil)
                    }
                }
            }
        }
    }

    struct XAxisText: View {
        let value: Int?

        private var text: String {
            if let value, value != 0 {
                return "\(value) BPM"
            }
            return "- BPM"
        }

        var body: some View {
            BrightText(text, size: .body3, color: .defaultWarningRed)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, .spacing05x)
        }
    }

    private enum Constants {
        static let yAxisWidth: CGFloat = 25
        static let graphHeight: CGFloat = 86
        static let graphLayoutHeight: CGFloat = 101
        static let barMarkWidth: CGFloat = 4
        static let chartGradientHeight: CGFloat = 57
        static let iconSize: CGFloat = 21
        static let gridLineCount = 16
        static let minimumBarsForGridLines = 15
    }
}

#Preview {
    HeartWorkoutSummaryPostWorkoutWidget(
        data: HeartDemoData.workout.postWorkoutHeartGraph ?? HeartWorkoutSummaryPostWorkoutHeartGraphData()
    )
    .padding(.spacing3x)
    .background(Color.sheetBackground)
}
