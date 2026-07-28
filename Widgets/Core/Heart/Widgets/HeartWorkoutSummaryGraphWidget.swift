//
//  HeartWorkoutSummaryGraphWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import Charts
import SwiftUI

struct HeartWorkoutSummaryGraphWidget: View {
    let hrAvg: Double
    let zoneAvg: Int
    let duration: TimeDuration
    let startDate: String
    let endDate: String
    let data: HeartWorkoutSummaryHeartGraphData

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            BrightText("Heart Rate", size: .body1)

            HStack(spacing: .spacing1x) {
                Image(ImageNames.heartPulseRedV5)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.iconSize, height: Constants.iconSize)

                HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                    BrightText(String(Int(hrAvg)), size: .huge)

                    BrightText("BPM AVG", size: .body1, color: .lightTextColor)
                }
            }
            .padding(.top, .spacing3x)

            HStack(spacing: .spacing1x) {
                chart
                    .frame(height: Constants.graphHeight)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .trailing, spacing: .spacing0x) {
                    BrightText(String(highest), size: .body3, color: .semiLightTextColor)

                    Spacer()

                    BrightText(String(lowest), size: .body3, color: .semiLightTextColor)
                }
                .frame(width: Constants.yAxisWidth, height: Constants.graphHeight, alignment: .topLeading)
            }

            HStack {
                BrightText("0", size: .body3, color: .lightTextColor)

                Spacer()

                BrightText(duration.asString, size: .body3, color: .lightTextColor)
                    .padding(.trailing, Constants.yAxisWidth + .spacing05x)
            }
            .padding(.top, .spacing1x)
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .sheetModalCards))
    }

    var chart: some View {
        ZStack {
            gridLines

            HStack {
                BrightVerticalDivider(height: Constants.graphHeight)
                Spacer()
                BrightVerticalDivider(height: Constants.graphHeight)
            }

            Chart {
                RuleMark(y: .value("Average", Int(hrAvg)))
                    .foregroundStyle(Color.defaultWarningRed)
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [6, 4]))
                    .annotation(position: .trailing, alignment: .leading) {
                        BrightText(" \(Int(hrAvg))", size: .body3, color: .defaultWarningRed)
                    }

                ForEach((data.data ?? []).indices, id: \.self) { index in
                    let heartData = data.data![index]

                    LineMark(
                        x: .value("hour", heartData.heartDate?.isoStringToDate() ?? Date()),
                        y: .value("index", heartData.value ?? 0)
                    )
                    .interpolationMethod(.cardinal(tension: 1.1))
                    .lineStyle(StrokeStyle(lineWidth: 0.75))
                    .foregroundStyle(Color.defaultWarningRed)
                }
            }
            .chartYScale(domain: lowest ... highest)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
        }
    }

    private var gridLines: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let width = geometry.size.width

            Path { path in
                for y in [CGFloat(0), height] {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color.textColor.opacity(.ultraLowOpacity), lineWidth: 0.5)

            Path { path in
                for fraction in [0.2, 0.4, 0.6, 0.8] {
                    let y = height * fraction
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(
                Color.textColor.opacity(.ultraLowOpacity),
                style: StrokeStyle(lineWidth: 0.5, dash: [6, 4])
            )
        }
    }

    var lowest: Int {
        data.yTicks?.first ?? 80
    }

    var highest: Int {
        data.yTicks?.last ?? 150
    }

    private enum Constants {
        static let yAxisWidth: CGFloat = 25
        static let graphHeight: CGFloat = 140
        static let iconSize: CGFloat = 28
    }
}

#Preview {
    let workout = HeartDemoData.workout

    return HeartWorkoutSummaryGraphWidget(
        hrAvg: workout.hrAvg ?? 0,
        zoneAvg: workout.zoneAvg ?? 0,
        duration: workout.duration ?? TimeDuration(),
        startDate: workout.startTime ?? "",
        endDate: workout.endTime ?? "",
        data: workout.heartGraph ?? HeartWorkoutSummaryHeartGraphData()
    )
    .padding(.spacing3x)
    .background(Color.sheetBackground)
}
