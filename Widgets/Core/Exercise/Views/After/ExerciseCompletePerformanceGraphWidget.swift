//
//  ExerciseCompletePerformanceGraphWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import Charts
import SwiftUI

struct ExerciseCompleteCombinedGraphData {
    let heartData: HeartWorkoutSummaryHeartGraphData
    let altitudeData: HeartWorkoutSummaryAltitudeGraphData
    let paceData: HeartWorkoutSummaryPaceGraphData
    let cadenceData: HeartWorkoutSummaryCadenceGraphData
}

enum ExerciseCompleteGraphMetric: CaseIterable {
    case heartRate
    case altitude
    case pace
    case cadence

    var color: Color {
        switch self {
        case .heartRate: .defaultRed
        case .altitude: .defaultBlue
        case .pace: .defaultGreen
        case .cadence: .defaultPink
        }
    }
}

// One metric's line, readout and styling.
private struct MetricSpec: Identifiable {
    let metric: ExerciseCompleteGraphMetric
    let title: String
    let unit: String
    let values: [Double]
    let yTicks: [Int]?
    // Shown when nothing is scrubbed — the session's average for this metric.
    let restingReadout: String

    var id: ExerciseCompleteGraphMetric { metric }
    var color: Color { metric.color }
}

struct ExerciseCompletePerformanceGraphWidget: View {
    let hrAvg: Double
    let duration: TimeDuration
    let avgPace: Int
    let altitudeGain: Amount
    let data: ExerciseCompleteCombinedGraphData

    // Owned by the caller so the map sheet can drive its camera from the same
    // scrub position.
    @Binding var selectedSecond: Double?
    var graphHeight: CGFloat = Constants.graphHeight
    // Floating over the map the card takes glass instead of a card fill, so the
    // route still reads through it.
    var usesGlass = false

    @ViewBuilder
    var body: some View {
        if usesGlass {
            stack
                .padding(.spacing3x)
                .modifier(GlassEffect(shape: .roundedRect, cornerRadius: .cornerRadius24, interactive: false))
        } else {
            stack
                .padding(.spacing3x)
                .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
        }
    }

    private var stack: some View {
        GraphStack(
            selectedSecond: $selectedSecond,
            duration: duration,
            metrics: metrics,
            graphHeight: graphHeight,
            readout: readout(for:)
        )
    }

    enum Constants {
        static let graphHeight: CGFloat = 70
    }
}

extension Double {
    fileprivate var hmsString: String {
        let total = Int(rounded())
        return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}

// MARK: - Metrics

extension ExerciseCompletePerformanceGraphWidget {
    fileprivate var metrics: [MetricSpec] {
        var specs: [MetricSpec] = []

        let heartValues = (data.heartData.data ?? []).map { Double($0.value ?? 0) }
        if !heartValues.isEmpty {
            specs.append(
                MetricSpec(
                    metric: .heartRate,
                    title: "Heart Rate",
                    unit: "BPM",
                    values: heartValues,
                    yTicks: data.heartData.yTicks,
                    restingReadout: String(Int(hrAvg.rounded()))
                )
            )
        }

        let altitudeValues = (data.altitudeData.data ?? []).map(Double.init)
        if !altitudeValues.isEmpty, altitudeGain.displayValue != "0" {
            specs.append(
                MetricSpec(
                    metric: .altitude,
                    title: "Altitude",
                    unit: altitudeGain.unit ?? "M",
                    values: altitudeValues,
                    yTicks: data.altitudeData.yTicks,
                    restingReadout: altitudeGain.displayValue
                )
            )
        }

        let paceValues = (data.paceData.data ?? []).map(Double.init)
        if !paceValues.isEmpty, avgPace != 0 {
            specs.append(
                MetricSpec(
                    metric: .pace,
                    title: "Pace",
                    unit: "/ KM",
                    values: paceValues,
                    yTicks: data.paceData.yTicks,
                    restingReadout: Self.paceString(from: Double(avgPace))
                )
            )
        }

        let cadenceValues = (data.cadenceData.data ?? []).map(Double.init)
        if !cadenceValues.isEmpty {
            // Cadence has no separate average in the payload, so use the mean.
            let mean = cadenceValues.reduce(0, +) / Double(cadenceValues.count)
            specs.append(
                MetricSpec(
                    metric: .cadence,
                    title: "Cadence",
                    unit: "SPM",
                    values: cadenceValues,
                    yTicks: data.cadenceData.yTicks,
                    restingReadout: String(Int(mean.rounded()))
                )
            )
        }

        return specs
    }

