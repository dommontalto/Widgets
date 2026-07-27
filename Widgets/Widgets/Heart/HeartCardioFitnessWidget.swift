//
//  HeartCardioFitnessWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import Charts
import SwiftUI

struct HeartCardioFitnessWidget: View {
    let data: HeartSummaryCardioFitnessData
    var showSecondaryLabel = true
    var sheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack {
                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText("Cardio Fitness", size: .body1)

                    if showSecondaryLabel, let title = data.title {
                        BrightText(
                            "Latest: \(title.isoStringToDate().stringFromDate(strFormatter: "d MMM"))",
                            size: .body3,
                            color: .lightTextColor
                        )
                    }
                }

                Spacer()

                BrightHealthStatus(status: data.label ?? "")
            }

            HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                Image(ImageNames.cardioFitnessV5)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.iconSize, height: Constants.iconSize)

                BrightText(
                    data.value?.toString ?? "--",
                    size: .huge,
                    color: data.value == nil ? .lightTextColor : .textColor
                )

                BrightText("VO2 MAX", size: .subheading, color: .lightTextColor)
            }

            ZStack {
                chart
                VerticalDashedLineWidget()
            }
            .frame(height: Constants.chartHeight)
            .padding(.top, .spacing105x)

            if xTickTriplet.count == 3 {
                HStack {
                    BrightText("\(xTickTriplet[0])", size: .body5, color: .semiLightTextColor)
                    Spacer()
                    BrightText("\(xTickTriplet[1])", size: .body5, color: .semiLightTextColor)
                    Spacer()
                    BrightText("\(xTickTriplet[2])", size: .body5, color: .semiLightTextColor)
                }
            }
        }
        .padding(.spacing3x)
        .modifier(sheet ? CardModifier(color: .sheetModalCards) : CardModifier())
    }

    /// Centres the scale on the user's own VO2 max so the marker never sits at an edge.
    private var xTickTriplet: [Int] {
        if let value = data.value {
            let centre = Int((value / 5.0).rounded()) * 5
            return [centre - 5, centre, centre + 5]
        }
        if let ticks = data.xTicks, ticks.count >= 3 {
            return [ticks[0], ticks[1], ticks[2]]
        }
        return []
    }

    var chart: some View {
        let start = xTickTriplet.count == 3 ? Double(xTickTriplet[0]) : Double(data.xTicks?.first ?? 30)
        let end = xTickTriplet.count == 3 ? Double(xTickTriplet[2]) : Double(data.xTicks?.last ?? 50)

        return Chart {
            BarMark(
                xStart: .value("Time", start),
                xEnd: .value("Time", end),
                y: .value("State", "Fitness"),
                height: MarkDimension(floatLiteral: Constants.chartHeight)
            )
            .foregroundStyle(Color.defaultBlue.opacity(.veryMinimalOpacity))
            .cornerRadius(.cornerRadius22)
        }
        .chartXScale(domain: start ... end)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geo in
                if let value = data.value {
                    let total = end - start
                    let lineStart = value - (total > 0 ? total / 200 : 0)

                    let lineStartX = min(max(proxy.position(forX: lineStart) ?? 0, 0), geo.size.width)

                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.defaultBlue.opacity(0),
                                        Color.defaultBlue.opacity(.lowOpacity),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: lineStartX, height: geo.size.height)
                            .position(x: lineStartX / 2, y: geo.size.height / 2)

                        Rectangle()
                            .fill(Color.defaultBlue)
                            .frame(width: 1, height: geo.size.height)
                            .position(x: lineStartX, y: geo.size.height / 2)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius22))
                    .allowsHitTesting(false)
                }
            }
        }
    }

    private enum Constants {
        static let chartHeight: CGFloat = 44
        static let iconSize: CGFloat = 26
    }
}

#Preview {
    HeartCardioFitnessWidget(
        data: HeartDemoData.workout.cardioFitness ?? HeartSummaryCardioFitnessData(),
        sheet: true
    )
    .padding(.spacing3x)
    .background(Color.sheetBackground)
}
