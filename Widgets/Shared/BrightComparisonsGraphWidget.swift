//
//  BrightComparisonsGraphWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import Charts
import SwiftUI

// Names match the Bright app's sleep daily payload so the widget ports back
// unchanged; here they're only ever filled from the demo below.
struct SleepGraphHeartDailyResponseHeartGraph {
    var yTicks: [Int]?
    var data: [SleepGraphHeartDailyResponseHeartGraphData]?
}

struct SleepGraphHeartDailyResponseHeartGraphData {
    var heartDate: String?
    var value: Int?
    var zone: Int?
}

struct SleepGraphHeartDailyResponseSp02Graph {
    var yTicks: [Int]?
    var xDates: [String]?
    var data: [Int]?
}

struct SleepGraphHeartDailyResponseBreathsGraph {
    var yTicks: [Int]?
    var xDates: [String]?
    var data: [Int]?
}

struct BrightComparisonsGraphWidget: View {
    let heartData: SleepGraphHeartDailyResponseHeartGraph
    let sp02Data: SleepGraphHeartDailyResponseSp02Graph
    let breathsData: SleepGraphHeartDailyResponseBreathsGraph

    @State private var selectedSecond: Double?

    private var labelWidth: CGFloat {
        ExerciseCompletePerformanceGraphWidget.MetricGraphComponent.Constants.labelWidth
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            header
                .padding(.bottom, .spacing2x)

            BrightDivider()

            rows

            BrightDivider()

            ExerciseGraphTimeAxis(
                startLabel: timeLabel(heartData.data?.first?.heartDate),
                endLabel: timeLabel(heartData.data?.last?.heartDate),
                scrub: scrub
            )
            .padding(.leading, labelWidth)
            .padding(.top, .spacing1x)
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText("Performance", size: .body1)

            BrightText(timeRange, size: .body3, color: .lightTextColor)
        }
    }

    private var timeRange: String {
        guard let first = heartData.data?.first?.heartDate,
              let last = heartData.data?.last?.heartDate
        else { return "" }

        return Date.brightTimeRange(from: first.isoStringToDate(), to: last.isoStringToDate())
    }

    private var rows: some View {
        VStack(spacing: .spacing0x) {
            ForEach(Array(metrics.enumerated()), id: \.element.title) { index, metric in
                ExerciseCompletePerformanceGraphWidget.MetricGraphComponent(
                    selectedSecond: $selectedSecond,
                    duration: duration,
                    title: metric.title,
                    color: metric.color,
                    values: metric.values,
                    yTicks: metric.yTicks,
                    graphHeight: Constants.graphHeight,
                    readout: (readout(for: metric), metric.unit)
                )

                if index < metrics.count - 1 {
                    BrightDivider()
                        .padding(.leading, labelWidth)
                }
            }
        }
    }
}

// MARK: - Metrics

extension BrightComparisonsGraphWidget {
    private struct Metric {
        let title: String
        let unit: String
        let color: Color
        let values: [Double]
        let yTicks: [Int]?
    }

    private var metrics: [Metric] {
        var specs: [Metric] = []

        let heartValues = (heartData.data ?? []).map { Double($0.value ?? 0) }
        if !heartValues.isEmpty {
            specs.append(
                Metric(
                    title: "Heart Rate",
                    unit: "BPM",
                    color: .defaultRed,
                    values: heartValues,
                    yTicks: heartData.yTicks
                )
            )
        }

        let sp02Values = (sp02Data.data ?? []).map { Double($0) }
        if !sp02Values.isEmpty {
            specs.append(
                Metric(
                    title: "Sp02",
                    unit: "%",
                    color: .defaultElectricBlue,
                    values: sp02Values,
                    yTicks: sp02Data.yTicks
                )
            )
        }

        let breathsValues = (breathsData.data ?? []).map { Double($0) }
        if !breathsValues.isEmpty {
            specs.append(
                Metric(
                    title: "Breaths",
                    unit: "/ MIN",
                    color: .defaultSkyBlue,
                    values: breathsValues,
                    yTicks: breathsData.yTicks
                )
            )
        }

        return specs
    }

