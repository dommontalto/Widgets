//
//  JournalDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 13/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    static let journalStreak = 3

    static var journalDays: [Bool] {
        (0 ..< 7).map { day in
            day <= currentWeekday && day > currentWeekday - journalStreak
        }
    }
}
