//
//  BrightLineChartWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import Charts
import SwiftUI

struct BrightLineChartWidgetV5: View {
    struct Sample: Identifiable, Hashable {
        let date: Date
        let value: Double

        var id: Date { date }
    }

    // A stretch of the window to highlight on the large size, such as a workout.
    struct Event: Identifiable, Hashable {
        let start: Date
        let end: Date
        let systemImage: String
        let color: Color

        var id: Date { start }

        var midpoint: Date {
            start.addingTimeInterval(end.timeIntervalSince(start) / 2)
        }
    }

    enum Window: String, CaseIterable, Codable, Identifiable {
        case rolling1h
        case rolling6h
        case rolling12h
        case fixed6h
        case fixed12h

        var id: Self { self }

        var title: String {
            "\(isFixed ? "Fixed" : "Rolling") \(hours)h"
        }

        var span: String {
            hours == 1 ? "1 hour" : "\(hours) hours"
        }

        var isFixed: Bool {
            self == .fixed6h || self == .fixed12h
        }

        var duration: TimeInterval {
            Double(hours) * 60 * 60
        }

        // A dot every 10 minutes for the hour, otherwise one an hour.
        var tickCount: Int {
            self == .rolling1h ? 7 : hours + 1
        }

        // A fixed window steps forward by half its length, on the clock, so its left
        // half is always a complete block and the right half fills in until the next step.
        func interval(endingAt latest: Date) -> DateInterval {
            guard isFixed else {
                return DateInterval(start: latest.addingTimeInterval(-duration), duration: duration)
            }
            let step = duration / 2
            let midnight = Calendar.current.startOfDay(for: latest)
            let blockStart = midnight.addingTimeInterval((latest.timeIntervalSince(midnight) / step).rounded(.down) * step)
            return DateInterval(start: blockStart.addingTimeInterval(-step), duration: duration)
        }

        // Rolling windows count back from now; fixed ones name the hours they start and step at.
        func labels(for interval: DateInterval) -> (leading: String, trailing: String) {
            if isFixed {
                let midpoint = interval.start.addingTimeInterval(duration / 2)
                return (interval.start.formatted(.brightHour), midpoint.formatted(.brightHour))
            }
            return (hours == 1 ? "60m ago" : "\(hours)h ago", "Now")
        }

        private var hours: Int {
            switch self {
            case .rolling1h: 1
            case .rolling6h, .fixed6h: 6
            case .rolling12h, .fixed12h: 12
            }
        }
    }

    let title: String
    let systemImage: String
    let tint: Color
    let unit: String
    let samples: [Sample]
    var events: [Event] = []
    var window: Window = .rolling1h
    let size: BrightWidgetSizeV5
    var allowsSelection = true

    @State private var selectedDate: Date?

