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

    // A stretch of the range to highlight on the large size, such as a workout.
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

    let appearance: BrightWidgetAppearanceV5
    let range: BrightWidgetRangeV5
    let size: BrightWidgetSizeV5
    let allowsSelection: Bool

    // Worked out once here rather than on every read: the body asks for them dozens of
    // times a pass, and every frame of a held finger, over hundreds of readings.
    private let latest: Date
    private let interval: DateInterval
    private let visibleSamples: [Sample]
    private let visibleEvents: [Event]
    private let high: Double
    private let low: Double
    private let average: Double

    @State private var selectedDate: Date?
    @State private var heldLabelWidth: CGFloat = 0

    init(
        appearance: BrightWidgetAppearanceV5,
        samples: [Sample],
        events: [Event] = [],
        range: BrightWidgetRangeV5 = .rolling1h,
        size: BrightWidgetSizeV5,
        allowsSelection: Bool = true
    ) {
        self.appearance = appearance
        self.range = range
        self.size = size
        self.allowsSelection = allowsSelection

        let latest = samples.last?.date ?? .now
        let interval = range.interval(endingAt: latest)
        let visible = Self.plotted(samples, in: interval, bucket: range.bucket)
        let values = visible.map(\.value)

        self.latest = latest
        self.interval = interval
        visibleSamples = visible
        visibleEvents = Self.trimmed(events, to: interval)
        high = values.max() ?? 0
        low = values.min() ?? 0
        average = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    private var title: String { appearance.title }
    private var systemImage: String { appearance.systemImage }
    private var tint: Color { appearance.tint }
    private var unit: String { appearance.unit ?? "" }

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
                .brightDebugBackgroundV5(.red)

            chart(domain: sparklineDomain)
                .frame(maxHeight: .infinity)
                .brightDebugBackgroundV5(.blue)
                .padding(.trailing, .spacing1x)

            VStack(alignment: .leading, spacing: .spacing0x) {
                windowLabels(color: .lightTextColor)
                    .brightDebugBackgroundV5(.green)
                    .padding(.trailing, .spacing1x)

                reading(selectedSample?.value ?? current, unit: unit, valueSize: .huge, unitSize: .body3, weight: .light)
                    // Digits never use the room every line keeps below its baseline, so
                    // it's pulled into the padding rather than lifting the number.
                    .padding(.bottom, Font.standardUIFont(size: .huge, weight: .light)?.descender ?? 0)
                    .brightDebugBackgroundV5(.yellow)
            }
        }
    }

    private var expandedLayout: some View {
        VStack(alignment: .leading, spacing: size == .large ? .spacing4x : .spacing2x) {
            HStack(alignment: .top, spacing: .spacing1x) {
                header
                    .brightDebugBackgroundV5(.red)

                Spacer(minLength: .spacing0x)

                reading(
                    selectedSample?.value ?? average,
                    unit: unit,
                    valueSize: size == .large ? .huge2 : .standout3,
                    unitSize: .body1,
                    weight: .regular
                )
                .brightDebugBackgroundV5(.yellow)
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
                    .foregroundStyle(appearance.iconStyle)

                BrightText(title, size: .body1, weight: .regular)

                if size != .small {
                    extreme("arrow.up", value: high, color: tint)

                    extreme("arrow.down", value: low, color: .defaultCyan)
                }
            }
            .lineLimit(1)

            BrightText("Latest: \(latest.formatted(.brightTime))", size: .body2, color: .lightTextColor)
                .contentTransition(.numericText())
        }
    }

    private func extreme(_ systemImage: String, value: Double, color: Color) -> some View {
        HStack(spacing: .spacing0x) {
            Image(systemName: systemImage)
                .font(.standard(size: .body3, weight: .regular))

            BrightText(display(value), size: .body3, color: color, weight: .regular)
                .monospacedDigit()
                .contentTransition(.numericText())
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
                .contentTransition(.numericText())
        }
        .lineLimit(1)
    }

    // MARK: - Chart

    private var plotArea: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                guideLabelColumn
                    .frame(width: Constants.axisLabelWidth)
                    .brightDebugBackgroundV5(.purple)

                chart(domain: domain)
                    .overlay { eventIcons }
                    .brightDebugBackgroundV5(.blue)
            }

            VStack(spacing: .spacing05x) {
                ticks
                    .brightDebugBackgroundV5(.orange)

                windowLabels(color: .semiLightTextColor)
                    .brightDebugBackgroundV5(.green)
            }
            .padding(.leading, Constants.axisLabelWidth + .spacing1x)
        }
        .padding(.trailing, .spacing1x)
    }

    private func chart(domain: ClosedRange<Double>) -> some View {
        Chart {
            if size == .large {
                ForEach(visibleEvents) { event in
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
                BrightSelectorV5(date: marked.date, value: marked.value)
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
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: geometry.size.width, alignment: .leading)
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
                ForEach(visibleEvents) { event in
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
            ForEach(0 ..< range.tickCount, id: \.self) { index in
                if index > 0 {
                    Spacer(minLength: .spacing0x)
                }

                Capsule()
                    .fill(index == nowTickIndex ? Color.textColor : Color.lightTextColor)
                    .frame(width: .spacing05x, height: index == 0 ? Constants.startTickHeight : .spacing05x)
            }
        }
    }

    // A fixed range's second label sits under its middle dot, so each label takes
    // half the width. While a point is held both give way to its time, which rides the selection line.
    private func windowLabels(color: Color) -> some View {
        let labels = range.labels(for: interval)

        return HStack(spacing: .spacing0x) {
            BrightText(labels.leading, size: .body5, color: color)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity, alignment: .leading)

            BrightText(labels.trailing, size: .body5, color: color)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity, alignment: range.isRolling ? .trailing : .leading)
        }
        .lineLimit(1)
        .opacity(selectedSample == nil ? .opaque : .zero)
        .overlay(alignment: .leading) {
            if let selectedSample {
                GeometryReader { geometry in
                    BrightText(selectedSample.date.formatted(.brightTime), size: .body5, color: color)
                        .monospacedDigit()
                        .fixedSize()
                        .onGeometryChange(for: CGFloat.self, of: \.size.width) { heldLabelWidth = $0 }
                        .offset(x: heldLabelOffset(for: selectedSample.date, width: geometry.size.width))
                }
                .transition(.opacity)
            }
        }
        .animation(.brightEaseInOut, value: selectedSample == nil)
    }

    // Centred on the line, but never past either end of the plot.
    private func heldLabelOffset(for date: Date, width: CGFloat) -> CGFloat {
        let centred = xPosition(of: date, width: width) - heldLabelWidth / 2
        return min(max(centred, 0), max(width - heldLabelWidth, 0))
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
            labels.append(GuideLabel(value: domain.lowerBound, color: .textColor.opacity(.veryLowOpacity), weight: .regular))
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

    private var start: Date {
        interval.start
    }

    private var end: Date {
        interval.end
    }

    // Trimmed to the range, so a zone that started before it only shades the part inside,
    // and one wholly outside it isn't drawn at all.
    private static func trimmed(_ events: [Event], to interval: DateInterval) -> [Event] {
        events.compactMap { event in
            let clampedStart = max(event.start, interval.start)
            let clampedEnd = min(event.end, interval.end)
            guard clampedStart < clampedEnd else { return nil }
            return Event(start: clampedStart, end: clampedEnd, systemImage: event.systemImage, color: event.color)
        }
    }

    private static func plotted(_ samples: [Sample], in interval: DateInterval, bucket: TimeInterval?) -> [Sample] {
        let inWindow = samples.filter { interval.contains($0.date) }
        guard let bucket else { return inWindow }

        // Dated by each bucket's last reading so the line still reaches the latest one.
        let buckets = Dictionary(grouping: inWindow) { Int($0.date.timeIntervalSince(interval.start) / bucket) }
        return buckets.keys.sorted().compactMap { key in
            guard let readings = buckets[key], let last = readings.last else { return nil }
            return Sample(date: last.date, value: readings.map(\.value).reduce(0, +) / Double(readings.count))
        }
    }

    private var nowTickIndex: Int {
        let lastIndex = range.tickCount - 1
        let progress = latest.timeIntervalSince(start) / range.duration
        return min(max(Int((progress * Double(lastIndex)).rounded()), 0), lastIndex)
    }


    private var current: Double {
        visibleSamples.last?.value ?? 0
    }

    // The high line is the top of the graph; the floor is rounded down a step so the
    // low never touches the bottom.
    private var domain: ClosedRange<Double> {
        let step = Constants.domainStep
        let lower = max(((low - step) / step).rounded(.down) * step, 0)
        return lower ... max(high, lower + 1)
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
        width * date.timeIntervalSince(start) / range.duration
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
        systemImage: "figure.strengthtraining.traditional",
        color: .defaultPink
    )

    ScrollView {
        VStack(alignment: .leading, spacing: .spacing205x) {
            ForEach(BrightWidgetSizeV5.allCases, id: \.self) { size in
                BrightLineChartWidgetV5(
                    appearance: BrightWidgetAppearanceV5(title: "Heart Rate", systemImage: "heart.fill", tint: .defaultRed, unit: "BPM"),
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
