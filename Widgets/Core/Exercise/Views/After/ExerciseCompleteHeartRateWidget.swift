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
    let data: ExerciseCardioHeartGraph

    @State private var selectedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            BrightText("Heart Rate", size: .body1)

            reading
                .padding(.top, .spacing3x)

            chart
                .frame(height: Constants.graphHeight)
                .padding(.top, .spacing1x)

            VStack(spacing: .spacing1x) {
                BrightDivider()

                ExerciseGraphTimeAxis(
                    startLabel: timeLabel(startDate),
                    endLabel: timeLabel(endDate),
                    scrub: scrub
                )
            }
            .padding(.trailing, Constants.legendWidth + .spacing1x)
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    private var reading: some View {
        HStack(alignment: .lastTextBaseline, spacing: .spacing1x) {
            ExerciseCompleteIconView(
                icon: .system("arrow.up.heart.fill", tint: .defaultRed),
                size: Constants.iconSize
            )
            // The glyph belongs to the number, not the baseline it sits on.
            .alignmentGuide(.lastTextBaseline) { $0[.bottom] - Constants.iconLift }

            BrightText(readingValue, size: .huge2, color: readingColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.brightEaseInOut, value: readingValue)

            BrightText("BPM", size: .body1, color: .lightTextColor)
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

                if let selectedSample {
                    RuleMark(
                        x: .value("Selected", selectedSample.index),
                        yStart: .value("BPM", lowest),
                        yEnd: .value("BPM", highest)
                    )
                    .foregroundStyle(Color.textColor.opacity(.lowOpacity))
                    .lineStyle(StrokeStyle(lineWidth: 1))

                    PointMark(
                        x: .value("Selected", selectedSample.index),
                        y: .value("BPM", selectedSample.value)
                    )
                    .symbolSize(20)
                    .foregroundStyle(Color.defaultRed)
                }
            }
            .chartYScale(domain: lowest ... highest)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartXSelection(value: selectionBinding)
            .background { fill }

            legend
        }
    }

    // A gradient across the whole plot masked by the area under the trace, so it
    // is anchored to the frame rather than to the line's own peak — a gradient
    // handed straight to the AreaMark would restart at every high point.
    private var fill: some View {
        LinearGradient(
            colors: [Color.defaultRed.opacity(.veryMinimalOpacity), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .mask {
            Chart {
                ForEach(samples.indices, id: \.self) { index in
                    AreaMark(
                        x: .value("Sample", index),
                        y: .value("BPM", samples[index])
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(.black)
                }
            }
            .chartYScale(domain: lowest ... highest)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
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
        .offset(x: .spacing05x)
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

    private var readingValue: String {
        if let selectedSample {
            return String(Int(selectedSample.value.rounded()))
        }

        guard let peakSample else { return "-" }
        return String(Int(peakSample.rounded()))
    }

    private var readingColor: Color {
        peakSample == nil ? .lightTextColor : .textColor
    }

    private var selectedSample: (index: Int, value: Double)? {
        guard let selectedIndex, samples.indices.contains(selectedIndex) else { return nil }
        return (selectedIndex, samples[selectedIndex])
    }

    private var selectionBinding: Binding<Int?> {
        Binding(
            get: { selectedIndex },
            set: { newValue in
                if let newValue, newValue != selectedIndex {
                    BrightHaptic.light.play()
                }
                selectedIndex = newValue
            }
        )
    }

    private var samples: [Double] {
        (data.data ?? []).map { Double($0.value ?? 0) }
    }

    // The line the trace actually touches, which sits below the session's peak
    // reading whenever that came from a moment the graph doesn't sample.
    private var peakSample: Double? {
        samples.max() ?? hrPeak
    }

    private var lowest: Double {
        Double(data.yTicks?.first ?? 80)
    }

    private var highest: Double {
        max(peakSample ?? Double(data.yTicks?.last ?? 150), lowest + 1)
    }

    private var scrub: ExerciseGraphTimeAxis.Scrub? {
        guard let selectedSample else { return nil }

        let last = max(samples.count - 1, 1)
        return ExerciseGraphTimeAxis.Scrub(
            fraction: Double(selectedSample.index) / Double(last),
            label: heldLabel(at: selectedSample.index)
        )
    }

    // Each reading carries its own stamp; a run that arrived without them falls
    // back to where the sample sits between the two ends.
    private func heldLabel(at index: Int) -> String {
        if let stamp = (data.data ?? [])[safe: index]?.heartDate, !stamp.isEmpty {
            return stamp.isoStringToDate().formatted(.brightTime)
        }

        guard !startDate.isEmpty, !endDate.isEmpty else { return "-" }

        let start = startDate.isoStringToDate()
        let span = endDate.isoStringToDate().timeIntervalSince(start)
        let fraction = Double(index) / Double(max(samples.count - 1, 1))
        return start.addingTimeInterval(span * fraction).formatted(.brightTime)
    }

    private func timeLabel(_ iso: String) -> String {
        iso.isEmpty ? "-" : iso.isoStringToDate().formatted(.brightTime)
    }

    private enum Constants {
        static let iconSize: CGFloat = 26
        static let iconLift: CGFloat = 4
        static let graphHeight: CGFloat = 130
        static let legendWidth: CGFloat = 68
        static let legendLabelHeight: CGFloat = 20
    }
}

#Preview {
    let session = ExerciseDemoComplete.cardio.summary

    return ExerciseCompleteHeartRateWidget(
        hrAvg: session.hrAvg ?? 0,
        hrPeak: session.hrPeak,
        startDate: session.startTime ?? "",
        endDate: session.endTime ?? "",
        data: session.heartGraph ?? ExerciseCardioHeartGraph()
    )
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}