    var body: some View {
        Group {
            if size == .small {
                compactLayout
            } else {
                expandedLayout
            }
        }
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .onChange(of: allowsSelection) { _, allows in
            if !allows {
                selectedDate = nil
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(title), average \(display(average)) \(unit), high \(display(high)), low \(display(low))"
        )
    }

    // MARK: - Layouts

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            header

            chart(domain: sparklineDomain)
                .frame(maxHeight: .infinity)
                .padding(.trailing, .spacing1x)

            VStack(alignment: .leading, spacing: .spacing0x) {
                windowLabels(color: .lightTextColor)
                    .padding(.trailing, .spacing1x)

                reading(selectedSample?.value ?? current, unit: unit, valueSize: .huge, unitSize: .body3, weight: .light)
                    // Digits never use the room every line keeps below its baseline, so
                    // it's pulled into the padding rather than lifting the number.
                    .padding(.bottom, Font.standardUIFont(size: .huge, weight: .light)?.descender ?? 0)
            }
        }
    }

    private var expandedLayout: some View {
        VStack(alignment: .leading, spacing: size == .large ? .spacing4x : .spacing2x) {
            HStack(alignment: .top, spacing: .spacing1x) {
                header

                Spacer(minLength: .spacing0x)

                reading(
                    selectedSample?.value ?? average,
                    unit: unit,
                    valueSize: size == .large ? .huge2 : .standout3,
                    unitSize: .body1,
                    weight: .regular
                )
            }

            plotArea
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing05x) {
                Image(systemName: systemImage)
                    .font(.standard(size: .subheading, weight: .light))
                    .foregroundStyle(tint)

                BrightText(title, size: .body1, weight: .regular)

                if size != .small {
                    extreme("arrow.up", value: high, color: tint)

                    extreme("arrow.down", value: low, color: .defaultCyan)
                }
            }
            .lineLimit(1)

            BrightText("Latest: \(latest.formatted(.brightTime))", size: .body2, color: .lightTextColor)
        }
    }

    private func extreme(_ systemImage: String, value: Double, color: Color) -> some View {
        HStack(spacing: .spacing0x) {
            Image(systemName: systemImage)
                .font(.standard(size: .body3, weight: .regular))

            BrightText(display(value), size: .body3, color: color, weight: .regular)
                .monospacedDigit()
        }
        .foregroundStyle(color)
    }

    private func reading(
        _ value: Double,
        unit: String,
        valueSize: FontSizes,
        unitSize: FontSizes,
        weight: Font.Weight
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            BrightText(display(value), size: valueSize, weight: weight)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.brightEaseInOut, value: display(value))

            BrightText(unit, size: unitSize, color: .lightTextColor, weight: weight)
        }
        .lineLimit(1)
    }

    // MARK: - Chart

    private var plotArea: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                guideLabelColumn
                    .frame(width: Constants.axisLabelWidth)

                chart(domain: domain)
                    .overlay { eventIcons }
            }

            VStack(spacing: .spacing05x) {
                ticks

                windowLabels(color: .semiLightTextColor)
            }
            .padding(.leading, Constants.axisLabelWidth + .spacing1x)
        }
        .padding(.trailing, .spacing1x)
    }

    private func chart(domain: ClosedRange<Double>) -> some View {
        Chart {
            if size == .large {
                ForEach(events) { event in
                    RectangleMark(
                        xStart: .value("Start", event.start),
                        xEnd: .value("End", event.end),
                        yStart: .value("Floor", domain.lowerBound),
                        yEnd: .value("Ceiling", domain.upperBound)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [event.color.opacity(.veryLowOpacity), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }

            ForEach(visibleSamples) { sample in
                AreaMark(
                    x: .value("Time", sample.date),
                    yStart: .value("Floor", domain.lowerBound),
                    yEnd: .value(unit, sample.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [tint.opacity(.semiLowOpacity), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Time", sample.date),
                    y: .value(unit, sample.value)
                )
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: Constants.lineWidth))
            }

            RuleMark(y: .value("Average", average))
                .brightDashedLineV5()

            if size != .small {
                RuleMark(y: .value("High", high))
                    .brightDashedLineV5(tint.opacity(.lowOpacity))

                RuleMark(y: .value("Low", low))
                    .brightDashedLineV5(.defaultCyan.opacity(.lowOpacity))
            }

            // Sits on the latest reading, and follows the finger while a point is held.
            if let marked = selectedSample ?? visibleSamples.last {
                RuleMark(x: .value("Marker", marked.date))
                    .foregroundStyle(Color.textColor)
                    .lineStyle(StrokeStyle(lineWidth: Constants.hairline))

                PointMark(
                    x: .value("Marker", marked.date),
                    y: .value(unit, marked.value)
                )
                .symbol {
                    // The card-coloured ring cuts the dot out of the line and marker behind it.
                    Circle()
                        .fill(Color.textColor)
                        .frame(width: Constants.pointDiameter, height: Constants.pointDiameter)
                        .frame(width: Constants.pointRingDiameter, height: Constants.pointRingDiameter)
                        .background(Circle().fill(Color.defaultHomeCards))
                }
            }
        }
        .chartXScale(domain: start...end)
        .chartYScale(domain: domain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .modifier(SelectionModifier(isEnabled: allowsSelection, selection: selection))
    }

    // The chart hides its own axes so its plot fills the frame, which lets the
    // labels and icons below be placed with the same value-to-point mapping.
    private var guideLabelColumn: some View {
        GeometryReader { geometry in
            ForEach(Array(guideLabels.enumerated()), id: \.offset) { _, label in
                BrightText(display(label.value), size: .body5, color: label.color, weight: label.weight)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: geometry.size.width, alignment: .trailing)
                    .position(
                        x: geometry.size.width / 2,
                        y: yPosition(of: label.value, height: geometry.size.height)
                    )
            }
        }
    }

    @ViewBuilder
    private var eventIcons: some View {
        if size == .large {
            GeometryReader { geometry in
                ForEach(events) { event in
                    Image(systemName: event.systemImage)
                        .font(.standard(size: .body1, weight: .light))
                        .foregroundStyle(event.color)
                        .position(
                            x: xPosition(of: event.midpoint, width: geometry.size.width),
                            y: -Constants.eventIconOffset
                        )
                }
            }
        }
    }

    private var ticks: some View {
        HStack(spacing: .spacing0x) {
            ForEach(0 ..< window.tickCount, id: \.self) { index in
                if index > 0 {
                    Spacer(minLength: .spacing0x)
                }

                Capsule()
                    .fill(index == nowTickIndex ? Color.textColor : Color.lightTextColor)
                    .frame(width: .spacing05x, height: index == 0 ? Constants.startTickHeight : .spacing05x)
            }
        }
    }

    // A fixed window's second label sits under its middle dot, so each label takes
    // half the width. While a point is held both give way to its time, which rides the selection line.
    private func windowLabels(color: Color) -> some View {
        let labels = window.labels(for: interval)

        return HStack(spacing: .spacing0x) {
            BrightText(labels.leading, size: .body5, color: color)
                .frame(maxWidth: .infinity, alignment: .leading)

            BrightText(labels.trailing, size: .body5, color: color)
                .frame(maxWidth: .infinity, alignment: window.isFixed ? .leading : .trailing)
        }
        .lineLimit(1)
        .opacity(selectedSample == nil ? .opaque : .zero)
        .overlay(alignment: .leading) {
            if let selectedSample {
                GeometryReader { geometry in
                    BrightText(selectedSample.date.formatted(.brightTime), size: .body5, color: color)
                        .monospacedDigit()
                        .fixedSize()
                        .frame(width: Constants.heldLabelWidth)
                        .offset(x: heldLabelOffset(for: selectedSample.date, width: geometry.size.width))
                }
                .transition(.opacity)
            }
        }
        .animation(.brightEaseInOut, value: selectedSample == nil)
    }

    // Centred on the line, but never past either end of the plot.
    private func heldLabelOffset(for date: Date, width: CGFloat) -> CGFloat {
        let centred = xPosition(of: date, width: width) - Constants.heldLabelWidth / 2
        return min(max(centred, 0), max(width - Constants.heldLabelWidth, 0))
    }

    // MARK: - Values

    private struct GuideLabel {
        let value: Double
        let color: Color
        let weight: Font.Weight
    }

    private var guideLabels: [GuideLabel] {
        var labels = [
            GuideLabel(value: high, color: tint, weight: .light),
            GuideLabel(value: average, color: .textColor, weight: .regular),
            GuideLabel(value: low, color: .defaultCyan, weight: .light),
        ]
        if size == .large {
            labels += [domain.upperBound, domain.lowerBound].map {
                GuideLabel(value: $0, color: .textColor.opacity(.veryLowOpacity), weight: .regular)
            }
        }
        return labels
    }

    private var selectedSample: Sample? {
        guard let selectedDate else { return nil }
        return visibleSamples.min {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        }
    }

    private var selection: Binding<Date?> {
        Binding {
            selectedDate
        } set: { newDate in
            let previous = selectedSample?.date
            selectedDate = newDate
            if let current = selectedSample?.date, current != previous {
                BrightHaptic.light.play()
            }
        }
    }

    private var latest: Date {
        samples.last?.date ?? .now
    }

    private var interval: DateInterval {
        window.interval(endingAt: latest)
    }

    private var start: Date {
        interval.start
    }

    private var end: Date {
        interval.end
    }

    private var visibleSamples: [Sample] {
        samples.filter { $0.date >= start && $0.date <= end }
    }

    private var nowTickIndex: Int {
        let lastIndex = window.tickCount - 1
        let progress = latest.timeIntervalSince(start) / window.duration
        return min(max(Int((progress * Double(lastIndex)).rounded()), 0), lastIndex)
    }

    private var values: [Double] {
        visibleSamples.map(\.value)
    }

    private var high: Double {
        values.max() ?? 0
    }

    private var low: Double {
        values.min() ?? 0
    }

    private var average: Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    private var current: Double {
        visibleSamples.last?.value ?? 0
    }

    // Rounded out to the next step either side so the extremes never touch the edge.
    private var domain: ClosedRange<Double> {
        let step = Constants.domainStep
        let lower = max(((low - step) / step).rounded(.down) * step, 0)
        let upper = ((high + step) / step).rounded(.up) * step
        return lower ... upper
    }

    private var sparklineDomain: ClosedRange<Double> {
        low ... max(high, low + 1)
    }

    private func yPosition(of value: Double, height: CGFloat) -> CGFloat {
        let span = domain.upperBound - domain.lowerBound
        guard span > 0 else { return height }
        return height * (1 - (value - domain.lowerBound) / span)
    }

    private func xPosition(of date: Date, width: CGFloat) -> CGFloat {
        width * date.timeIntervalSince(start) / window.duration
    }

    private func display(_ value: Double) -> String {
        "\(Int(value.rounded()))"
    }

    private struct SelectionModifier: ViewModifier {
        let isEnabled: Bool
        let selection: Binding<Date?>

        func body(content: Content) -> some View {
            if isEnabled {
                content.chartXSelection(value: selection)
            } else {
                content
            }
        }
    }

    private enum Constants {
        static let domainStep: Double = 10
        static let axisLabelWidth: CGFloat = 26
        static let lineWidth: CGFloat = 1
        static let hairline: CGFloat = 0.5
        static let pointDiameter: CGFloat = 8
        static let pointRingDiameter: CGFloat = 14
        static let heldLabelWidth: CGFloat = 60
        static let startTickHeight: CGFloat = 7
        static let eventIconOffset: CGFloat = .spacing2x
    }
}

#Preview {
    let now = Date.now
    let samples = (0 ... 60).map { minute in
        BrightLineChartWidgetV5.Sample(
            date: now.addingTimeInterval(Double(minute - 60) * 60),
            value: 85 + 20 * sin(Double(minute) / 6)
        )
    }
    let workout = BrightLineChartWidgetV5.Event(
        start: now.addingTimeInterval(-50 * 60),
        end: now.addingTimeInterval(-30 * 60),
        systemImage: "figure.outdoor.cycle",
        color: .defaultOrange
    )

    ScrollView {
        VStack(alignment: .leading, spacing: .spacing205x) {
            ForEach(BrightWidgetSizeV5.allCases, id: \.self) { size in
                BrightLineChartWidgetV5(
                    title: "Heart Rate",
                    systemImage: "heart.fill",
                    tint: .defaultRed,
                    unit: "BPM",
                    samples: samples,
                    events: [workout],
                    size: size
                )
                .frame(width: size == .small ? 174 : 363, height: size == .large ? 363 : 174)
            }
        }
        .padding(.spacing205x)
    }
    .background(Color.defaultBackground)
}
