//
//  BrightDateFormatting.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import Foundation

extension String {
    func isoStringToDate() -> Date {
        ISO8601DateFormatter().date(from: self) ?? Date()
    }
}

extension Locale {
    static let bright = Locale(identifier: "en_NZ")
}

extension FormatStyle where Self == Date.FormatStyle {
    static var brightTime: Self { Date.FormatStyle(locale: .bright).hour(.defaultDigits(amPM: .abbreviated)).minute() }
    static var brightDay: Self { Date.FormatStyle(locale: .bright).day(.defaultDigits) }
    static var brightWeekdayInitial: Self { Date.FormatStyle(locale: .bright).weekday(.narrow) }
}

extension FormatStyle where Self == Date.VerbatimFormatStyle {
    static var brightTime24: Self {
        Date.VerbatimFormatStyle(
            format: "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
            timeZone: .current,
            calendar: Calendar(identifier: .gregorian)
        )
    }
}

struct BrightDateStyle: FormatStyle {
    func format(_ value: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        if calendar.isDateInToday(value) { return "Today" }
        if calendar.isDateInYesterday(value) { return "Yesterday" }
        if calendar.isDateInTomorrow(value) { return "Tomorrow" }

        let base = Date.FormatStyle(locale: .bright).day().month(.abbreviated)
        if calendar.isDate(value, equalTo: .now, toGranularity: .year) {
            return value.formatted(base)
        }
        return value.formatted(base.year())
    }
}

struct BrightTimestampStyle: FormatStyle {
    func format(_ value: Date) -> String {
        guard Calendar.autoupdatingCurrent.isDate(value, equalTo: .now, toGranularity: .year) else {
            return value.formatted(.brightDate)
        }
        return "\(value.formatted(.brightDate)), \(value.formatted(.brightTime))"
    }
}

extension FormatStyle where Self == BrightDateStyle {
    static var brightDate: Self { .init() }
}

extension FormatStyle where Self == BrightTimestampStyle {
    static var brightTimestamp: Self { .init() }
}

extension Date {
    var isoString: String {
        ISO8601DateFormatter().string(from: self)
    }

    static func brightTimeRange(from: Date, to: Date) -> String {
        "\(from.formatted(.brightTime)) – \(max(from, to).formatted(.brightTime))"
    }

    func stringFromDate(strFormatter: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = strFormatter
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: self)
    }
}

extension Double {
    var toString: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
