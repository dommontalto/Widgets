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

    var axisDates: [Date] {
        switch range {
        case .day: dates(every: 6, of: .hour)
        case .week: dates(every: 1, of: .day)
        case .month: dates(every: 7, of: .day)
        case .threeMonths: dates(every: 1, of: .month)
        case .year: dates(every: 3, of: .month)
        }
    }

    func middle(of slot: Date) -> Date {
        let next = Self.calendar.date(byAdding: bucket, value: 1, to: slot) ?? slot
        return slot.addingTimeInterval(next.timeIntervalSince(slot) / 2)
    }

    func slotContainsNow(_ slot: Date, now: Date = .now) -> Bool {
        let next = Self.calendar.date(byAdding: bucket, value: 1, to: slot) ?? slot
        return slot <= now && now < next
    }

    func startsMonth(_ date: Date) -> Bool {
        Self.calendar.dateInterval(of: .month, for: date)?.start == date
    }

    func axisLabel(for date: Date) -> String {
        switch range {
        case .day: date.formatted(.brightHour)
        case .week: date.formatted(.brightWeekdayInitial)
        case .month: date.formatted(.brightDay)
        case .threeMonths, .year: date.formatted(.brightMonth)
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
// period before. The current period keeps its full width, so the days still to come
// stay empty.
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
        }
    }

    private func header(for period: BrightChartV5v2Period) -> some View {
        let values = points(period).map(\.value)
        let average = values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)

        return VStack(alignment: .leading, spacing: .spacing05x) {
            Text("Average")
                .font(.standard(size: .body4, weight: .medium))
                .foregroundStyle(Color.lightTextColor)

            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                    Text(average.map { "\(Int($0.rounded()))" } ?? "--")
                        .font(.standard(size: .huge2, weight: .semibold))
                        .foregroundStyle(Color.textColor)
                        .contentTransition(.numericText())

                    Text(unit)
                        .font(.standard(size: .body2, weight: .medium))
                        .foregroundStyle(Color.lightTextColor)
                }

                Spacer()

                rangeMenu
            }

            Text(period.title)
                .font(.standard(size: .body3, weight: .regular))
                .foregroundStyle(Color.semiLightTextColor)
        }
        .animation(.brightEaseInOut, value: offset)
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

    private func chart(for period: BrightChartV5v2Period) -> some View {
        let values = points(period)
        let latest = period.end > .now ? values.last : nil
        let slotMiddles = Dictionary(uniqueKeysWithValues: period.buckets.map { (period.middle(of: $0), $0) })

        return Chart {
            switch type {
            case .bar:
                ForEach(values) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: period.bucket),
                        y: .value(unit, point.value),
                        width: .ratio(Constants.barWidthRatio)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [tint, tint.opacity(.lowOpacity)], startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(Capsule())
                }

            case .line:
                ForEach(values) { point in
                    AreaMark(
                        x: .value("Date", period.middle(of: point.date)),
                        yStart: .value("Floor", domain.lowerBound),
                        yEnd: .value(unit, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [tint.opacity(.semiLowOpacity), .clear], startPoint: .top, endPoint: .bottom)
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(x: .value("Date", period.middle(of: point.date)), y: .value(unit, point.value))
                        .foregroundStyle(tint)
                        .lineStyle(StrokeStyle(lineWidth: Constants.lineWidth))
                        .interpolationMethod(.catmullRom)
                }

            case .dotted:
                ForEach(values) { point in
                    LineMark(x: .value("Date", period.middle(of: point.date)), y: .value(unit, point.value))
                        .foregroundStyle(tint.opacity(.semiLowOpacity))
                        .lineStyle(StrokeStyle(lineWidth: Constants.hairline))

                    PointMark(x: .value("Date", period.middle(of: point.date)), y: .value(unit, point.value))
                        .foregroundStyle(tint)
                        .symbolSize(Constants.dotArea)
                }
            }

            if type != .bar, let latest {
                BrightSelectorV5(date: period.middle(of: latest.date), value: latest.value)
            }
        }
        .chartXScale(domain: period.start ... period.end)
        .chartYScale(domain: domain)
        .chartXAxis {
            AxisMarks(values: period.range == .month ? [] : period.buckets.filter(period.startsMonth)) { _ in
                AxisGridLine(stroke: .brightDashedLineV5)
                    .foregroundStyle(Color.lightTextColor)
            }

            // Placed at each slot's middle rather than `centered`, which can't centre the
            // last slot as it has no next value to measure to.
            AxisMarks(values: Array(slotMiddles.keys)) { value in
                AxisValueLabel(anchor: .top, collisionResolution: .disabled) {
                    if let middle = value.as(Date.self), let slotStart = slotMiddles[middle] {
                        slot(slotStart, in: period)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: [domain.lowerBound, domain.upperBound]) { value in
                AxisValueLabel {
                    if let number = value.as(Double.self) {
                        Text("\(Int(number))")
                            .font(.standard(size: .body5, weight: .regular))
                            .foregroundStyle(Color.lightTextColor)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(.top, .spacing1x)
        .padding(.bottom, .spacing1x)
    }

    // A dot under every bar, ticked taller where it carries a label, and bright for the
    // slot holding now.
    private func slot(_ date: Date, in period: BrightChartV5v2Period) -> some View {
        let isLabelled = period.axisDates.contains(date)
        let isCurrent = period.slotContainsNow(date)

        return VStack(spacing: .spacing05x) {
            Capsule()
                .fill(isCurrent ? Color.textColor : Color.lightTextColor)
                .frame(width: .spacing05x, height: isLabelled ? Constants.labelTickHeight : .spacing05x)
                .frame(height: Constants.labelTickHeight)

            if isLabelled {
                Text(period.axisLabel(for: date))
                    .font(.standard(size: period.range == .week ? .body2 : .body5, weight: .regular))
                    .foregroundStyle(
                        period.range == .week
                            ? (isCurrent ? Color.textColor : Color.lightTextColor)
                            : Color.semiLightTextColor
                    )
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }

    private enum Constants {
        static let chartHeight: CGFloat = 280
        static let barWidthRatio: CGFloat = 0.6
        static let lineWidth: CGFloat = 1.5
        static let hairline: CGFloat = 0.5
        static let dotArea: CGFloat = 28
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
