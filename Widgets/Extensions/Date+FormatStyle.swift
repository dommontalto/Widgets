//
//  Date+FormatStyle.swift
//  Widgets
//
//  Created by Dom Montalto on 1/8/2026.
//

import Foundation

extension Locale {
    static let bright = Locale(identifier: "en_NZ")
}

extension FormatStyle where Self == Date.FormatStyle {
    static var brightTime: Self { bright.hour(.defaultDigits(amPM: .abbreviated)).minute() }
    static var brightHour: Self { bright.hour(.defaultDigits(amPM: .abbreviated)) }
    static var brightDay: Self { bright.day(.defaultDigits) }
    static var brightWeekday: Self { bright.weekday(.wide) }
    static var brightWeekdayShort: Self { bright.weekday(.abbreviated) }
    static var brightWeekdayInitial: Self { bright.weekday(.narrow) }
    static var brightSlashDate: Self { bright.day(.twoDigits).month(.twoDigits).year() }

    private static var bright: Self { Date.FormatStyle(locale: .bright) }
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

extension Date {
    static func brightDateRange(_ start: String?, _ end: String?) -> String? {
        guard let start, let end,
              let from = Date(brightDayKey: start) ?? Date(brightISOZoned: start),
              let to = Date(brightDayKey: end) ?? Date(brightISOZoned: end)
        else { return nil }
        return "\(from.formatted(.brightDate)) – \(max(from, to).formatted(.brightDate))"
    }

    static func brightTimeRange(_ start: String?, _ end: String?) -> String? {
        guard let start, let end,
              let from = Date(brightISOZoned: start),
              let to = Date(brightISOZoned: end)
        else { return nil }
        return brightTimeRange(from: from, to: to)
    }

    static func brightTimeRange(from: Date, to: Date) -> String {
        "\(from.formatted(.brightTime)) – \(max(from, to).formatted(.brightTime))"
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

struct BrightCalendarDateStyle: FormatStyle {
    func format(_ value: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        let day = value.formatted(Date.FormatStyle(locale: .bright).day().month(.abbreviated))
        if calendar.isDateInToday(value) { return "Today, \(day)" }
        if calendar.isDateInYesterday(value) { return "Yesterday, \(day)" }
        if calendar.isDateInTomorrow(value) { return "Tomorrow, \(day)" }
        return value.formatted(.brightDate)
    }
}

struct BrightMonthStyle: FormatStyle {
    func format(_ value: Date) -> String {
        let base = Date.FormatStyle(locale: .bright).month(.abbreviated)
        if Calendar.autoupdatingCurrent.isDate(value, equalTo: .now, toGranularity: .year) {
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

extension FormatStyle where Self == BrightCalendarDateStyle {
    static var brightCalendarDate: Self { .init() }
}

extension FormatStyle where Self == BrightMonthStyle {
    static var brightMonth: Self { .init() }
}

extension FormatStyle where Self == BrightTimestampStyle {
    static var brightTimestamp: Self { .init() }
}

extension Date {
    var brightDayKey: String { formatted(Date.dayKeyStyle) }
    var brightISOZoned: String { formatted(Date.isoZonedStyle) }
    var brightISOZonedPrecise: String { formatted(Date.isoZonedPreciseStyle) }
    var brightYearKey: String { String(Calendar.autoupdatingCurrent.component(.year, from: self)) }
    var brightMonthNumber: String { String(format: "%02d", Calendar.autoupdatingCurrent.component(.month, from: self)) }
    var brightLogStamp: String { formatted(Date.logStampStyle) }

    init?(brightDayKey: String) {
        guard let date = try? Date.dayKeyStyle.parse(brightDayKey) else { return nil }
        self = date
    }

    init?(brightISOZoned: String) {
        for style in Date.isoZonedParseStyles {
            if let date = try? style.parse(brightISOZoned) {
                self = date
                return
            }
        }
        return nil
    }

    private static var dayKeyStyle: Date.ISO8601FormatStyle {
        Date.ISO8601FormatStyle(timeZone: .current).year().month().day().dateSeparator(.dash)
    }

    private static var isoStyle: Date.ISO8601FormatStyle {
        Date.ISO8601FormatStyle(timeZone: .current)
            .year().month().day()
            .dateSeparator(.dash)
            .dateTimeSeparator(.standard)
            .time(includingFractionalSeconds: false)
    }

    private static var isoZonedStyle: Date.ISO8601FormatStyle {
        isoStyle.timeZone(separator: .colon)
    }

    private static var isoZonedPreciseStyle: Date.ISO8601FormatStyle {
        isoFractionalStyle.timeZone(separator: .colon)
    }

    private static var isoZonedParseStyles: [Date.ISO8601FormatStyle] {
        [
            isoStyle.timeZone(separator: .colon),
            isoStyle.timeZone(separator: .omitted),
            isoFractionalStyle.timeZone(separator: .colon),
            isoFractionalStyle.timeZone(separator: .omitted),
        ]
    }

    private static var isoFractionalStyle: Date.ISO8601FormatStyle {
        Date.ISO8601FormatStyle(timeZone: .current)
            .year().month().day()
            .dateSeparator(.dash)
            .dateTimeSeparator(.standard)
            .time(includingFractionalSeconds: true)
    }

    private static var logStampStyle: Date.VerbatimFormatStyle {
        Date.VerbatimFormatStyle(
            format: "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits) \(day: .twoDigits)/\(month: .twoDigits)/\(year: .defaultDigits)",
            timeZone: .current,
            calendar: Calendar(identifier: .gregorian)
        )
    }
}
