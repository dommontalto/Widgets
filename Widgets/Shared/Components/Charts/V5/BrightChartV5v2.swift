//
//  BrightChartV5v2.swift
//  Widgets
//
//  Created by Dom Montalto on 10/11/2026.
//

import Charts
import SwiftUI

enum BrightChartV5v2Type: String, CaseIterable, Identifiable {
    case bar
    case line
    case dotted

    var id: Self { self }

    var title: String {
        switch self {
        case .bar: "Bar"
        case .line: "Line"
        case .dotted: "Dotted"
        }
    }

    var systemImage: String {
        switch self {
        case .bar: "chart.bar.fill"
        case .line: "chart.xyaxis.line"
        case .dotted: "chart.dots.scatter"
        }
    }
}

enum BrightChartV5v2Range: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case threeMonths
    case year

    var id: Self { self }

    var title: String {
        switch self {
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        case .threeMonths: "3 Months"
        case .year: "Year"
        }
    }

    // What the trend beside the range pill compares against, for the current period.
    var trendSuffix: String {
        switch self {
        case .day: "TODAY"
        case .week: "THIS WEEK"
        case .month: "THIS MONTH"
        case .threeMonths: "3 MONTHS"
        case .year: "THIS YEAR"
        }
    }

    var pageCount: Int {
        switch self {
        case .day: 30
        case .week: 26
        case .month: 24
        case .threeMonths: 8
        case .year: 3
        }
    }
}

struct BrightChartV5v2Point: Identifiable {
    var id: Date { date }
    let date: Date
    let value: Double
}

// A fixed calendar period: a whole day, week, month, quarter of three months ending with
// the current one, or year. Offsets page back from the period holding today.
struct BrightChartV5v2Period: Hashable {
    let range: BrightChartV5v2Range
    let start: Date
    let end: Date

    // Weeks run Monday to Sunday whatever the device's region says.
    static var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.firstWeekday = 2
        return calendar
    }

    init(range: BrightChartV5v2Range, offset: Int, now: Date = .now) {
        let calendar = Self.calendar
        let component: Calendar.Component
        let length: Int
        let anchor: Date
        switch range {
        case .day:
            component = .day
            length = 1
            anchor = calendar.startOfDay(for: now)
        case .week:
            component = .weekOfYear
            length = 1
            anchor = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            component = .month
            length = 1
            anchor = calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .threeMonths:
            component = .month
            length = 3
            let thisMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            anchor = calendar.date(byAdding: .month, value: -2, to: thisMonth) ?? thisMonth
        case .year:
            component = .year
            length = 1
            anchor = calendar.dateInterval(of: .year, for: now)?.start ?? now
        }
        self.range = range
        start = calendar.date(byAdding: component, value: offset * length, to: anchor) ?? anchor
        end = calendar.date(byAdding: component, value: length, to: start) ?? start
    }

    var bucket: Calendar.Component {
        switch range {
        case .day: .hour
        case .week, .month, .threeMonths: .day
        case .year: .month
        }
    }

    var buckets: [Date] {
        dates(every: 1, of: bucket)
    }

    var lastDay: Date {
        Self.calendar.date(byAdding: .day, value: -1, to: end) ?? start
    }

    var title: String {
        switch range {
        case .day: start.formatted(.brightCalendarDate)
        case .week, .threeMonths: Date.brightDateRange(start.brightDayKey, lastDay.brightDayKey) ?? ""
        case .month: start.formatted(.brightMonth)
        case .year: start.brightYearKey
        }
    }

    func isLabelled(_ slot: Date) -> Bool {
        let calendar = Self.calendar
        switch range {
        case .day: return calendar.component(.hour, from: slot) % 12 == 0
        case .week, .year: return true
        case .month: return (calendar.component(.day, from: slot) - 1) % 7 == 0
        case .threeMonths: return startsMonth(slot)
        }
    }

    func isNow(_ slot: Date, now: Date = .now) -> Bool {
        let next = Self.calendar.date(byAdding: bucket, value: 1, to: slot) ?? slot
        return slot <= now && now < next
    }

    func startsMonth(_ slot: Date) -> Bool {
        Self.calendar.component(.day, from: slot) == 1 && Self.calendar.component(.hour, from: slot) == 0
    }

    func slotTitle(_ slot: Date) -> String {
        switch range {
        case .day: slot.formatted(.brightHour)
        case .week, .month, .threeMonths: slot.formatted(.brightDate)
        case .year: slot.formatted(.brightMonth)
        }
    }

    func axisLabel(for slot: Date) -> String {
        switch range {
        case .day: slot.formatted(.brightHour)
        case .week: slot.formatted(.brightWeekdayInitial)
        case .month: slot.formatted(.brightDay)
        case .threeMonths: slot.formatted(.brightMonth)
        case .year: slot.formatted(.brightMonthInitial)
        }
    }

    private func dates(every step: Int, of component: Calendar.Component) -> [Date] {
        var dates: [Date] = []
        var date = start
        while date < end {
            dates.append(date)
            guard let next = Self.calendar.date(byAdding: component, value: step, to: date) else { break }
            date = next
        }
        return dates
    }
}

