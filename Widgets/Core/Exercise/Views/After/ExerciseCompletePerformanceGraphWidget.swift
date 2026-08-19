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

private struct MetricFramesKey: PreferenceKey {
    static let defaultValue: [ExerciseCompleteGraphMetric: CGRect] = [:]

    static func reduce(
        value: inout [ExerciseCompleteGraphMetric: CGRect],
        nextValue: () -> [ExerciseCompleteGraphMetric: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// One metric's line, readout and styling. Both the readout row and the graph
// stack render from this, so they can't drift apart.
private struct MetricSpec: Identifiable {
    let metric: ExerciseCompleteGraphMetric
    let title: String
    let unit: String
    let values: [Double]
    let yTicks: [Int]?
    // Shown when nothing is scrubbed — the workout's average for this metric.
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
    // When supplied, only that metric's line is drawn and the readouts become
    // the switcher for it. Left `nil` the card stacks every metric at once.
    var selectedMetric: Binding<ExerciseCompleteGraphMetric>?
    var graphHeight: CGFloat = Constants.graphHeight

    @State private var metricFrames: [ExerciseCompleteGraphMetric: CGRect] = [:]

    private var isSwitchable: Bool {
        selectedMetric != nil
    }

    private var visibleMetrics: [MetricSpec] {
        guard let selectedMetric else { return metrics }
        let match = metrics.filter { $0.metric == selectedMetric.wrappedValue }
        return match.isEmpty ? Array(metrics.prefix(1)) : match
    }

    var body: some View {
        if isSwitchable {
            switcher
        } else {
            stack
        }
    }

    // Over the map only one metric is drawn at a time and the readouts double as
    // the switcher for it, so that mode keeps its own card.
    private var switcher: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            BrightText("Breakdown", size: .body1, weight: .regular)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(selectedSecond?.hmsString ?? "0:00:00", size: .body1)
                    .padding(.bottom, .spacing1x)

                selectedTexts
            }
            .padding(.vertical, .spacing2x)

            BrightDivider()

            SharedGraphComponent(
                selectedSecond: $selectedSecond,
                duration: duration,
                metrics: visibleMetrics,
                graphHeight: graphHeight
            )
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    // On the Performance tab every metric is stacked on the page itself, each
    // reading out in its own colour beside its trace.
    private var stack: some View {
        SharedGraphComponent(
            selectedSecond: $selectedSecond,
            duration: duration,
            metrics: metrics,
            graphHeight: graphHeight,
            readout: readout(for:)
        )
    }

    private var selectedTexts: some View {
        HStack(spacing: isSwitchable ? .spacing1x : .spacing3x) {
            ForEach(metrics) { spec in
                SelectedComponentText(
                    numberText: readout(for: spec),
                    numberTextColor: spec.color,
                    unitString: spec.unit,
                    isSelected: isSwitchable && selectedMetric?.wrappedValue == spec.metric,
                    isSwitchable: isSwitchable,
                    onTap: isSwitchable ? { select(spec.metric) } : nil
                )
                .background {
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: MetricFramesKey.self,
                            value: [spec.metric: geo.frame(in: .named(Constants.readoutSpace))]
                        )
                    }
                }
            }
        }
        .coordinateSpace(name: Constants.readoutSpace)
        .onPreferenceChange(MetricFramesKey.self) { metricFrames = $0 }
        // Simultaneous so the buttons still handle plain taps; this adds sliding
        // your finger along the row to drag the pill between readouts.
        .simultaneousGesture(dragGesture, including: isSwitchable ? .all : .subviews)
        .brightHaptic(.light, trigger: selectedMetric?.wrappedValue)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // Nearest centre rather than a strict hit test, so the pill still
                // follows while the finger is in the gaps between readouts.
                let nearest = metricFrames.min {
                    abs($0.value.midX - value.location.x) < abs($1.value.midX - value.location.x)
                }
                guard let metric = nearest?.key else { return }
                select(metric)
            }
    }

    private func select(_ metric: ExerciseCompleteGraphMetric) {
        guard selectedMetric?.wrappedValue != metric else { return }

        // Ease, not spring: a spring overshoots, and on a colour that reads as the
        // line flashing between the old and new tint before it settles.
        withAnimation(.brightEaseInOut) {
            selectedMetric?.wrappedValue = metric
        }
    }

    enum Constants {
        static let graphHeight: CGFloat = 70
        static let readoutSpace = "metricReadouts"
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
    fileprivate struct SharedGraphComponent: View {
        @Binding var selectedSecond: Double?
        let duration: TimeDuration
        let metrics: [MetricSpec]
        let graphHeight: CGFloat
        // Supplied by the stacked mode, where each row shows its own value.
        var readout: ((MetricSpec) -> String)?

        var body: some View {
            VStack(alignment: .leading, spacing: .spacing0x) {
                BrightDivider()

                VStack(spacing: .spacing0x) {
                    if let single = metrics.first, metrics.count == 1 {
                        // Deliberately not in the ForEach: keyed by metric, each
                        // one would be a different view, so switching would swap
                        // rather than interpolate. One stable row lets Charts
                        // animate the line's points and colour between metrics.
                        row(single, isLast: true)
                    } else {
                        ForEach(Array(metrics.enumerated()), id: \.element.id) { index, spec in
                            row(spec, isLast: index == metrics.count - 1)
                        }
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
                readout: readout.map { ($0(spec), spec.unit) }
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
        // Value and unit for the stacked mode's label column.
        var readout: (value: String, unit: String)?

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

        @ViewBuilder
        private var label: some View {
            if let readout {
                VStack(alignment: .leading, spacing: .spacing1x) {
                    BrightText(title, size: .body1)

                    HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                        BrightText(readout.value, size: .standout4, color: color)
                            .monospacedDigit()

                        BrightText(readout.unit, size: .body1, color: .semiLightTextColor)
                    }
                }
            } else {
                BrightText(title, size: .body1)
                    .contentTransition(.numericText())
                    .animation(.brightEaseInOut, value: title)
                    .padding(.top, .spacing2x)
                    .frame(height: graphHeight, alignment: .topLeading)
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
            .chartYScale(domain: Double(yTicks?.first ?? 80) ... Double(yTicks?.last ?? 150))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartXSelection(value: chartSelectionBinding)
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

    struct SelectedComponentText: View {
        let numberText: String
        let numberTextColor: Color
        let unitString: String
        var isSelected = false
        // Only the switcher gets capsule chrome; the stacked card is plain text.
        var isSwitchable = false
        var onTap: (() -> Void)?

        var body: some View {
            if let onTap {
                Button(action: onTap) { readout }
                    .buttonStyle(.plain)
            } else {
                readout
            }
        }

        private var readout: some View {
            HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                BrightText(
                    numberText,
                    size: .heading,
                    color: isSelected ? .black : numberTextColor
                )
                .frame(maxHeight: Constants.lineHeight)

                BrightText(
                    unitString,
                    size: .body1,
                    color: isSelected ? .black.opacity(.lowOpacity) : .lightTextColor
                )
            }
            .padding(.horizontal, isSwitchable ? .spacing1x : .spacing0x)
            .frame(height: Constants.cellHeight)
            .background {
                if isSwitchable {
                    Capsule()
                        .fill(isSelected ? numberTextColor : .clear)
                        .overlay {
                            Capsule().strokeBorder(
                                isSelected ? .clear : numberTextColor.opacity(.semiLowOpacity),
                                lineWidth: 0.5
                            )
                        }
                }
            }
            .contentShape(.rect)
        }

        private enum Constants {
            static let lineHeight: CGFloat = 24
            static let cellHeight: CGFloat = 30
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
    let workout = ExerciseDemoComplete.cardio.workout

    return ExerciseCompletePerformanceGraphWidget(
        hrAvg: workout.hrAvg ?? 0,
        duration: workout.duration ?? TimeDuration(),
        avgPace: workout.avgPaceSecondsPerKm ?? 0,
        altitudeGain: workout.altitudeGain ?? Amount(unit: "M", value: 0),
        data: ExerciseCompleteCombinedGraphData(
            heartData: workout.heartGraph ?? HeartWorkoutSummaryHeartGraphData(),
            altitudeData: workout.altitudeGraph ?? HeartWorkoutSummaryAltitudeGraphData(),
            paceData: workout.paceGraph ?? HeartWorkoutSummaryPaceGraphData(),
            cadenceData: workout.cadenceGraph ?? HeartWorkoutSummaryCadenceGraphData()
        ),
        selectedSecond: $selectedSecond
    )
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}
