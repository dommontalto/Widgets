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

        var id: Int { index }
    }

    enum Range: String, CaseIterable, Codable, Identifiable {
        case rolling12h
        case today
        case week

        var id: Self { self }

        var title: String {
            switch self {
            case .rolling12h: "Rolling 12 hours"
            case .today: "Today"
            case .week: "This week"
            }
        }

        var slotCount: Int {
            switch self {
            case .rolling12h: 12
            case .today: 24
            case .week: 7
            }
        }

        var isHourly: Bool {
            self != .week
        }
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
    }

    // The large size's grid of this week's days: each day's value, or how far it
    // landed from the target.
    enum Summary {
        case values([Bar])
        case targets([Bar], target: Double)
    }

    let title: String
    let systemImage: String
    let tint: Color
    var unit: String?
    let subtitle: String
    let range: Range
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
            HStack(alignment: .top, spacing: .spacing05x) {
                header

                if let comparison {
                    Spacer(minLength: .spacing0x)

                    comparisonText(comparison)
                }
            }

            plotArea(showsGuides: false)
                .frame(maxHeight: .infinity)

            reading(valueSize: .huge205)
                // Digits never use the room every line keeps below its baseline, so
                // it's pulled into the padding rather than lifting the number.
                .padding(.bottom, Font.standardUIFont(size: .huge205, weight: .light)?.descender ?? 0)
        }
    }

    private var expandedLayout: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .top, spacing: .spacing1x) {
                header

                Spacer(minLength: .spacing0x)

                VStack(alignment: .trailing, spacing: .spacing05x) {
                    reading(valueSize: size == .large ? .standout1 : .standout3)

                    if let comparison {
                        comparisonText(comparison)
                    }
                }
            }

            plotArea(showsGuides: true)
                .frame(maxHeight: .infinity)

            if size == .large, let summary {
                Rectangle()
                    .fill(Color.textColor.opacity(.ultraLowOpacity))
                    .frame(height: Constants.hairline)
                    .padding(.horizontal, -.spacing205x)

                summaryGrid(summary)
            }
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

    private func reading(valueSize: FontSizes) -> some View {
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

    // MARK: - Plot

    private func plotArea(showsGuides: Bool) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                if showsGuides {
                    guideLabelColumn
                        .frame(width: Constants.axisLabelWidth)
                }

                barArea(showsGuides: showsGuides)
                    .overlay { selectionLayer }
                    .onGeometryChange(for: CGFloat.self, of: \.size.width) { plotWidth = $0 }
            }

            VStack(alignment: .leading, spacing: .spacing05x) {
                slotDots

                slotLabels
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
            let slot = geometry.size.width / CGFloat(range.slotCount)
            let barWidth = max(slot * barFraction, Constants.minimumBarWidth)

            ZStack(alignment: .topLeading) {
                if showsGuides, showsAverage {
                    averageLine(y: yPosition(of: average, height: height))
                }

                ForEach(bars) { bar in
                    if let value = bar.value, value > 0 {
                        barShape(value: value, width: barWidth, plotHeight: height)
                            .opacity(selectedIndex == nil || selectedIndex == bar.index ? .opaque : .semiLowOpacity)
                            .offset(x: slot * (CGFloat(bar.index) + 0.5) - barWidth / 2)
                            .frame(height: height, alignment: .bottom)
                    }
                }

                if showsExtremes, selectedIndex == nil {
                    ForEach(extremes, id: \.bar.index) { extreme in
                        extremeLabel(extreme.systemImage, value: extreme.value)
                            .position(
                                x: slot * (CGFloat(extreme.bar.index) + 0.5),
                                y: yPosition(of: extreme.value, height: height) - Constants.extremeOffset
                            )
                    }
                }
            }
        }
    }

    private func averageLine(y: CGFloat) -> some View {
        BrightDashedLineV5(color: .defaultGreen.opacity(.lowOpacity))
            .overlay(alignment: .trailing) {
                BrightText("AVG", size: .body6, color: .lightTextColor)
                    .fixedSize()
                    .offset(y: -Constants.averageLabelLift)
            }
            .offset(y: y)
    }

    private func barShape(value: Double, width: CGFloat, plotHeight: CGFloat) -> some View {
        let height = max(plotHeight - yPosition(of: value, height: plotHeight), width)
        let aboveTarget = target.map { max(height - (plotHeight - yPosition(of: $0, height: plotHeight)), 0) } ?? 0

        return ZStack(alignment: .top) {
            barFill(plotHeight: plotHeight)
                .frame(width: width, height: height, alignment: .bottom)

            Color.defaultOrange
                .frame(width: width, height: aboveTarget)
        }
        .frame(width: width, height: height)
        .clipShape(Capsule())
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
        VStack(spacing: .spacing0x) {
            Image(systemName: systemImage)
                .font(.standard(size: .body3, weight: .light))

            BrightText(display(value), size: .body5, color: .semiLightTextColor)
                .monospacedDigit()
        }
        .foregroundStyle(Color.semiLightTextColor)
        .fixedSize()
    }

    // The target or the top of the scale, the average where its line is drawn, and zero.
    private var guideLabelColumn: some View {
        GeometryReader { geometry in
            ForEach(guideValues, id: \.self) { value in
                BrightText(display(value), size: .body5, color: .lightTextColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: geometry.size.width, alignment: .trailing)
                    .position(x: geometry.size.width / 2, y: yPosition(of: value, height: geometry.size.height))
            }
        }
    }

    // One per slot, centred under its bar, with a taller tick at each labelled hour.
    private var slotDots: some View {
        HStack(spacing: .spacing0x) {
            ForEach(0 ..< range.slotCount, id: \.self) { index in
                Capsule()
                    .fill(index == (selectedIndex ?? currentIndex) ? Color.textColor : Color.lightTextColor)
                    .frame(width: .spacing05x, height: isLabelledSlot(index) ? Constants.labelTickHeight : .spacing05x)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: Constants.labelTickHeight)
    }

    @ViewBuilder
    private var slotLabels: some View {
        // Hour labels start at their tick, half a slot in from the slot's edge.
        let inset = max(plotWidth / CGFloat(range.slotCount) / 2 - .spacing05x / 2, 0)

        switch range {
        case .rolling12h:
            HStack(spacing: .spacing0x) {
                BrightText("12h ago", size: .body5, color: .semiLightTextColor)

                Spacer(minLength: .spacing0x)

                BrightText("Now", size: .body5, color: .semiLightTextColor)
            }
            .lineLimit(1)
            .padding(.horizontal, inset)
        case .today:
            HStack(spacing: .spacing0x) {
                ForEach([0, 12], id: \.self) { hour in
                    BrightText(hourLabel(hour), size: .body5, color: .semiLightTextColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.leading, inset)
        case .week:
            HStack(spacing: .spacing0x) {
                ForEach(0 ..< range.slotCount, id: \.self) { index in
                    BrightText(
                        Constants.weekdayInitials[index],
                        size: .body2,
                        color: index == currentIndex ? .textColor : .lightTextColor
                    )
                    .frame(maxWidth: .infinity)
                }
            }
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
                    PointMark(x: .value("Slot", Double(index) + 0.5), y: .value("Floor", 0))
                        .opacity(.zero)
                }
            }
            .chartXScale(domain: 0 ... Double(range.slotCount))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartXSelection(value: selection)
        }
    }

    // Snaps to the slot under the finger, never past the latest reading.
    private var selection: Binding<Double?> {
        Binding {
            selectedIndex.map { Double($0) + 0.5 }
        } set: { position in
            let index = position.map { min(max(Int($0), 0), currentIndex) }
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
            let slot = plotWidth / CGFloat(range.slotCount)
            let centred = slot * (CGFloat(selectedIndex) + 0.5) - Constants.heldLabelWidth / 2

            BrightText(slotTitle(selectedIndex), size: .body5, color: .semiLightTextColor)
                .monospacedDigit()
                .fixedSize()
                .frame(width: Constants.heldLabelWidth)
                .offset(x: min(max(centred, 0), max(plotWidth - Constants.heldLabelWidth, 0)))
                .transition(.opacity)
        }
    }

    private func slotTitle(_ index: Int) -> String {
        let calendar = Calendar.current
        switch range {
        case .rolling12h:
            let hourStart = calendar.dateInterval(of: .hour, for: .now)?.start ?? .now
            return hourStart.addingTimeInterval(-Double(range.slotCount - 1 - index) * 60 * 60).formatted(.brightHour)
        case .today:
            return hourLabel(index)
        case .week:
            var monday = calendar
            monday.firstWeekday = 2
            let weekStart = monday.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
            return (calendar.date(byAdding: .day, value: index, to: weekStart) ?? weekStart).formatted(.brightWeekday)
        }
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

        return HStack(spacing: .spacing05x) {
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
                    HStack(spacing: .spacing0x) {
                        Image(systemName: value >= target ? "arrow.up" : "arrow.down")
                            .font(.standard(size: .body3, weight: .light))

                        BrightText([display(abs(value - target)), unit].compactMap(\.self).joined(separator: " "), size: .body3, color: .semiLightTextColor)
                            .monospacedDigit()
                    }
                    .foregroundStyle(Color.semiLightTextColor)
                }
            } else {
                BrightText("--", size: .body3, color: .semiLightTextColor)
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
        range == .week && !values.isEmpty
    }

    private var showsExtremes: Bool {
        size == .large && range.isHourly
    }

    private var guideValues: [Double] {
        var guides = [target ?? domainMax]
        if showsAverage {
            guides.append(average)
        }
        guides.append(0)
        return guides
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
        range.isHourly ? Constants.hourBarFraction : Constants.dayBarFraction
    }

    // Rounded up to a tidy number with headroom, so the tallest bar, the target and
    // the high label above it all sit inside.
    private var domainMax: Double {
        let peak = max(values.max() ?? 0, target ?? 0) * (showsExtremes ? Constants.extremeHeadroom : Constants.headroom)
        guard peak > 0 else { return 1 }
        let magnitude = pow(10, floor(log10(peak)))
        let step = magnitude / 2
        return (peak / step).rounded(.up) * step
    }

    private func yPosition(of value: Double, height: CGFloat) -> CGFloat {
        height * (1 - min(value / domainMax, 1))
    }

    private func isLabelledSlot(_ index: Int) -> Bool {
        switch range {
        case .rolling12h: index == 0
        case .today: index == 0 || index == 12
        case .week: false
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        Calendar.current.startOfDay(for: .now).addingTimeInterval(Double(hour) * 60 * 60).formatted(.brightHour)
    }

    private func display(_ value: Double) -> String {
        Int(value.rounded()).formatted()
    }

    private enum Constants {
        static let axisLabelWidth: CGFloat = 34
        static let hourBarFraction: CGFloat = 0.6
        static let dayBarFraction: CGFloat = 0.48
        static let minimumBarWidth: CGFloat = 2
        static let labelTickHeight: CGFloat = 7
        static let hairline: CGFloat = 0.5
        static let headroom = 1.1
        static let extremeHeadroom = 1.4
        static let extremeOffset: CGFloat = .spacing3x
        static let averageLabelLift: CGFloat = .spacing1x
        static let risingGreenStop = 0.24
        static let dayBadgeSize: CGFloat = 20
        static let heldLabelWidth: CGFloat = 70
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
                title: "Total Energy",
                systemImage: "flame.fill",
                tint: .defaultOrange,
                unit: "Cal",
                subtitle: "Latest: 5-6 PM",
                range: .today,
                bars: hourly,
                fill: .solid(.defaultCyan),
                target: 150,
                comparison: "2,100 Yest.",
                summary: .values(daily),
                size: .large
            )
            .frame(width: 363, height: 363)

            BrightBarChartWidgetV5(
                title: "Steps",
                systemImage: "shoeprints.fill",
                tint: .defaultYellow,
                subtitle: "Latest: 8-9 AM",
                range: .week,
                bars: daily,
                fill: .solid(.defaultYellow),
                headline: .current,
                comparison: "2,100 Yest.",
                summary: .values(daily),
                size: .large
            )
            .frame(width: 363, height: 363)

            BrightBarChartWidgetV5(
                title: "Total Energy",
                systemImage: "flame.fill",
                tint: .defaultOrange,
                unit: "Cal",
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