// A detail graph that pages back through fixed calendar periods: swipe right for the
// period before. The current period keeps its full width, so the slots still to come
// stay empty. Slots are plotted by their place in the period (0, 1, 2…), so the bars
// and the dot row beneath share one scale.
struct BrightChartV5v2: View {
    let type: BrightChartV5v2Type
    @Binding var range: BrightChartV5v2Range
    var tint: Color = .defaultGreen
    var unit = "Val"
    var domain: ClosedRange<Double> = 0...100
    // Inset inside the pager rather than around it, so a swiped page slides in from the
    // screen edge instead of being cut off at the padding.
    var horizontalPadding: CGFloat = .spacing3x
    let points: (BrightChartV5v2Period) -> [BrightChartV5v2Point]

    @State private var offset = 0
    @State private var selectedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            header(for: BrightChartV5v2Period(range: range, offset: offset))
                .padding(.horizontal, horizontalPadding)

            TabView(selection: $offset) {
                ForEach(-(range.pageCount - 1) ... 0, id: \.self) { page in
                    chart(for: BrightChartV5v2Period(range: range, offset: page))
                        .padding(.horizontal, horizontalPadding)
                        .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: Constants.chartHeight)
        }
        .onChange(of: range) {
            offset = 0
            selectedIndex = nil
        }
        .onChange(of: offset) {
            selectedIndex = nil
        }
        .onChange(of: type) {
            selectedIndex = nil
        }
    }

    // MARK: - Header

    private func header(for period: BrightChartV5v2Period) -> some View {
        let average = average(of: period)
        let slots = period.buckets
        let held = selectedIndex.flatMap { index in plotted(period, slots: slots).first { Int($0.x) == index } }
        let shown = held?.value ?? average

        return VStack(alignment: .leading, spacing: .spacing05x) {
            Text(held.map { period.slotTitle(slots[Int($0.x)]) } ?? "Average")
                .font(.standard(size: .body4, weight: .medium))
                .foregroundStyle(Color.lightTextColor)
                .contentTransition(.numericText())

            HStack {
                HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                    Text(shown.map { "\(Int($0.rounded()))" } ?? "--")
                        .font(.standard(size: .huge2, weight: .semibold))
                        .foregroundStyle(Color.textColor)
                        .contentTransition(.numericText())

                    Text(unit)
                        .font(.standard(size: .body2, weight: .medium))
                        .foregroundStyle(Color.lightTextColor)
                }

                Spacer()

                if held == nil {
                    trend(average: average)
                }

                rangeMenu
            }

            Text(period.title)
                .font(.standard(size: .body3, weight: .regular))
                .foregroundStyle(Color.semiLightTextColor)
        }
        .animation(.brightEaseInOut, value: offset)
        .animation(.brightSnappy, value: selectedIndex)
    }

    // The change from the period before, as a percentage of it.
    @ViewBuilder
    private func trend(average: Double?) -> some View {
        let previous = self.average(of: BrightChartV5v2Period(range: range, offset: offset - 1))
        if let average, let previous, previous > 0 {
            let change = (average - previous) / previous * 100
            HStack(spacing: .spacing05x) {
                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                Text("\(Int(abs(change).rounded()))%")
                    .contentTransition(.numericText())
                if offset == 0 {
                    Text(range.trendSuffix)
                }
            }
            .font(.standard(size: .body3, weight: .medium))
            .foregroundStyle(Color.semiLightTextColor)
            .lineLimit(1)
        }
    }

    private func average(of period: BrightChartV5v2Period) -> Double? {
        let values = points(period).map(\.value)
        return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }

    private var rangeMenu: some View {
        Menu {
            Picker("Range", selection: $range) {
                ForEach(BrightChartV5v2Range.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
        } label: {
            HStack(spacing: .spacing05x) {
                Text(range.title)
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
            }
            .font(.standard(size: .body3, weight: .medium))
            .foregroundStyle(Color.textColor)
            .padding(.horizontal, .spacing2x)
            .padding(.vertical, .spacing1x)
            .modifier(BrightGlassEffectV5())
        }
        .sensoryFeedback(.selection, trigger: range)
    }

    // MARK: - Chart

    private func chart(for period: BrightChartV5v2Period) -> some View {
        let slots = period.buckets
        let xDomain = xDomain(slotCount: slots.count, period: period)

        return VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                plot(plotted(period, slots: slots), slots: slots, period: period, xDomain: xDomain)

                guideColumn
            }

            axis(slots: slots, period: period, xDomain: xDomain)
                .padding(.trailing, Constants.guideWidth + .spacing1x)
        }
        .padding(.top, .spacing1x)
    }

    private func plot(_ plotted: [Plotted], slots: [Date], period: BrightChartV5v2Period, xDomain: ClosedRange<Double>) -> some View {
        Chart {
            switch type {
            case .bar: bars(plotted, period: period)
            case .line: line(plotted)
            case .dotted: dots(plotted)
            }

            if type != .bar, let marked = marked(in: plotted, period: period) {
                BrightSelectorV5(x: marked.x, value: marked.value)
            }
        }
        .chartXSelection(value: selection(in: plotted))
        .chartXScale(domain: xDomain)
        .chartYScale(domain: domain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }

    @ChartContentBuilder
    private func bars(_ plotted: [Plotted], period: BrightChartV5v2Period) -> some ChartContent {
        let half: Double = barFraction(period) / 2
        ForEach(plotted) { point in
            bar(point, half: half)
        }
    }

    private func bar(_ point: Plotted, half: Double) -> some ChartContent {
        RectangleMark(
            xStart: .value("Start", point.x - half),
            xEnd: .value("End", point.x + half),
            yStart: .value("Floor", domain.lowerBound),
            yEnd: .value("Value", point.value)
        )
        .foregroundStyle(tint)
        .clipShape(Capsule())
        .opacity(selectedIndex == nil || selectedIndex == Int(point.x) ? .opaque : .ultraLowOpacity)
    }

    @ChartContentBuilder
    private func line(_ plotted: [Plotted]) -> some ChartContent {
        let fill = LinearGradient(colors: [tint.opacity(.semiLowOpacity), .clear], startPoint: .top, endPoint: .bottom)
        ForEach(plotted) { point in
            AreaMark(x: .value("Slot", point.x), yStart: .value("Floor", domain.lowerBound), yEnd: .value("Value", point.value))
                .foregroundStyle(fill)
                .interpolationMethod(.catmullRom)
        }
        ForEach(plotted) { point in
            LineMark(x: .value("Slot", point.x), y: .value("Value", point.value))
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: Constants.lineWidth))
                .interpolationMethod(.catmullRom)
        }
    }

    @ChartContentBuilder
    private func dots(_ plotted: [Plotted]) -> some ChartContent {
        let fill = LinearGradient(colors: [tint.opacity(.semiLowOpacity), .clear], startPoint: .top, endPoint: .bottom)
        ForEach(plotted) { point in
            AreaMark(x: .value("Slot", point.x), yStart: .value("Floor", domain.lowerBound), yEnd: .value("Value", point.value))
                .foregroundStyle(fill)
        }
        ForEach(plotted) { point in
            LineMark(x: .value("Slot", point.x), y: .value("Value", point.value))
                .foregroundStyle(tint.opacity(.semiLowOpacity))
                .lineStyle(StrokeStyle(lineWidth: Constants.hairline))
        }
        ForEach(plotted) { point in
            PointMark(x: .value("Slot", point.x), y: .value("Value", point.value))
                .symbol {
                    Circle()
                        .fill(tint)
                        .frame(width: Constants.dotDiameter, height: Constants.dotDiameter)
                }
        }
    }

    // The top of the scale and zero, at the plot's two ends.
    private var guideColumn: some View {
        VStack(alignment: .leading) {
            guideLabel(domain.upperBound)
            Spacer(minLength: .spacing0x)
            guideLabel(domain.lowerBound)
        }
        .frame(width: Constants.guideWidth, alignment: .leading)
    }

    private func guideLabel(_ value: Double) -> some View {
        Text("\(Int(value))")
            .font(.standard(size: .body5, weight: .regular))
            .foregroundStyle(Color.lightTextColor)
            .monospacedDigit()
    }

    // A dot under every slot, ticked taller where it carries a label, laid out on the
    // plot's own scale.
    private func axis(slots: [Date], period: BrightChartV5v2Period, xDomain: ClosedRange<Double>) -> some View {
        let isLettered = period.range == .week || period.range == .year
        let isHours = period.range == .day

        return VStack(alignment: .leading, spacing: .spacing05x) {
            GeometryReader { geometry in
                ForEach(slots.indices, id: \.self) { index in
                    tick(slots[index], period: period, isSelected: index == selectedIndex)
                        .position(x: x(of: index, in: xDomain, width: geometry.size.width), y: Constants.labelTickHeight / 2)
                }
            }
            .frame(height: Constants.labelTickHeight)

            Text("M")
                .font(.standard(size: isLettered ? .body2 : .body5, weight: .regular))
                .hidden()
                .frame(maxWidth: .infinity)
                .overlay {
                    GeometryReader { geometry in
                        ForEach(slots.indices.filter { period.isLabelled(slots[$0]) }, id: \.self) { index in
                            label(slots[index], period: period, isLettered: isLettered)
                                // The hours read rightwards from their tick; the rest centre on it.
                                .frame(width: isHours ? .spacing05x : nil, alignment: .leading)
                                .position(x: x(of: index, in: xDomain, width: geometry.size.width), y: geometry.size.height / 2)
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private func tick(_ slot: Date, period: BrightChartV5v2Period, isSelected: Bool) -> some View {
        let isLabelled = period.isLabelled(slot) || isSelected
        let isNow = period.isNow(slot) && !isSelected

        if period.range == .year {
            Circle()
                .fill(isNow || isSelected ? Color.textColor : Color.lightTextColor)
                .frame(width: .spacing1x, height: .spacing1x)
        } else if period.range == .day {
            Capsule()
                .fill(isNow ? Color.defaultCyan : isLabelled ? Color.textColor : Color.lightTextColor)
                .frame(width: .spacing05x, height: isLabelled || isNow ? Constants.labelTickHeight : .spacing05x)
        } else {
            Capsule()
                .fill(isNow || isSelected ? Color.textColor : Color.lightTextColor)
                .frame(width: .spacing05x, height: isLabelled ? Constants.labelTickHeight : .spacing05x)
        }
    }

    // MARK: - Holding

    // The held point, or else the latest one while its period is still running.
    private func marked(in plotted: [Plotted], period: BrightChartV5v2Period) -> Plotted? {
        if let selectedIndex {
            return plotted.first { Int($0.x) == selectedIndex }
        }
        return period.end > .now ? plotted.last : nil
    }

    // Snaps to the nearest slot with a reading, so empty ones are passed over.
    private func selection(in plotted: [Plotted]) -> Binding<Double?> {
        Binding {
            selectedIndex.map(Double.init)
        } set: { position in
            let index = position.flatMap { position in
                plotted.min { abs($0.x - position) < abs($1.x - position) }.map { Int($0.x) }
            }
            guard index != selectedIndex else { return }
            selectedIndex = index
            if index != nil {
                BrightHaptic.light.play()
            }
        }
    }

    private func label(_ slot: Date, period: BrightChartV5v2Period, isLettered: Bool) -> some View {
        Text(period.axisLabel(for: slot))
            .font(.standard(size: isLettered ? .body2 : .body5, weight: .regular))
            .foregroundStyle(isLettered ? (period.isNow(slot) ? Color.textColor : Color.lightTextColor) : Color.semiLightTextColor)
            .lineLimit(1)
            .fixedSize()
    }

    // MARK: - Layout

    private struct Plotted: Identifiable {
        let x: Double
        let value: Double
        var id: Double { x }
    }

    private func plotted(_ period: BrightChartV5v2Period, slots: [Date]) -> [Plotted] {
        let indices = Dictionary(uniqueKeysWithValues: slots.enumerated().map { ($1, $0) })
        return points(period).compactMap { point in
            indices[point.date].map { Plotted(x: Double($0), value: point.value) }
        }
    }

    private func barFraction(_ period: BrightChartV5v2Period) -> Double {
        period.range == .day ? Constants.hourBarFraction : Constants.dayBarFraction
    }

    // Runs from the first bar's leading edge to the last one's trailing edge (or the first
    // point to the last), so the plot lines up with the header above it.
    private func xDomain(slotCount: Int, period: BrightChartV5v2Period) -> ClosedRange<Double> {
        let inset = type == .bar ? barFraction(period) / 2 : 0
        return -inset ... Double(max(slotCount - 1, 1)) + inset
    }

    private func x(of index: Int, in xDomain: ClosedRange<Double>, width: CGFloat) -> CGFloat {
        (Double(index) - xDomain.lowerBound) / (xDomain.upperBound - xDomain.lowerBound) * width
    }

    private enum Constants {
        static let chartHeight: CGFloat = 300
        static let guideWidth: CGFloat = 26
        static let hourBarFraction: CGFloat = 0.6
        static let dayBarFraction: CGFloat = 0.48
        static let lineWidth: CGFloat = 1
        static let hairline: CGFloat = 0.5
        static let dotDiameter: CGFloat = 7
        static let labelTickHeight: CGFloat = 7
    }
}

#Preview {
    @Previewable @State var range = BrightChartV5v2Range.week

    BrightChartV5v2(type: .bar, range: $range) { period in
        period.buckets.filter { $0 <= .now }.map { BrightChartV5v2Point(date: $0, value: .random(in: 30...90)) }
    }
    .padding(.vertical, .spacing3x)
    .background(Color.defaultBackground)
}
