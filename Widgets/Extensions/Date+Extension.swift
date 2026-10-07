//
//  Date+Extension.swift
//  Widgets
//
//  Created by Anthony Uccello on 2023-04-07.
//

import Foundation

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .day)
    }

    static func convertStandardDateToDisplayString(dateString: String) -> String {
        guard let date = Date(brightISOZoned: dateString) else { return "" }
        return "\(date.formatted(.brightSlashDate)) \(date.formatted(.brightTime))"
    }

    func toCurrentTimezone() -> Date {
        let timeZoneDifference =
            TimeInterval(TimeZone.current.secondsFromGMT())
        return addingTimeInterval(timeZoneDifference)
    }

    func mergeAndRoundToCurrentTime() -> Date {
        let calendar = Calendar.current

        let dateComponents = calendar.dateComponents([.year, .month, .day], from: self)
        var timeComponents = calendar.dateComponents([.hour, .minute, .second], from: Date())

        var minutes = calendar.component(.minute, from: Date())
        if minutes < 15 {
            minutes = 0
        } else if minutes < 30 {
            minutes = 15
        } else if minutes < 45 {
            minutes = 30
        } else if minutes < 59 {
            minutes = 45
        }
        timeComponents.minute = minutes

        return calendar.date(from: DateComponents(
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute,
            second: timeComponents.second
        )) ?? self
    }

    func addHours(_ hours: Int) -> Date {
        // Get the current calendar
        let calendar = Calendar.current

        // Define the date components for adding 1 hour
        var dateComponents = DateComponents()
        dateComponents.hour = hours

        // Add 1 hour to the date
        return calendar.date(byAdding: dateComponents, to: self) ?? self
    }

    func byAdding(
        component: Calendar.Component,
        value: Int,
        wrappingComponents: Bool = false,
        using calendar: Calendar = .current
    ) -> Date? {
        calendar.date(byAdding: component, value: value, to: self, wrappingComponents: wrappingComponents)
    }

    func hasSameHour(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .hour)
    }

    func isSameHour(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .hour)
    }

    func hasSameMinute(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .minute)
    }

    func isInSameWeek(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .weekOfMonth)
    }

    func isInSameMonth(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .month)
    }

    func isInSameTriMonth(as date: Date) -> Bool {
        month().roundedUp(toNearest: 3) == date.month().roundedUp(toNearest: 3) && year() == date.year()
    }

    func isInSameYear(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .year)
    }

    func startOfHour() -> Date {
        Calendar.current.date(bySettingHour: hour(), minute: 0, second: 0, of: self) ?? Date()
    }

    func endOfHour() -> Date {
        Calendar.current.date(bySettingHour: hour(), minute: 59, second: 59, of: self) ?? Date()
    }

    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }

    func endOfDay() -> Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? Date()
    }

    func startOfWeek() -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday is the first day of the week

        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        guard let startOfWeek = calendar.date(from: components) else {
            return self
        }

        return calendar.startOfDay(for: startOfWeek)
    }

    func endOfWeek() -> Date {
        let calendar = Calendar.current
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek())!
        return endOfWeek.endOfDay()
    }

    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        let startOfMonth = calendar.date(from: components)!
        return startOfMonth.startOfDay()
    }

    func startOfYear() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        let startOfYear = calendar.date(from: components)!
        return startOfYear.startOfDay()
    }

    func endOfMonth() -> Date {
        let calendar = Calendar.current
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth())!
        let endOfMonth = calendar.date(byAdding: .day, value: -1, to: startOfNextMonth)!
        return endOfMonth.endOfDay()
    }

    func endOfYear() -> Date {
        let calendar = Calendar.current
        let startOfNextYear = calendar.date(byAdding: .year, value: 1, to: startOfYear())!
        let endOfYear = calendar.date(byAdding: .day, value: -1, to: startOfNextYear)!
        return endOfYear.endOfDay()
    }

    func daysDifference(to date: Date) -> Int? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startOfDay(), to: date.startOfDay())
        return components.day
    }

    func numDaysInMonth() -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: self)!
        return range.count
    }

    func mergeDate(withTimeDate date: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: self)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: date)

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second

        if let finalDate = calendar.date(from: combinedComponents) {
            return finalDate
        }
        return date
    }

    func compareTimeOnly(with date: Date) -> ComparisonResult {
        let calendar = Calendar.current

        // Extract time components from both dates
        let components1 = calendar.dateComponents([.hour, .minute, .second], from: self)
        let components2 = calendar.dateComponents([.hour, .minute, .second], from: date)

        // Compare hour, then minute, then second
        if components1.hour! < components2.hour! {
            return .orderedAscending
        } else if components1.hour! > components2.hour! {
            return .orderedDescending
        } else {
            // Hours are equal, compare minutes
            if components1.minute! < components2.minute! {
                return .orderedAscending
            } else if components1.minute! > components2.minute! {
                return .orderedDescending
            } else {
                // Minutes are equal, compare seconds
                if components1.second! < components2.second! {
                    return .orderedAscending
                } else if components1.second! > components2.second! {
                    return .orderedDescending
                } else {
                    // Times are equal
                    return .orderedSame
                }
            }
        }
    }

    func compareDateOnly(with date: Date) -> ComparisonResult {
        let calendar = Calendar.current

        // Extract time components from both dates
        let components1 = calendar.dateComponents([.year, .month, .day], from: self)
        let components2 = calendar.dateComponents([.year, .month, .day], from: date)

        // Compare hour, then minute, then second
        if components1.year! < components2.year! {
            return .orderedAscending
        } else if components1.year! > components2.year! {
            return .orderedDescending
        } else {
            // Hours are equal, compare minutes
            if components1.month! < components2.month! {
                return .orderedAscending
            } else if components1.month! > components2.month! {
                return .orderedDescending
            } else {
                // Minutes are equal, compare seconds
                if components1.day! < components2.day! {
                    return .orderedAscending
                } else if components1.day! > components2.day! {
                    return .orderedDescending
                } else {
                    // Times are equal
                    return .orderedSame
                }
            }
        }
    }

    func minutesDifference(startDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: startDate, to: self)
        return components.minute ?? 0
    }

    func secondsDifference(startDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.second], from: startDate, to: self)
        return components.second ?? 0
    }
}

// MARK: - Convenience Properties

extension Date {
    public var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    public var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    // Days from this date to today (negative if in the past)
    public var daysFromToday: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: self),
            to: calendar.startOfDay(for: Date())
        )
        return components.day ?? 0
    }

    // Days since this date (positive if in the past)
    public var daysSinceDate: Int {
        daysFromToday
    }
}

// MARK: - Component Accessors

extension Date {
    public func hour() -> Int {
        Calendar.current.component(.hour, from: self)
    }
    public func minute() -> Int {
        Calendar.current.component(.minute, from: self)
    }
    public func second() -> Int {
        Calendar.current.component(.second, from: self)
    }

    public func day() -> Int {
        Calendar.current.component(.day, from: self)
    }
    public func month() -> Int {
        Calendar.current.component(.month, from: self)
    }
    public func year() -> Int {
        Calendar.current.component(.year, from: self)
    }
}
