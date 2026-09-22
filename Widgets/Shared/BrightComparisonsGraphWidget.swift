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

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            header
                .padding(.bottom, .spacing2x)

            BrightDivider()

            rows

            BrightDivider()

            TimeAxis(
                startLabel: timeLabel(heartData.data?.first?.heartDate),
                endLabel: timeLabel(heartData.data?.last?.heartDate),
                scrub: scrub
            )
            .padding(.leading, Constants.labelWidth)
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

    var durationSeconds: Double {
        guard let firstStr = heartData.data?.first?.heartDate,
              let lastStr = heartData.data?.last?.heartDate
        else { return 0 }
        return lastStr.isoStringToDate().timeIntervalSince(firstStr.isoStringToDate())
    }

    private func heldLabel(at second: Double) -> String {
        guard let startString = heartData.data?.first?.heartDate else { return "" }

        return startString.isoStringToDate().addingTimeInterval(second).formatted(.brightTime)
    }

    private func timeLabel(_ iso: String?) -> String {
        guard let iso else { return "-" }
        return iso.isoStringToDate().formatted(.brightTime)
    }

    private var rows: some View {
        VStack(spacing: .spacing0x) {
            ForEach(Array(metrics.enumerated()), id: \.element.title) { index, metric in
                MetricGraph(
                    selectedSecond: $selectedSecond,
                    durationSeconds: durationSeconds,
                    title: metric.title,
                    color: metric.color,
                    values: metric.values,
                    yTicks: metric.yTicks,
                    graphHeight: Constants.graphHeight,
                    readout: (readout(for: metric), metric.unit)
                )

                if index < metrics.count - 1 {
                    BrightDivider()
                        .padding(.leading, Constants.labelWidth)
                }
            }
        }
    }

    enum Constants {
        static let labelWidth: CGFloat = 92
        static let graphHeight: CGFloat = 70
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
           let value = metric.values.interpolated(at: selectedSecond, over: durationSeconds) {
            return String(Int(value.rounded()))
        }

        let values = metric.values
        let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        return String(Int(avg.rounded()))
    }

    private var scrub: TimeAxis.Scrub? {
        guard let selectedSecond else { return nil }

        return TimeAxis.Scrub(
            fraction: selectedSecond / max(durationSeconds, 1),
            label: heldLabel(at: selectedSecond)
        )
    }
}

// MARK: - Metric graph

extension BrightComparisonsGraphWidget {
    struct MetricGraph: View {
        @Binding var selectedSecond: Double?
        let durationSeconds: Double
        let title: String
        let color: Color
        let values: [Double]
        let yTicks: [Int]?
        let graphHeight: CGFloat
        let readout: (value: String, unit: String)

        var body: some View {
            HStack(spacing: .spacing0x) {
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
                    BrightText(readout.value, size: .standout3, color: color)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.brightEaseInOut, value: readout.value)

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
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(color)
                }

                if let selectedSecond, let selectedValue = values.interpolated(at: selectedSecond, over: durationSeconds) {
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
            .chartXScale(domain: 0 ... max(durationSeconds, 1))
            .chartYScale(domain: yDomain)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartXSelection(value: chartSelectionBinding)
            .background { fill }
        }

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
                .chartXScale(domain: 0 ... max(durationSeconds, 1))
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
            return (Double(index) / Double(values.count - 1)) * durationSeconds
        }

        private enum Constants {
            static let labelWidth: CGFloat = BrightComparisonsGraphWidget.Constants.labelWidth
        }
    }
}

// MARK: - Time axis

extension BrightComparisonsGraphWidget {
    struct TimeAxis: View {
        struct Scrub {
            let fraction: Double
            let label: String
        }

        let startLabel: String
        let endLabel: String
        var scrub: Scrub?

        var body: some View {
            HStack(spacing: .spacing0x) {
                BrightText(startLabel, size: .body1, color: .lightTextColor)

                Spacer(minLength: .spacing2x)

                BrightText(endLabel, size: .body1, color: .lightTextColor)
            }
            .opacity(scrub == nil ? .opaque : 0)
            .overlay(alignment: .leading) {
                if let scrub {
                    held(scrub)
                        .transition(.opacity)
                }
            }
            .animation(.brightEaseInOut, value: scrub == nil)
        }

        private func held(_ scrub: Scrub) -> some View {
            GeometryReader { proxy in
                BrightText(scrub.label, size: .body1, color: .lightTextColor)
                    .monospacedDigit()
                    .frame(width: Constants.heldWidth)
                    .multilineTextAlignment(.center)
                    .offset(x: offset(for: scrub.fraction, in: proxy.size.width))
            }
        }

        private func offset(for fraction: Double, in width: CGFloat) -> CGFloat {
            let clamped = CGFloat(min(max(fraction, 0), 1))
            let centred = width * clamped - Constants.heldWidth / 2
            return min(max(centred, 0), max(width - Constants.heldWidth, 0))
        }

        private enum Constants {
            static let heldWidth: CGFloat = 80
        }
    }
}

// MARK: - Interpolation

extension [Double] {
    fileprivate func interpolated(at second: Double, over duration: Double) -> Double? {
        guard !isEmpty else { return nil }

        let position = (second / Swift.max(duration, 1)) * Double(count - 1)
        let lowerIndex = Swift.max(0, Swift.min(count - 1, Int(position.rounded(.down))))
        let upperIndex = Swift.max(0, Swift.min(count - 1, Int(position.rounded(.up))))
        let fraction = position - Double(lowerIndex)

        return self[lowerIndex] + (self[upperIndex] - self[lowerIndex]) * fraction
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
