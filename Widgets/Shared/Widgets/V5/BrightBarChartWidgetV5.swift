//
//  BrightBarChartWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import Charts
import SwiftUI

// A bar for each hour or each day of the chosen range. Any part of a bar above the
// target turns orange; the week draws a single dashed line at its average.
struct BrightBarChartWidgetV5: View {
    struct Bar: Identifiable, Hashable {
        let index: Int
        // Nil for a slot that hasn't happened yet.
        let value: Double?
        // This slot's own limit, such as the day's calorie allowance, in place of the chart's target.
        var target: Double?
        // Parts stacked from the floor up, such as the day's carbs, fat and protein. Their
        // colours blend into each other, with a mark where each one meets the next.
        var segments: [Segment] = []

        var id: Int { index }
    }

    struct Segment: Hashable {
        let label: String
        let value: Double
        let color: Color
    }

    enum Fill {
        case solid(Color)
        // Cyan at the floor rising through green to yellow at the top of the plot,
        // so a taller bar reaches further up it.
        case rising
    }

    enum Headline {
        case total
        case average
        case current
        // Each segment's average in its own colour, e.g. "C:35 · F:20 · P:65 avg".
        case split
    }

    // The large size's grid of this week's days: each day's value, or how far it
    // landed from the target.
    enum Summary {
        case values([Bar])
        case targets([Bar], target: Double)
    }

    let appearance: BrightWidgetAppearanceV5
    let subtitle: String
    let range: BrightWidgetRangeV5
    let bars: [Bar]
    var fill: Fill = .solid(.defaultGreen)
    var target: Double?
    var headline: Headline = .total
    var comparison: String?
    var summary: Summary?
    let size: BrightWidgetSizeV5
    var allowsSelection = true

    @State private var plotWidth: CGFloat = 0
    @State private var selectedIndex: Int?
    @State private var heldLabelWidth: CGFloat = 0

