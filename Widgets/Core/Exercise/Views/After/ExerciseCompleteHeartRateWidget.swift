//
//  ExerciseCompleteHeartRateWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import Charts
import SwiftUI

struct ExerciseCompleteHeartRateWidget: View {
    let hrAvg: Double
    let hrPeak: Double?
    let startDate: String
    let endDate: String
    let data: HeartWorkoutSummaryHeartGraphData

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            HStack(spacing: .spacing0x) {
                reading(
                    title: "AVG HR",
                    value: hrAvg,
                    icon: .asset(ImageNames.heartPulseRedV5)
                )

                BrightVerticalDivider(height: Constants.readingRule)

                reading(
                    title: "Peak HR",
                    value: hrPeak,
                    icon: .system("arrow.up.heart.fill", tint: .defaultRed)
                )
                .padding(.leading, .spacing3x)
            }

            chart
                .frame(height: Constants.graphHeight)
                .padding(.top, .spacing4x)

            VStack(spacing: .spacing1x) {
                BrightDivider()

                HStack {
                    BrightText(timeLabel(startDate), size: .body1, color: .lightTextColor)
                    Spacer()
                    BrightText(timeLabel(endDate), size: .body1, color: .lightTextColor)
                }
            }
            .padding(.trailing, Constants.legendWidth + .spacing1x)
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    private func reading(title: String, value: Double?, icon: ExerciseCompleteIcon) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(title, size: .body1, weight: .regular)

            HStack(alignment: .lastTextBaseline, spacing: .spacing1x) {
                ExerciseCompleteIconView(icon: icon, size: Constants.iconSize)
                    // The glyph belongs to the number, not the baseline it sits on.
                    .alignmentGuide(.lastTextBaseline) { $0[.bottom] - Constants.iconLift }

                BrightText(
                    value != nil ? String(Int(value!.rounded())) : "-",
                    size: .huge2,
                    color: value == nil ? .lightTextColor : .textColor
                )
                .monospacedDigit()

                BrightText("BPM", size: .body1, color: .lightTextColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // The peak and average sit as labelled dashed rules across the trace, so the
    // shape of the effort reads against both without an axis.
    private var chart: some View {
        HStack(spacing: .spacing1x) {
            Chart {
                if let peakSample {
                    RuleMark(y: .value("Peak", peakSample))
                        .foregroundStyle(Color.defaultRed.opacity(.lowOpacity))
                        .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [6, 4]))
                }

                RuleMark(y: .value("Average", hrAvg))
                    .foregroundStyle(Color.defaultSkyBlue.opacity(.lowOpacity))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [6, 4]))

                ForEach(samples.indices, id: \.self) { index in
                    LineMark(
                        x: .value("Sample", index),
                        y: .value("BPM", samples[index])
                    )
                    .interpolationMethod(.linear)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Color.defaultRed)
                }
            }
            .chartYScale(domain: lowest ... highest)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)

            legend
        }
    }

    // Each label rides at its own rule's height rather than sitting in a fixed
    // stack, so the reading and the line it names stay level.
    private var legend: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                if let peakSample {
                    legendLabel(
                        "\(Int(peakSample.rounded())) Peak",
                        color: .defaultRed,
                        value: peakSample,
                        in: proxy.size.height
                    )
                }

                legendLabel(
                    "\(Int(hrAvg.rounded())) AVG",
                    color: .defaultSkyBlue,
                    value: hrAvg,
                    in: proxy.size.height
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: Constants.legendWidth)
    }

    private func legendLabel(
        _ text: String,
        color: Color,
        value: Double,
        in height: CGFloat
    ) -> some View {
        BrightText(text, size: .body1, color: color)
            .monospacedDigit()
            .frame(height: Constants.legendLabelHeight)
            .offset(y: yPosition(for: value, in: height) - Constants.legendLabelHeight / 2)
    }

    private func yPosition(for value: Double, in height: CGFloat) -> CGFloat {
        let span = max(highest - lowest, 1)
        let fraction = min(1, max(0, (value - lowest) / span))
        return height * (1 - fraction)
    }

    private var samples: [Double] {
        (data.data ?? []).map { Double($0.value ?? 0) }
    }

    // The line the trace actually touches, which sits below the workout's peak
    // reading whenever that came from a moment the graph doesn't sample.
    private var peakSample: Double? {
        samples.max() ?? hrPeak
    }

    private var lowest: Double {
        Double(data.yTicks?.first ?? 80)
    }

    private var highest: Double {
        Double(data.yTicks?.last ?? 150)
    }

    private func timeLabel(_ iso: String) -> String {
        iso.isEmpty ? "-" : iso.isoStringToDate().formatted(.brightTime)
    }

    private enum Constants {
        static let readingRule: CGFloat = 64
        static let iconSize: CGFloat = 26
        static let iconLift: CGFloat = 4
        static let graphHeight: CGFloat = 130
        static let legendWidth: CGFloat = 68
        static let legendLabelHeight: CGFloat = 20
    }
}

#Preview {
    let workout = ExerciseDemoComplete.cardio.workout

    return ExerciseCompleteHeartRateWidget(
        hrAvg: workout.hrAvg ?? 0,
        hrPeak: workout.hrPeak,
        startDate: workout.startTime ?? "",
        endDate: workout.endTime ?? "",
        data: workout.heartGraph ?? HeartWorkoutSummaryHeartGraphData()
    )
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}
