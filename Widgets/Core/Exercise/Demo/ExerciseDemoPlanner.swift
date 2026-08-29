//
//  ExerciseDemoPlanner.swift
//  Widgets
//
//  Created by Dom Montalto on 4/8/2026.
//

import SwiftUI

// Demo data for the weekly session planner. Kept apart from ExerciseDemoData
// because it depends on the planner's own models.
enum ExerciseDemoPlanner {
    // The same sessions My Sessions holds, plus the rest day a planner needs.
    static let templates: [ExercisePlannedSession] = ExerciseDemoSessions.all.map(planned) + [
        ExercisePlannedSession(title: "Rest Day", subtitle: "", kind: .rest),
    ]

    private static func planned(_ session: ExerciseQuickSession) -> ExercisePlannedSession {
        let hasStrength = !session.strengthItems.isEmpty
        let hasCardio = !session.cardioItems.isEmpty
        let kind: ExercisePlannedSession.Kind = if hasStrength, hasCardio {
            .mixed
        } else if hasCardio {
            .cardio
        } else {
            .strength
        }

        // The icon follows whatever the session opens with, so a lift-then-run
        // session wears the gym glyph.
        let opener = session.items.first.map { ExerciseDemoLibrary.type(of: $0.exerciseName).symbol }
        return ExercisePlannedSession(
            title: session.name,
            subtitle: session.subtitle,
            kind: kind,
            symbol: opener
        )
    }

    static var week: [ExercisePlanDay] {
        [
            ExercisePlanDay(name: "Mon", sessions: [template("Push & run")]),
            ExercisePlanDay(name: "Tue", sessions: [template("Quick Push")]),
            ExercisePlanDay(name: "Wed", sessions: []),
            ExercisePlanDay(name: "Thu", sessions: [template("Quick 10K")]),
            ExercisePlanDay(name: "Fri", sessions: [template("Quick Pull"), template("Quick 5K")]),
            ExercisePlanDay(name: "Sat", sessions: []),
            ExercisePlanDay(name: "Sun", sessions: [template("Quick 5K")]),
        ]
    }

    private static func template(_ name: String) -> ExercisePlannedSession {
        (templates.first { $0.title == name } ?? templates[0]).duplicated
    }

    static var emptyWeek: [ExercisePlanDay] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map {
            ExercisePlanDay(name: $0, sessions: [])
        }
    }
}
