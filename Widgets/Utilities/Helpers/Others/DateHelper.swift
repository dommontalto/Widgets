//
//  DateHelper.swift
//  Widgets
//
//  Created by Zoe Friedman on 22/11/2023.
//

import Foundation

class DateHelper {
    static let australianTimeZone = TimeZone(identifier: "Australia/Sydney") ?? TimeZone.current

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2 // Monday
        calendar.timeZone = DateHelper.australianTimeZone
        return calendar
    }()

    static func getDateInTimeZone(_ date: Date) -> Date {
        calendar.date(
            from: calendar.dateComponents(
                in: calendar.timeZone,
                from: date
            )
        ) ?? date
    }
}