    fileprivate func readout(for spec: MetricSpec) -> String {
        guard let selectedSecond,
              let value = spec.values.interpolated(at: selectedSecond, over: duration.totalSeconds)
        else {
            return spec.restingReadout
        }

        return spec.metric == .pace ? Self.paceString(from: value) : String(Int(value.rounded()))
    }

    fileprivate static func paceString(from paceInSeconds: Double) -> String {
        let totalSeconds = Int(paceInSeconds.rounded())
        guard totalSeconds > 0 else { return "0'00\"" }

        // A pace this slow is almost certainly bad GPS, so show hours rather than "72'14"".
        if totalSeconds >= 3600 {
            return "\(totalSeconds / 3600):\(String(format: "%02d", (totalSeconds % 3600) / 60))h"
        }

        return "\(totalSeconds / 60)'\(String(format: "%02d", totalSeconds % 60))\""
    }
}

// MARK: - Stacked graphs

extension ExerciseCompletePerformanceGraphWidget {
    fileprivate struct GraphStack: View {
        @Binding var selectedSecond: Double?
        let duration: TimeDuration
        let metrics: [MetricSpec]
        let graphHeight: CGFloat
        let readout: (MetricSpec) -> String

        var body: some View {
            VStack(alignment: .leading, spacing: .spacing0x) {
                BrightDivider()

                VStack(spacing: .spacing0x) {
                    ForEach(Array(metrics.enumerated()), id: \.element.id) { index, spec in
                        row(spec, isLast: index == metrics.count - 1)
                    }
                }

                BrightDivider()

                HStack {
                    BrightText("0:00:00", size: .body1, color: .lightTextColor)

                    Spacer()

                    BrightText(duration.totalSeconds.hmsString, size: .body1, color: .lightTextColor)
                }
                .padding(.top, .spacing1x)
            }
        }

        @ViewBuilder
        private func row(_ spec: MetricSpec, isLast: Bool) -> some View {
            MetricGraphComponent(
                selectedSecond: $selectedSecond,
                duration: duration,
                title: spec.title,
                color: spec.color,
                values: spec.values,
                yTicks: spec.yTicks,
                graphHeight: graphHeight,
                readout: (readout(spec), spec.unit)
            )

            if !isLast {
                BrightDivider()
                    .padding(.leading, MetricGraphComponent.Constants.labelWidth)
            }
        }
    }

    struct MetricGraphComponent: View {
        @Binding var selectedSecond: Double?
        let duration: TimeDuration
        let title: String
        let color: Color
        let values: [Double]
        let yTicks: [Int]?
        let graphHeight: CGFloat
        let readout: (value: String, unit: String)

        var body: some View {
            HStack(spacing: .spacing0x) {
                // Fixed height rather than a Spacer: a flexible label column would
                // stretch the row to whatever the parent proposes, which fills the
                // screen when this card floats over the map instead of scrolling.
                label
                    .frame(width: Constants.labelWidth, height: graphHeight, alignment: .leading)

                BrightVerticalDivider(height: graphHeight)

                chart
                    .frame(height: graphHeight)
            }
            .frame(height: graphHeight)
        }

        private var label: some View {
            VStack(alignment: .leading, spacing: .spacing1x) {
                BrightText(title, size: .body4)

                HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                    BrightText(readout.value, size: .standout4, color: color)
                        .monospacedDigit()

                    BrightText(readout.unit, size: .body1, color: .semiLightTextColor)
                }
            }
        }

