//
//  JournalDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 13/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    static let journalStreak = 3

    static var journalDays: [BrightChecklistWidgetV5.Day] {
        let today = Calendar.current.startOfDay(for: anchor)
        return (0 ..< 7).map { day in
            .init(
                date: Calendar.current.date(byAdding: .day, value: day - currentWeekday, to: today) ?? today,
                isDone: day <= currentWeekday && day > currentWeekday - journalStreak
            )
        }
    }
}