    private func readout(for metric: Metric) -> String {
        if let selectedSecond,
           let value = interpolatedValue(values: metric.values, at: selectedSecond) {
            return String(Int(value.rounded()))
        }

        let values = metric.values
        let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        return String(Int(avg.rounded()))
    }

    private func interpolatedValue(values: [Double], at second: Double) -> Double? {
        guard !values.isEmpty else { return nil }
        let position = (second / max(durationSeconds, 1)) * Double(values.count - 1)
        let lowerIndex = max(0, min(values.count - 1, Int(floor(position))))
        let upperIndex = max(0, min(values.count - 1, Int(ceil(position))))
        let fraction = position - Double(lowerIndex)
        return values[lowerIndex] + (values[upperIndex] - values[lowerIndex]) * fraction
    }
}

// MARK: - Duration & Time Helpers

extension BrightComparisonsGraphWidget {
    var durationSeconds: Double {
        guard let firstStr = heartData.data?.first?.heartDate,
              let lastStr = heartData.data?.last?.heartDate
        else { return 0 }
        return lastStr.isoStringToDate().timeIntervalSince(firstStr.isoStringToDate())
    }

    private var duration: TimeDuration {
        let total = Int(durationSeconds.rounded())
        return TimeDuration(hour: total / 3600, minute: (total % 3600) / 60, second: total % 60)
    }

    private var scrub: ExerciseGraphTimeAxis.Scrub? {
        guard let selectedSecond else { return nil }

        return ExerciseGraphTimeAxis.Scrub(
            fraction: selectedSecond / max(durationSeconds, 1),
            label: heldLabel(at: selectedSecond)
        )
    }

    private func heldLabel(at second: Double) -> String {
        guard let startString = heartData.data?.first?.heartDate else { return "" }

        return startString.isoStringToDate().addingTimeInterval(second).formatted(.brightTime)
    }

    private func timeLabel(_ iso: String?) -> String {
        guard let iso else { return "-" }
        return iso.isoStringToDate().formatted(.brightTime)
    }

    private enum Constants {
        static let graphHeight: CGFloat = 70
    }
}

// MARK: - Demo

enum BrightComparisonsDemo {
    static let start = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date())!

    static var heartGraph: SleepGraphHeartDailyResponseHeartGraph {
        let points = (0 ..< 96).map { index in
            let t = Double(index) / 95
            let value = 62 - 12 * sin(t * .pi) + 4 * sin(Double(index) * 1.3)
            return SleepGraphHeartDailyResponseHeartGraphData(
                heartDate: start.addingTimeInterval(t * 8 * 3600).isoString,
                value: Int(value),
                zone: 1
            )
        }
        return SleepGraphHeartDailyResponseHeartGraph(yTicks: [40, 80], data: points)
    }

    static var sp02Graph: SleepGraphHeartDailyResponseSp02Graph {
        let values = (0 ..< 96).map { 96 + Int(2 * sin(Double($0) * 0.4)) }
        return SleepGraphHeartDailyResponseSp02Graph(yTicks: [90, 100], data: values)
    }

    static var breathsGraph: SleepGraphHeartDailyResponseBreathsGraph {
        let values = (0 ..< 96).map { 14 + Int(3 * sin(Double($0) * 0.25)) }
        return SleepGraphHeartDailyResponseBreathsGraph(yTicks: [8, 22], data: values)
    }
}

#Preview {
    BrightComparisonsGraphWidget(
        heartData: BrightComparisonsDemo.heartGraph,
        sp02Data: BrightComparisonsDemo.sp02Graph,
        breathsData: BrightComparisonsDemo.breathsGraph
    )
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultBackground.ignoresSafeArea())
}