        private var chart: some View {
            Chart {
                ForEach(values.indices, id: \.self) { index in
                    LineMark(
                        x: .value("Second", xSecond(for: index)),
                        y: .value(title, values[index])
                    )
                    .interpolationMethod(.cardinal(tension: 1.1))
                    .lineStyle(StrokeStyle(lineWidth: 0.75))
                    .foregroundStyle(color)
                }

                if let selectedSecond, let selectedValue = value(at: selectedSecond) {
                    RuleMark(x: .value("Selected", selectedSecond))
                        .foregroundStyle(Color.textColor.opacity(.lowOpacity))
                        .lineStyle(StrokeStyle(lineWidth: 1))

                    PointMark(
                        x: .value("Selected", selectedSecond),
                        y: .value(title, selectedValue)
                    )
                    .symbolSize(20)
                    .foregroundStyle(color)
                }
            }
            .chartXScale(domain: 0 ... max(duration.totalSeconds, 1))
            .chartYScale(domain: yDomain)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartXSelection(value: chartSelectionBinding)
            .background { fill }
        }

        // A gradient across the whole row masked by the area under the line, so it
        // is anchored to the dividers rather than to the line's own peak — a
        // gradient handed straight to the AreaMark would restart at every high point.
        private var fill: some View {
            LinearGradient(
                colors: [color.opacity(.veryMinimalOpacity), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .mask {
                Chart {
                    ForEach(values.indices, id: \.self) { index in
                        AreaMark(
                            x: .value("Second", xSecond(for: index)),
                            y: .value(title, values[index])
                        )
                        .interpolationMethod(.cardinal(tension: 1.1))
                        .foregroundStyle(.black)
                    }
                }
                .chartXScale(domain: 0 ... max(duration.totalSeconds, 1))
                .chartYScale(domain: yDomain)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            }
        }

        private var yDomain: ClosedRange<Double> {
            Double(yTicks?.first ?? 80) ... Double(yTicks?.last ?? 150)
        }

        private var chartSelectionBinding: Binding<Double?> {
            Binding(
                get: { selectedSecond },
                set: { newValue in
                    if let newValue, newValue != selectedSecond {
                        BrightHaptic.light.play()
                    }
                    selectedSecond = newValue
                }
            )
        }

        private func xSecond(for index: Int) -> Double {
            guard values.count > 1 else { return 0 }
            return (Double(index) / Double(values.count - 1)) * duration.totalSeconds
        }

        private func value(at second: Double) -> Double? {
            values.interpolated(at: second, over: duration.totalSeconds)
        }

        enum Constants {
            static let labelWidth: CGFloat = 92
        }
    }
}

extension [Double] {
    // Reads the value at `second` by treating the array as evenly spaced across `duration`.
    fileprivate func interpolated(at second: Double, over duration: Double) -> Double? {
        guard !isEmpty else { return nil }

        let position = (second / Swift.max(duration, 1)) * Double(count - 1)
        let lowerIndex = Swift.max(0, Swift.min(count - 1, Int(position.rounded(.down))))
        let upperIndex = Swift.max(0, Swift.min(count - 1, Int(position.rounded(.up))))
        let fraction = position - Double(lowerIndex)

        return self[lowerIndex] + (self[upperIndex] - self[lowerIndex]) * fraction
    }
}

#Preview {
    @Previewable @State var selectedSecond: Double?
    let session = ExerciseDemoComplete.cardio.summary

    return ExerciseCompletePerformanceGraphWidget(
        hrAvg: session.hrAvg ?? 0,
        duration: session.duration ?? TimeDuration(),
        avgPace: session.avgPaceSecondsPerKm ?? 0,
        altitudeGain: session.altitudeGain ?? Amount(unit: "M", value: 0),
        data: ExerciseCompleteCombinedGraphData(
            heartData: session.heartGraph ?? HeartWorkoutSummaryHeartGraphData(),
            altitudeData: session.altitudeGraph ?? HeartWorkoutSummaryAltitudeGraphData(),
            paceData: session.paceGraph ?? HeartWorkoutSummaryPaceGraphData(),
            cadenceData: session.cadenceGraph ?? HeartWorkoutSummaryCadenceGraphData()
        ),
        selectedSecond: $selectedSecond
    )
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}
