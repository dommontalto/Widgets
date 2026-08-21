//
//  ExerciseCompleteRecoveryWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import Charts
import SwiftUI

struct ExerciseCompleteRecoveryWidget: View {
    let data: HeartWorkoutSummaryPostWorkoutHeartGraphData

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            BrightText(
                "Post-Session Heart Rate Drop",
                size: .body1,
                color: .textColor
            )

            HStack(spacing: .spacing1x) {
                Image(ImageNames.heartRedDownV5)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 21, height: 21)

                HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                    BrightText(
                        String(data.bpmDrop ?? 0),
                        size: .huge,
                        color: .textColor
                    )
                    BrightText(
                        "BPM",
                        size: .body1,
                        color: .textColor.opacity(.lowOpacity)
                    )
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
                        BrightText(
                            String(data.yTicks?.last ?? 100),
                            size: .body1,
                            color: .semiLightTextColor
                        )
                        Spacer()
                        BrightText(
                            String(data.yTicks?.first ?? 70),
                            size: .body1,
                            color: .semiLightTextColor
                        )
                    }
                    .frame(width: Constants.yAxisWidth, height: Constants.graphHeight, alignment: .leading)
                }
            }
            .padding(.top, .spacing1x)

            if (data.xDatesDisplay ?? []).count >= 3 {
                HStack(spacing: .spacing0x) {
                    BrightText(
                        (data.xDates?.first ?? "").isoStringToDate().formatted(.brightTime),
                        size: .body1,
                        color: .lightTextColor
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, .spacing05x)
                    BrightText(
                        data.xDatesDisplay![1],
                        size: .body1,
                        color: .lightTextColor
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, .spacing05x)
                    BrightText(
                        data.xDatesDisplay![2],
                        size: .body1,
                        color: .lightTextColor
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, .spacing05x)
                }
                // Same inset the chart takes for the y-axis, so these columns
                // divide the same width as the BPM readings above them.
                .padding(.trailing, Constants.yAxisWidth + .spacing105x)
            }
        }

        .padding(.spacing3x)
        .modifier(CardModifier(
            color: .defaultSheetModalCards
        ))
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
                .foregroundStyle(Color.defaultRed)
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
                gradient: Gradient(colors: [Color.defaultRed.opacity(0.10), .clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Constants.chartGradientHeight)

            if (data.data ?? []).count >= 15 {
                BrightDivider(color: Color.defaultRed)
                HStack(alignment: .top) {
                    BrightVerticalDivider(height: Constants.graphLayoutHeight)
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(height: Constants.graphLayoutHeight)
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(height: Constants.graphLayoutHeight)
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(height: Constants.graphLayoutHeight)
                }
            }

            if (data.xDatesDisplay ?? []).count >= 3 {
                VStack {
                    Spacer()
                    HStack(spacing: .spacing0x) {
                        XAxisText(value: data.xBpm![0])
                        XAxisText(value: data.xBpm![1])
                        XAxisText(value: data.xBpm![2])
                    }
                }
            }
        }
    }

    struct XAxisText: View {
        let value: Int?
        var body: some View {
            if let value, value != 0 {
                BrightText(
                    String(value) + " BPM",
                    size: .body1,
                    color: .defaultRed
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, .spacing05x)
            } else {
                BrightText(
                    "- BPM",
                    size: .body1,
                    color: .defaultRed
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, .spacing05x)
            }
        }
    }

    private class Constants {
        static let yAxisWidth: CGFloat = 25
        static let graphHeight: CGFloat = 86
        static let graphLayoutHeight: CGFloat = 101
        static let barMarkWidth: CGFloat = 4
        static let chartGradientHeight: CGFloat = 57
    }
}

#Preview {
    ExerciseCompleteRecoveryWidget(
        data: HeartWorkoutSummaryPostWorkoutHeartGraphData()
    )
}