    private var title: String { appearance.title }
    private var systemImage: String { appearance.systemImage }
    private var tint: Color { appearance.tint }
    private var unit: String? { appearance.unit }

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
                selectedIndex = nil
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(display(headlineValue)) \(unitLabel)")
    }

    // MARK: - Layouts

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            header
                .brightDebugBackgroundV5(.red)

            plotArea(showsGuides: false)
                .frame(maxHeight: .infinity)

            reading(valueSize: .huge205)
                // Digits never use the room every line keeps below its baseline, so
                // it's pulled into the padding rather than lifting the number.
                .padding(.bottom, Font.standardUIFont(size: .huge205, weight: .light)?.descender ?? 0)
                .brightDebugBackgroundV5(.yellow)
        }
    }

    private var expandedLayout: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .top, spacing: .spacing1x) {
                header
                    .brightDebugBackgroundV5(.red)

                Spacer(minLength: .spacing0x)

                VStack(alignment: .trailing, spacing: .spacing05x) {
                    reading(valueSize: size == .large ? .standout1 : .standout3)
                        .brightDebugBackgroundV5(.yellow)

                    if let comparison {
                        comparisonText(comparison)
                            .brightDebugBackgroundV5(.cyan)
                    }
                }
            }

            plotArea(showsGuides: !isSegmented)
                .frame(maxHeight: .infinity)

            if size == .large, let summary {
                BrightDividerV5()
                    .padding(.horizontal, -.spacing205x)

                summaryGrid(summary)
                    .brightDebugBackgroundV5(.pink)
            }
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
            }
            .lineLimit(1)

            BrightText(subtitle, size: .body2, color: .lightTextColor)
                .lineLimit(1)
        }
    }

    private func comparisonText(_ text: String) -> some View {
        BrightText(text, size: .body5, color: .defaultCyan.opacity(.lowOpacity))
            .monospacedDigit()
            .lineLimit(1)
    }

    @ViewBuilder
    private func reading(valueSize: FontSizes) -> some View {
        if headline == .split {
            splitReading
        } else {
            numberReading(valueSize: valueSize)
        }
    }

    private func numberReading(valueSize: FontSizes) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            BrightText(display(headlineValue), size: valueSize, weight: size == .small ? .light : .regular)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.brightEaseInOut, value: display(headlineValue))

            if !unitLabel.isEmpty {
                BrightText(unitLabel, size: .body1, color: .lightTextColor, weight: size == .small ? .light : .regular)
            }
        }
        .lineLimit(1)
    }

    // The held day's split, or the average of every day with readings.
    private var splitReading: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            ForEach(Array(splitValues.enumerated()), id: \.offset) { offset, part in
                if offset > 0 {
                    BrightText("·", size: .body1, color: .lightTextColor)
                }

                HStack(alignment: .firstTextBaseline, spacing: .spacing0x) {
                    BrightText("\(part.label):", size: .body1, color: .lightTextColor, weight: .regular)

                    BrightText(display(part.value), size: .subheading, color: part.color, weight: .regular)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }

            if selectedIndex == nil {
                BrightText("avg", size: .body1, color: .lightTextColor, weight: .regular)
            }
        }
        .lineLimit(1)
        .animation(.brightEaseInOut, value: selectedIndex)
    }

    // MARK: - Plot

    private func plotArea(showsGuides: Bool) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                if showsGuides {
                    guideLabelColumn
                        .frame(width: Constants.axisLabelWidth)
                        .brightDebugBackgroundV5(.purple)
                }

                barArea(showsGuides: showsGuides)
                    .overlay { selectionLayer }
                    .brightDebugBackgroundV5(.blue)
                    .onGeometryChange(for: CGFloat.self, of: \.size.width) { plotWidth = $0 }
            }

            VStack(alignment: .leading, spacing: .spacing05x) {
                slotDots
                    .brightDebugBackgroundV5(.orange)

                slotLabels
                    .brightDebugBackgroundV5(.green)
                    .opacity(selectedIndex == nil ? .opaque : .zero)
                    .overlay(alignment: .leading) { heldLabel }
                    .animation(.brightEaseInOut, value: selectedIndex == nil)
            }
            .padding(.leading, showsGuides ? Constants.axisLabelWidth + .spacing1x : .spacing0x)
        }
    }

    private func barArea(showsGuides: Bool) -> some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let width = geometry.size.width
            let barWidth = barWidth(in: width)

            ZStack(alignment: .topLeading) {
                if showsGuides, showsAverage {
                    averageLine(y: yPosition(of: average, height: height))
                }

                ForEach(bars) { bar in
                    if let value = bar.value, value > 0 {
                        barShape(bar, value: value, target: bar.target ?? target, width: barWidth, plotHeight: height)
                            .opacity(selectedIndex == nil || selectedIndex == bar.index ? .opaque : .ultraLowOpacity)
                            .offset(x: slotCentre(bar.index, in: width) - barWidth / 2)
                            .frame(height: height, alignment: .bottom)
                    }
                }

                if showsExtremes, selectedIndex == nil {
                    ForEach(extremes, id: \.bar.index) { extreme in
                        extremeLabel(extreme.systemImage, value: extreme.value)
                            .position(
                                x: slotCentre(extreme.bar.index, in: width),
                                y: yPosition(of: extreme.value, height: height) - Constants.extremeOffset
                            )
                    }
                }
            }
        }
    }

    private func averageLine(y: CGFloat) -> some View {
        BrightDashedLineV5(color: .defaultGreen.opacity(.lowOpacity))
            .offset(y: y)
    }

    @ViewBuilder
    private func barShape(_ bar: Bar, value: Double, target: Double?, width: CGFloat, plotHeight: CGFloat) -> some View {
        if bar.segments.isEmpty {
            singleBar(value: value, target: target, width: width, plotHeight: plotHeight)
        } else {
            segmentedBar(bar.segments, value: value, width: width, plotHeight: plotHeight)
        }
    }

    // Each segment's colour peaks at its middle and blends into its neighbours, with a
    // mark where one meets the next.
    private func segmentedBar(_ segments: [Segment], value: Double, width: CGFloat, plotHeight: CGFloat) -> some View {
        let height = max(plotHeight - yPosition(of: value, height: plotHeight), width)
        let total = max(segments.reduce(0) { $0 + $1.value }, 1)
        let tops = segments.indices.map { index in
            segments[...index].reduce(0) { $0 + $1.value } / total
        }
        let stops = segments.indices.map { index in
            let bottom = index == 0 ? 0 : tops[index - 1]
            return Gradient.Stop(color: segments[index].color, location: 1 - (bottom + tops[index]) / 2)
        }

        return ZStack(alignment: .top) {
            LinearGradient(stops: Array(stops.reversed()), startPoint: .top, endPoint: .bottom)

            // Small bars are too narrow for the marks, so only the blend shows.
            ForEach(Array((size == .small ? [] : tops.dropLast()).enumerated()), id: \.offset) { _, top in
                Capsule()
                    .fill(Color.defaultHomeCards.opacity(.lowOpacity))
                    .frame(width: max(width - .spacing05x, 0), height: Constants.targetMarkHeight)
                    .offset(y: height * (1 - top) - Constants.targetMarkHeight / 2)
            }
        }
        .frame(width: width, height: height)
        .clipShape(barOutline)
    }

    private func singleBar(value: Double, target: Double?, width: CGFloat, plotHeight: CGFloat) -> some View {
        let height = max(plotHeight - yPosition(of: value, height: plotHeight), width)
        let aboveTarget = target.map { max(height - (plotHeight - yPosition(of: $0, height: plotHeight)), 0) } ?? 0
        // The orange melts into the fill across a band centred on the target, rather than
        // stopping at a hard edge.
        let blend = min(Constants.targetBlend, aboveTarget * 2)
        let solidEnd = max(aboveTarget - blend / 2, 0) / height
        let clearStart = min(aboveTarget + blend / 2, height) / height

        return ZStack(alignment: .top) {
            barFill(plotHeight: plotHeight)
                .frame(width: width, height: height, alignment: .bottom)

            if aboveTarget > 0 {
                Color.defaultOrange
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: solidEnd),
                                .init(color: .clear, location: clearStart),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // On the large week's bars, a line marks where the target fell.
                if range.isWeek, size == .large {
                    Capsule()
                        .fill(Color.defaultHomeCards.opacity(.lowOpacity))
                        .frame(width: max(width - .spacing05x, 0), height: Constants.targetMarkHeight)
                        .offset(y: aboveTarget - Constants.targetMarkHeight / 2)
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(barOutline)
    }

    // The week's wide bars are rounded rectangles; the hours' thin ones are capsules.
    private var barOutline: AnyShape {
        range.isWeek
            ? AnyShape(RoundedRectangle(cornerRadius: Constants.weekBarCornerRadius, style: .continuous))
            : AnyShape(Capsule())
    }

    @ViewBuilder
    private func barFill(plotHeight: CGFloat) -> some View {
        switch fill {
        case let .solid(color):
            color
        case .rising:
            LinearGradient(
                stops: [
                    .init(color: .defaultYellow, location: 0),
                    .init(color: .defaultGreen, location: Constants.risingGreenStop),
                    .init(color: .defaultCyan, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: plotHeight)
        }
    }

    private func extremeLabel(_ systemImage: String, value: Double) -> some View {
        VStack(spacing: .spacing025x) {
            Image(systemName: systemImage)
                .font(.standard(size: .body4, weight: .light))

            BrightText(display(value), size: .body6, color: .semiLightTextColor)
                .monospacedDigit()
        }
        .foregroundStyle(Color.semiLightTextColor)
        .fixedSize()
    }

    // The top of the scale and zero, at the column's two ends.
    private var guideLabelColumn: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            guideLabel(domainMax)

            Spacer(minLength: .spacing0x)

            guideLabel(0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func guideLabel(_ value: Double) -> some View {
        BrightText(display(value), size: .body5, color: .lightTextColor)
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
    }

    // One per slot, centred under its bar, with a taller tick at each labelled hour.
    // Placed within whatever width it's given, so it never sets the widget's width.
    private var slotDots: some View {
        GeometryReader { geometry in
            ForEach(0 ..< range.slotCount, id: \.self) { index in
                Capsule()
                    .fill(index == (selectedIndex ?? currentIndex) ? Color.textColor : Color.lightTextColor)
                    .frame(width: .spacing05x, height: isLabelledSlot(index) ? Constants.labelTickHeight : .spacing05x)
                    .position(x: slotCentre(index, in: geometry.size.width), y: geometry.size.height / 2)
            }
        }
        .frame(height: Constants.labelTickHeight)
    }

    @ViewBuilder
    private var slotLabels: some View {
        if range.isWeek {
            // A hidden letter gives the row its height; the real ones sit over their bars.
            BrightText("M", size: .body2)
                .hidden()
                .frame(maxWidth: .infinity)
                .overlay {
                    GeometryReader { geometry in
                        ForEach(0 ..< range.slotCount, id: \.self) { index in
                            BrightText(
                                Constants.weekdayInitials[index],
                                size: .body2,
                                color: index == currentIndex ? .textColor : .lightTextColor
                            )
                            .fixedSize()
                            .position(x: slotCentre(index, in: geometry.size.width), y: geometry.size.height / 2)
                        }
                    }
                }
        } else if range.isRolling {
            let labels = range.labels(for: interval)

            HStack(spacing: .spacing0x) {
                BrightText(labels.leading, size: .body5, color: .semiLightTextColor)

                Spacer(minLength: .spacing0x)

                BrightText(labels.trailing, size: .body5, color: .semiLightTextColor)
            }
            .lineLimit(1)
        } else {
            // The start at the leading edge, and the halfway hour from its bar's leading edge.
            let labels = range.labels(for: interval)

            ZStack(alignment: .leading) {
                BrightText(labels.leading, size: .body5, color: .semiLightTextColor)

                BrightText(labels.trailing, size: .body5, color: .semiLightTextColor)
                    .offset(x: slotCentre(range.slotCount / 2, in: plotWidth) - barWidth(in: plotWidth) / 2)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Selection

    // An empty chart laid over the bars, so holding them selects with the same
    // gesture as the line chart and the page still scrolls.
    @ViewBuilder
    private var selectionLayer: some View {
        if allowsSelection {
            Chart {
                ForEach(0 ..< range.slotCount, id: \.self) { index in
                    PointMark(x: .value("Slot", Double(slotCentre(index, in: plotWidth))), y: .value("Floor", 0))
                        .opacity(.zero)
                }
            }
            // Measured in points, so the finger and the bars share one scale.
            .chartXScale(domain: 0 ... Double(max(plotWidth, 1)))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartXSelection(value: selection)
        }
    }

    // Snaps to the nearest bar, so empty hours and days are passed over rather than held.
    private var selection: Binding<Double?> {
        Binding {
            selectedIndex.map { Double(slotCentre($0, in: plotWidth)) }
        } set: { position in
            let filled = bars.filter { ($0.value ?? 0) > 0 }.map(\.index)
            let index = position.flatMap { position in
                filled.min { distance($0, from: position) < distance($1, from: position) }
            }
            guard index != selectedIndex else { return }
            selectedIndex = index
            if index != nil {
                BrightHaptic.light.play()
            }
        }
    }

    // The held slot's hour or day, centred over it but kept inside the plot.
    @ViewBuilder
    private var heldLabel: some View {
        if let selectedIndex {
            let centred = slotCentre(selectedIndex, in: plotWidth) - heldLabelWidth / 2

            BrightText(slotTitle(selectedIndex), size: .body5, color: .semiLightTextColor)
                .monospacedDigit()
                .fixedSize()
                .onGeometryChange(for: CGFloat.self, of: \.size.width) { heldLabelWidth = $0 }
                .offset(x: min(max(centred, 0), max(plotWidth - heldLabelWidth, 0)))
                .transition(.opacity)
        }
    }

    private func slotTitle(_ index: Int) -> String {
        slotStart(index).formatted(range.isWeek ? .brightWeekday : .brightHour)
    }

    // Rolling slots end with the hour now running; the rest count on from the range's start.
    private func slotStart(_ index: Int) -> Date {
        if range.isWeek {
            return Calendar.current.date(byAdding: .day, value: index, to: interval.start) ?? interval.start
        }
        if range.isRolling {
            let hourStart = Calendar.current.dateInterval(of: .hour, for: .now)?.start ?? .now
            return hourStart.addingTimeInterval(-Double(range.slotCount - 1 - index) * 60 * 60)
        }
        return interval.start.addingTimeInterval(Double(index) * 60 * 60)
    }

    // MARK: - Summary

    private func summaryGrid(_ summary: Summary) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(summaryTitle(summary), size: .body3, color: .semiLightTextColor, weight: .regular)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: .spacing1x, alignment: .leading), count: 3),
                alignment: .leading,
                spacing: .spacing2x
            ) {
                ForEach(summaryBars(summary)) { bar in
                    summaryCell(for: bar, summary: summary)
                }
            }
        }
    }

    private func summaryCell(for bar: Bar, summary: Summary) -> some View {
        let isToday = bar.index == summaryBars(summary).last { $0.value != nil }?.index

        return HStack(spacing: .spacing1x) {
            BrightText(
                Constants.weekdayInitials[bar.index],
                size: .body5,
                color: isToday ? .defaultBlack : .defaultCyan,
                weight: isToday ? .regular : .light
            )
            .frame(width: Constants.dayBadgeSize, height: Constants.dayBadgeSize)
            .background(Circle().fill(isToday ? Color.defaultCyan : Color.defaultCyan.opacity(.minimalOpacity)))

            if let value = bar.value {
                switch summary {
                case .values:
                    BrightText([display(value), unit].compactMap(\.self).joined(separator: " "), size: .body3, color: .semiLightTextColor)
                        .monospacedDigit()
                case let .targets(_, target):
                    HStack(spacing: .spacing05x) {
                        Image(systemName: value >= target ? "arrow.up" : "arrow.down")
                            .font(.standard(size: .body3, weight: .light))

                        BrightText([display(abs(value - target)), unit].compactMap(\.self).joined(separator: " "), size: .body3, color: .semiLightTextColor)
                            .monospacedDigit()
                    }
                    .foregroundStyle(Color.semiLightTextColor)
                }
            } else {
                BrightText("-", size: .body3, color: .semiLightTextColor)
            }
        }
        .lineLimit(1)
    }

    private func summaryTitle(_ summary: Summary) -> String {
        if case .targets = summary { "Weekly Targets" } else { "This week" }
    }

    private func summaryBars(_ summary: Summary) -> [Bar] {
        switch summary {
        case let .values(bars), let .targets(bars, _): bars
        }
    }

    // MARK: - Values

    private var values: [Double] {
        bars.compactMap(\.value)
    }

    private var average: Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    private var headlineValue: Double {
        if let selectedIndex, let value = bars.first(where: { $0.index == selectedIndex })?.value {
            return value
        }
        return switch headline {
        case .total: values.reduce(0, +)
        case .average: average
        case .current: bars.last { $0.value != nil }?.value ?? 0
        // Shown as its parts instead, so this only feeds the accessibility label.
        case .split: average
        }
    }

    private var splitValues: [Segment] {
        if let selectedIndex, let bar = bars.first(where: { $0.index == selectedIndex }), !bar.segments.isEmpty {
            return bar.segments
        }
        let days = bars.filter { !$0.segments.isEmpty }
        guard let first = days.first else { return [] }
        return first.segments.indices.map { index in
            let average = days.reduce(0) { $0 + $1.segments[index].value } / Double(days.count)
            return Segment(label: first.segments[index].label, value: average, color: first.segments[index].color)
        }
    }

    private var unitLabel: String {
        let suffix = headline == .average && selectedIndex == nil ? "AVG" : nil
        return [unit, suffix].compactMap(\.self).joined(separator: " ")
    }

    // The latest slot with a reading, which is now.
    private var currentIndex: Int {
        bars.last { $0.value != nil }?.index ?? 0
    }

    private var showsAverage: Bool {
        range.isWeek && !values.isEmpty && !isSegmented
    }

    // Split bars are shares of a whole, so a scale or an average line says nothing about them.
    private var isSegmented: Bool {
        bars.contains { !$0.segments.isEmpty }
    }

    private var showsExtremes: Bool {
        size == .large && !range.isWeek
    }

    // The highest and lowest hours that have readings.
    private var extremes: [(bar: Bar, value: Double, systemImage: String)] {
        let readings = bars.filter { ($0.value ?? 0) > 0 }
        guard let high = readings.max(by: { ($0.value ?? 0) < ($1.value ?? 0) }),
              let low = readings.min(by: { ($0.value ?? 0) < ($1.value ?? 0) }),
              let highValue = high.value, let lowValue = low.value,
              high.index != low.index
        else { return [] }
        return [(high, highValue, "arrow.up"), (low, lowValue, "arrow.down")]
    }

    private var barFraction: CGFloat {
        !range.isWeek ? Constants.hourBarFraction : Constants.dayBarFraction
    }

    private func barWidth(in width: CGFloat) -> CGFloat {
        max(width / CGFloat(range.slotCount) * barFraction, Constants.minimumBarWidth)
    }

    // The bars run edge to edge like the line chart's plot: the first starts at the
    // leading edge and the last ends at the trailing one.
    private func slotCentre(_ index: Int, in width: CGFloat) -> CGFloat {
        let bar = barWidth(in: width)
        guard range.slotCount > 1 else { return width / 2 }
        return bar / 2 + CGFloat(index) * (width - bar) / CGFloat(range.slotCount - 1)
    }

    private func distance(_ index: Int, from position: Double) -> Double {
        abs(Double(slotCentre(index, in: plotWidth)) - position)
    }

    // Rounded up to a tidy number with headroom, so the tallest bar, the target and
    // the high label above it all sit inside.
    private var domainMax: Double {
        let targets = bars.compactMap(\.target) + [target].compactMap(\.self)
        let peak = max(values.max() ?? 0, targets.max() ?? 0) * (showsExtremes ? Constants.extremeHeadroom : Constants.headroom)
        guard peak > 0 else { return 1 }
        let magnitude = pow(10, floor(log10(peak)))
        let step = magnitude / 5
        return (peak / step).rounded(.up) * step
    }

    private func yPosition(of value: Double, height: CGFloat) -> CGFloat {
        height * (1 - min(value / domainMax, 1))
    }

    // The first hour, plus the halfway hour where it's labelled too.
    private func isLabelledSlot(_ index: Int) -> Bool {
        guard !range.isWeek else { return false }
        return index == 0 || (!range.isRolling && index == range.slotCount / 2)
    }

    private var interval: DateInterval {
        range.interval(endingAt: .now)
    }

    private func display(_ value: Double) -> String {
        appearance.format(value)
    }

    private enum Constants {
        static let axisLabelWidth: CGFloat = 34
        static let hourBarFraction: CGFloat = 0.6
        static let dayBarFraction: CGFloat = 0.48
        static let minimumBarWidth: CGFloat = 2
        static let labelTickHeight: CGFloat = 7
        static let headroom = 1.1
        static let extremeHeadroom = 1.4
        static let extremeOffset: CGFloat = .spacing3x
        static let weekBarCornerRadius: CGFloat = 6
        static let targetBlend: CGFloat = .spacing4x
        static let targetMarkHeight: CGFloat = .spacing05x
        static let risingGreenStop = 0.24
        static let dayBadgeSize: CGFloat = 20
        static let weekdayInitials = ["M", "T", "W", "T", "F", "S", "S"]
    }
}

#Preview {
    let hourly = [62, 58, 57, 56, 58, 60, 85, 140, 95, 110, 90, 80, 120, 95, 85, 88, 160, 210, 130, 90, 80, 75, 70, 65]
        .enumerated()
        .map { BrightBarChartWidgetV5.Bar(index: $0, value: $0 <= 17 ? Double($1) : nil) }
    let daily = [2_394, 5_345, 12_340, 2_388, 9_394, 0, 0]
        .enumerated()
        .map { BrightBarChartWidgetV5.Bar(index: $0, value: $0 <= 4 ? Double($1) : nil) }

    ScrollView {
        VStack(spacing: .spacing205x) {
            BrightBarChartWidgetV5(
                appearance: BrightWidgetAppearanceV5(title: "Total Energy", systemImage: "flame.fill", tint: .defaultOrange, unit: "Cal"),
                subtitle: "Latest: 5-6 PM",
                range: .today,
                bars: hourly,
                fill: .solid(.defaultCyan),
                target: 150,
                comparison: "Yesterday: 2,100",
                summary: .values(daily),
                size: .large
            )
            .frame(width: 363, height: 363)

            BrightBarChartWidgetV5(
                appearance: BrightWidgetAppearanceV5(title: "Steps", systemImage: "shoeprints.fill", tint: .defaultYellow),
                subtitle: "Latest: 8-9 AM",
                range: .week,
                bars: daily,
                fill: .solid(.defaultYellow),
                headline: .current,
                comparison: "Yesterday: 2,100",
                summary: .values(daily),
                size: .large
            )
            .frame(width: 363, height: 363)

            BrightBarChartWidgetV5(
                appearance: BrightWidgetAppearanceV5(title: "Total Energy", systemImage: "flame.fill", tint: .defaultOrange, unit: "Cal"),
                subtitle: "Latest: 5-6 PM",
                range: .rolling12h,
                bars: Array(hourly.prefix(12)),
                fill: .solid(.defaultCyan),
                target: 120,
                size: .small
            )
            .frame(width: 174, height: 174)
        }
        .padding(.spacing205x)
    }
    .background(Color.defaultBackground)
}
