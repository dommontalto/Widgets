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

struct HeartWorkoutPerformanceGraphWidget: View {
    let hrAvg: Double
    let duration: TimeDuration
    let avgPace: Int
    let altitudeGain: Amount
    let data: HeartWorkoutCombinedGraphData

    @State private var selectedSecond: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            BrightText("Breakdown", size: .body1)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(selectedSecond?.hmsString ?? "0:00:00", size: .body3)

                selectedTexts
            }
            .padding(.vertical, .spacing2x)

            BrightDivider()

            SharedGraphComponent(selectedSecond: $selectedSecond, duration: duration, data: data)
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .sheetModalCards))
    }

    private var selectedTexts: some View {
        HStack(spacing: .spacing2x) {
            SelectedComponentText(
                numberText: selectedBpmString,
                numberTextColor: .defaultWarningRed,
                unitString: "BPM"
            )

            if let altitudeUnit = altitudeGain.unit, altitudeGain.displayValue != "0" {
                SelectedComponentText(
                    numberText: selectedAltitudeGainString,
                    numberTextColor: .defaultBlue,
                    unitString: altitudeUnit
                )
            }

            if avgPace != 0 {
                SelectedComponentText(
                    numberText: selectedPaceString,
                    numberTextColor: .defaultBrightGreen,
                    unitString: "/ KM"
                )
            }

            if !(data.cadenceData.data ?? []).isEmpty {
                SelectedComponentText(
                    numberText: selectedCadenceString,
                    numberTextColor: .defaultBrightPink,
                    unitString: "SPM"
                )
            }
        }
    }
}

extension Double {
    fileprivate var hmsString: String {
        let total = Int(rounded())
        return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}

// MARK: - Stacked graphs

extension HeartWorkoutPerformanceGraphWidget {
    struct SharedGraphComponent: View {
        @Binding var selectedSecond: Double?
        let duration: TimeDuration
        let data: HeartWorkoutCombinedGraphData

        var body: some View {
            VStack(alignment: .leading, spacing: .spacing0x) {
                VStack(spacing: .spacing0x) {
                    if let heartData = data.heartData.data {
                        MetricGraphComponent(
                            selectedSecond: $selectedSecond,
                            duration: duration,
                            title: "Heart Rate",
                            color: .defaultWarningRed,
                            values: heartData.map { Double($0.value ?? 0) },
                            yTicks: data.heartData.yTicks
                        )
                        BrightDivider()
                    }

                    if let altitudeData = data.altitudeData.data {
                        MetricGraphComponent(
                            selectedSecond: $selectedSecond,
                            duration: duration,
                            title: "Altitude",
                            color: .defaultBlue,
                            values: altitudeData.map(Double.init),
                            yTicks: data.altitudeData.yTicks
                        )
                        BrightDivider()
                    }

                    if let paceData = data.paceData.data {
                        MetricGraphComponent(
                            selectedSecond: $selectedSecond,
                            duration: duration,
                            title: "Pace",
                            color: .defaultBrightGreen,
                            values: paceData.map(Double.init),
                            yTicks: data.paceData.yTicks
                        )
                        BrightDivider()
                    }

                    if let cadenceData = data.cadenceData.data {
                        MetricGraphComponent(
                            selectedSecond: $selectedSecond,
                            duration: duration,
                            title: "Cadence",
                            color: .defaultBrightPink,
                            values: cadenceData.map(Double.init),
                            yTicks: data.cadenceData.yTicks
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

        private let haptic = UIImpactFeedbackGenerator(style: .light)

        var body: some View {
            HStack(spacing: .spacing0x) {
                VStack {
                    BrightText(title, size: .body3)
                        .padding(.top, .spacing2x)

                    Spacer()
                }
                .frame(width: Constants.labelWidth, alignment: .leading)

                BrightVerticalDivider(height: Constants.graphHeight)

                chart
                    .frame(height: Constants.graphHeight)
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
            static let graphHeight: CGFloat = 70
        }
    }

    struct SelectedComponentText: View {
        let numberText: String
        let numberTextColor: Color
        let unitString: String

        var body: some View {
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

// MARK: - Selected readouts

extension HeartWorkoutPerformanceGraphWidget {
    private var selectedBpmString: String {
        let values = (data.heartData.data ?? []).map { Double($0.value ?? 0) }
        if let selectedSecond, let bpm = values.interpolated(at: selectedSecond, over: duration.totalSeconds) {
            return String(Int(bpm.rounded()))
        }
        return String(Int(hrAvg.rounded()))
    }

    private var selectedAltitudeGainString: String {
        let values = (data.altitudeData.data ?? []).map(Double.init)
        if let selectedSecond, let altitude = values.interpolated(at: selectedSecond, over: duration.totalSeconds) {
            return String(Int(altitude.rounded()))
        }
        return altitudeGain.displayValue
    }

    private var selectedPaceString: String {
        let values = (data.paceData.data ?? []).map(Double.init)
        if let selectedSecond, let pace = values.interpolated(at: selectedSecond, over: duration.totalSeconds) {
            return formatPaceAsMinPerKm(pace)
        }
        return formatPaceAsMinPerKm(Double(avgPace))
    }

    /// Cadence has no separate average in the payload, so the resting readout is
    /// the mean of the graph itself.
    private var selectedCadenceString: String {
        let values = (data.cadenceData.data ?? []).map(Double.init)
        if let selectedSecond, let cadence = values.interpolated(at: selectedSecond, over: duration.totalSeconds) {
            return String(Int(cadence.rounded()))
        }
        guard !values.isEmpty else { return "--" }
        return String(Int((values.reduce(0, +) / Double(values.count)).rounded()))
    }

    private func formatPaceAsMinPerKm(_ paceInSeconds: Double) -> String {
        let totalSeconds = Int(paceInSeconds.rounded())
        guard totalSeconds > 0 else { return "0'00\"" }

        // A pace this slow is almost certainly bad GPS, so show hours rather than "72'14"".
        if totalSeconds >= 3600 {
            return "\(totalSeconds / 3600):\(String(format: "%02d", (totalSeconds % 3600) / 60))h"
        }

        return "\(totalSeconds / 60)'\(String(format: "%02d", totalSeconds % 60))\""
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
        )
    )
    .padding(.spacing3x)
    .background(Color.sheetBackground)
}
