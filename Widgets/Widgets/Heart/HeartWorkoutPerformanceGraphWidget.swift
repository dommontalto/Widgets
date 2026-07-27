//
//  HeartWorkoutPerformanceGraphWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import Charts
import SwiftUI

struct HeartWorkoutCombinedGraphData {
    let heartData: HeartWorkoutSummaryHeartGraphData
    let altitudeData: HeartWorkoutSummaryAltitudeGraphData
    let paceData: HeartWorkoutSummaryPaceGraphData
    let cadenceData: HeartWorkoutSummaryCadenceGraphData
}

enum HeartWorkoutGraphMetric: CaseIterable {
    case heartRate
    case altitude
    case pace
    case cadence
}

/// One metric's line, readout and styling. Both the readout row and the graph
/// stack render from this, so they can't drift apart.
private struct MetricSpec: Identifiable {
    let metric: HeartWorkoutGraphMetric
    let title: String
    let color: Color
    let unit: String
    let values: [Double]
    let yTicks: [Int]?
    /// Shown when nothing is scrubbed — the workout's average for this metric.
    let restingReadout: String

    var id: HeartWorkoutGraphMetric { metric }
}

struct HeartWorkoutPerformanceGraphWidget: View {
    let hrAvg: Double
    let duration: TimeDuration
    let avgPace: Int
    let altitudeGain: Amount
    let data: HeartWorkoutCombinedGraphData

    /// Owned by the caller so the map sheet can drive its camera from the same
    /// scrub position.
    @Binding var selectedSecond: Double?
    /// When supplied, only that metric's line is drawn and the readouts become
    /// the switcher for it. Left `nil` the card stacks every metric at once.
    var selectedMetric: Binding<HeartWorkoutGraphMetric>?
    var graphHeight: CGFloat = Constants.graphHeight

    private var isSwitchable: Bool {
        selectedMetric != nil
    }

    private var visibleMetrics: [MetricSpec] {
        guard let selectedMetric else { return metrics }
        let match = metrics.filter { $0.metric == selectedMetric.wrappedValue }
        return match.isEmpty ? Array(metrics.prefix(1)) : match
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            BrightText("Breakdown", size: .body1)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(selectedSecond?.hmsString ?? "0:00:00", size: .body3)

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
        .modifier(CardModifier(color: .sheetModalCards))
    }

    private var selectedTexts: some View {
        HStack(spacing: .spacing2x) {
            ForEach(metrics) { spec in
                SelectedComponentText(
                    numberText: readout(for: spec),
                    numberTextColor: spec.color,
                    unitString: spec.unit,
                    isDimmed: isSwitchable && selectedMetric?.wrappedValue != spec.metric,
                    onTap: isSwitchable
                        ? {
                            withAnimation(.brightSnappy) {
                                selectedMetric?.wrappedValue = spec.metric
                            }
                        }
                        : nil
                )
            }
        }
    }

    /// Not `private`: `graphHeight` is the default for a memberwise-init
    /// parameter, so it has to be at least as visible as the initialiser.
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

extension HeartWorkoutPerformanceGraphWidget {
    fileprivate var metrics: [MetricSpec] {
        var specs: [MetricSpec] = []

        let heartValues = (data.heartData.data ?? []).map { Double($0.value ?? 0) }
        if !heartValues.isEmpty {
            specs.append(
                MetricSpec(
                    metric: .heartRate,
                    title: "Heart Rate",
                    color: .defaultWarningRed,
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
                    color: .defaultBlue,
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
                    color: .defaultBrightGreen,
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
                    color: .defaultBrightPink,
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

extension HeartWorkoutPerformanceGraphWidget {
    fileprivate struct SharedGraphComponent: View {
        @Binding var selectedSecond: Double?
        let duration: TimeDuration
        let metrics: [MetricSpec]
        let graphHeight: CGFloat

        var body: some View {
            VStack(alignment: .leading, spacing: .spacing0x) {
                VStack(spacing: .spacing0x) {
                    ForEach(metrics) { spec in
                        MetricGraphComponent(
                            selectedSecond: $selectedSecond,
                            duration: duration,
                            title: spec.title,
                            color: spec.color,
                            values: spec.values,
                            yTicks: spec.yTicks,
                            graphHeight: graphHeight
                        )
                        BrightDivider()
                    }
                }

                HStack {
                    BrightText("0:00:00", size: .body3, color: .lightTextColor)

                    Spacer()

                    BrightText(duration.totalSeconds.hmsString, size: .body3, color: .lightTextColor)
                }
                .padding(.top, .spacing1x)
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

        private let haptic = UIImpactFeedbackGenerator(style: .light)

        var body: some View {
            HStack(spacing: .spacing0x) {
                // Fixed height rather than a Spacer: a flexible label column would
                // stretch the row to whatever the parent proposes, which fills the
                // screen when this card floats over the map instead of scrolling.
                BrightText(title, size: .body3)
                    .padding(.top, .spacing2x)
                    .frame(width: Constants.labelWidth, height: graphHeight, alignment: .topLeading)

                BrightVerticalDivider(height: graphHeight)

                chart
                    .frame(height: graphHeight)
            }
            .frame(height: graphHeight)
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
                        haptic.impactOccurred()
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

        private enum Constants {
            static let labelWidth: CGFloat = 70
        }
    }

    struct SelectedComponentText: View {
        let numberText: String
        let numberTextColor: Color
        let unitString: String
        var isDimmed = false
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
                    size: .standout4,
                    color: numberTextColor,
                    scaleTextSize: Constants.numberMinimumScale
                )
                .frame(maxHeight: Constants.lineHeight)

                BrightText(unitString, size: .subheading, color: .lightTextColor)
            }
            .frame(height: Constants.cellHeight)
            .opacity(isDimmed ? .semiLowOpacity : .opaque)
            .contentShape(.rect)
        }

        private enum Constants {
            static let lineHeight: CGFloat = 24
            static let cellHeight: CGFloat = 30
            /// Four readouts at 24pt only just fit the card, so let the digits
            /// tighten rather than truncate on the widest combinations.
            static let numberMinimumScale: CGFloat = 0.8
        }
    }
}

extension TimeDuration {
    var totalSeconds: Double {
        (Double(hour ?? 0) * 3600) + (Double(minute ?? 0) * 60) + Double(second ?? 0)
    }
}

extension [Double] {
    /// Reads the value at `second` by treating the array as evenly spaced across `duration`.
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
    let workout = HeartDemoData.workout

    return HeartWorkoutPerformanceGraphWidget(
        hrAvg: workout.hrAvg ?? 0,
        duration: workout.duration ?? TimeDuration(),
        avgPace: workout.avgPaceSecondsPerKm ?? 0,
        altitudeGain: workout.altitudeGain ?? Amount(unit: "M", value: 0),
        data: HeartWorkoutCombinedGraphData(
            heartData: workout.heartGraph ?? HeartWorkoutSummaryHeartGraphData(),
            altitudeData: workout.altitudeGraph ?? HeartWorkoutSummaryAltitudeGraphData(),
            paceData: workout.paceGraph ?? HeartWorkoutSummaryPaceGraphData(),
            cadenceData: workout.cadenceGraph ?? HeartWorkoutSummaryCadenceGraphData()
        ),
        selectedSecond: $selectedSecond
    )
    .padding(.spacing3x)
    .background(Color.sheetBackground)
}
