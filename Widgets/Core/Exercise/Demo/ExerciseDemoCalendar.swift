//
//  ExerciseDemoCalendar.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import SwiftUI

struct ExerciseCalendarSession: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let categories: [ExerciseCategory]
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

// When a saved session is on. Everything else about it — its name, what it
// holds and how it reads — comes from the session itself, so the calendar can
// only ever show sessions My Sessions holds.
private struct ExerciseScheduledSession {
    let name: String
    let startMinutes: Int
    let durationMinutes: Int

    var session: ExerciseQuickSession? {
        ExerciseDemoSessions.all.first { $0.name == name }
    }
}

enum ExerciseCalendarDemo {
    static func sessions(on date: Date) -> [ExerciseCalendarSession] {
        schedule(on: date).compactMap { scheduled in
            guard let session = scheduled.session else { return nil }

            return ExerciseCalendarSession(
                id: session.id,
                name: session.name,
                subtitle: session.subtitle,
                categories: session.categories
            )
        }
    }

    static func events(on date: Date) -> [ExerciseCalendarEvent] {
        schedule(on: date).compactMap { scheduled in
            guard let session = scheduled.session else { return nil }

            return ExerciseCalendarEvent(
                name: session.name,
                detail: durationLabel(scheduled.durationMinutes),
                detailIcon: "stopwatch",
                startMinutes: scheduled.startMinutes,
                durationMinutes: scheduled.durationMinutes,
                color: color(of: session)
            )
        }
    }

    // The calendar dot mirrors the heatmap palette: purple for strength-only
    // days, cardio blue for cardio-only, and their gradient when a day holds
    // both — a session carrying lifts and a run counts as both on its own.
    static func dotStyle(on date: Date) -> AnyShapeStyle? {
        let sessions = schedule(on: date).compactMap(\.session)
        guard !sessions.isEmpty else { return nil }

        let hasStrength = sessions.contains { !$0.strengthItems.isEmpty }
        let hasCardio = sessions.contains { !$0.cardioItems.isEmpty }
        if hasStrength, hasCardio { return AnyShapeStyle(ExerciseDayType.bothGradient) }
        if hasStrength { return AnyShapeStyle(Color.defaultPink) }
        if hasCardio { return AnyShapeStyle(Color.defaultSkyBlueCyan) }
        return nil
    }

    private static func color(of session: ExerciseQuickSession) -> Color {
        session.strengthItems.isEmpty ? .defaultSkyBlueCyan : .defaultPink
    }

    private static func durationLabel(_ minutes: Int) -> String {
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "\(rest)min" }
        return rest == 0 ? "\(hours)hr" : "\(hours)hr \(rest)min"
    }

    private static func schedule(on date: Date) -> [ExerciseScheduledSession] {
        scheduleByOffset[offset(of: date)] ?? []
    }

    private static func offset(of date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: date)).day ?? 0
    }

    private static let scheduleByOffset: [Int: [ExerciseScheduledSession]] = [
        -2: [
            ExerciseScheduledSession(
                name: "Quick 5K", startMinutes: 6 * 60 + 30, durationMinutes: 30
            ),
        ],
        0: [
            ExerciseScheduledSession(
                name: "Push & run", startMinutes: 18 * 60, durationMinutes: 90
            ),
            ExerciseScheduledSession(
                name: "Quick Pull", startMinutes: 20 * 60, durationMinutes: 60
            ),
        ],
        1: [
            ExerciseScheduledSession(
                name: "Quick Push", startMinutes: 6 * 60 + 30, durationMinutes: 60
            ),
        ],
        3: [
            ExerciseScheduledSession(
                name: "Quick 10K", startMinutes: 20 * 60 + 30, durationMinutes: 60
            ),
        ],
    ]
}
