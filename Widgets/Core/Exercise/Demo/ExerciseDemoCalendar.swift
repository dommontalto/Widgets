//
//  ExerciseDemoCalendar.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import SwiftUI

struct ExerciseCalendarSession {
    let name: String
    let time: String
    let duration: String
    let color: Color
    let symbols: [String]
}

struct ExerciseCalendarEvent: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let detailIcon: String?
    let startMinutes: Int
    let durationMinutes: Int
    let color: Color
}

enum ExerciseCalendarDemo {
    static func session(on date: Date) -> ExerciseCalendarSession? {
        sessionsByOffset[offset(of: date)]
    }

    static func events(on date: Date) -> [ExerciseCalendarEvent] {
        eventsByOffset[offset(of: date)] ?? []
    }

    private static func offset(of date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: date)).day ?? 0
    }

    private static let sessionsByOffset: [Int: ExerciseCalendarSession] = [
        0: ExerciseCalendarSession(
            name: "Gym session",
            time: "6:00 - 7:00 PM",
            duration: "1hr 30min",
            color: .defaultPurple,
            symbols: ["figure.strengthtraining.traditional", "figure.run"]
        ),
        1: ExerciseCalendarSession(
            name: "5K run",
            time: "6:30 - 7:00 AM",
            duration: "30min",
            color: .defaultSkyBlue,
            symbols: ["figure.run"]
        ),
        3: ExerciseCalendarSession(
            name: "Soccer",
            time: "8:30 - 9:00 PM",
            duration: "30min",
            color: .defaultGreen,
            symbols: ["figure.indoor.soccer"]
        ),
    ]

    private static let eventsByOffset: [Int: [ExerciseCalendarEvent]] = [
        -2: [
            ExerciseCalendarEvent(
                name: "Soccer", detail: "30 Mins", detailIcon: "stopwatch",
                startMinutes: 18 * 60, durationMinutes: 60, color: .defaultGreen
            ),
        ],
        0: [
            ExerciseCalendarEvent(
                name: "Soccer", detail: "30 Mins", detailIcon: "stopwatch",
                startMinutes: 11 * 60, durationMinutes: 60, color: .defaultGreen
            ),
            ExerciseCalendarEvent(
                name: "Push Pull Split", detail: "1hr 30min", detailIcon: "stopwatch",
                startMinutes: 13 * 60, durationMinutes: 60, color: .defaultPurple
            ),
            ExerciseCalendarEvent(
                name: "Push Pull Split", detail: "1hr 30min", detailIcon: "stopwatch",
                startMinutes: 15 * 60, durationMinutes: 27, color: .defaultPurple
            ),
            ExerciseCalendarEvent(
                name: "Warmdown Walk", detail: "Free walk", detailIcon: nil,
                startMinutes: 15 * 60 + 30, durationMinutes: 25, color: .defaultSkyBlue
            ),
            ExerciseCalendarEvent(
                name: "5K run", detail: "40 Mins", detailIcon: "stopwatch",
                startMinutes: 17 * 60, durationMinutes: 60, color: .defaultSkyBlue
            ),
        ],
        1: [
            ExerciseCalendarEvent(
                name: "5K run", detail: "30 Mins", detailIcon: "stopwatch",
                startMinutes: 6 * 60 + 30, durationMinutes: 30, color: .defaultSkyBlue
            ),
        ],
        3: [
            ExerciseCalendarEvent(
                name: "Soccer", detail: "30 Mins", detailIcon: "stopwatch",
                startMinutes: 20 * 60 + 30, durationMinutes: 30, color: .defaultGreen
            ),
        ],
    ]
}
