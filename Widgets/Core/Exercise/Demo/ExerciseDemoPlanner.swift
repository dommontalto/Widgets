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
    static let templates: [ExercisePlannedSession] = [
        ExercisePlannedSession(title: "Back & Biceps", subtitle: "10 exercises", kind: .strength),
        ExercisePlannedSession(title: "Chest & Legs", subtitle: "10 exercises", kind: .strength),
        ExercisePlannedSession(title: "Back & Core", subtitle: "6 exercises", kind: .strength),
        ExercisePlannedSession(title: "3K Run", subtitle: "Target: Zone 2", kind: .run),
        ExercisePlannedSession(title: "10K Run", subtitle: "Target: Zone 3", kind: .run),
        ExercisePlannedSession(title: "20K Cycle", subtitle: "Target: Zone 2", kind: .cycle),
        ExercisePlannedSession(title: "Rest Day", subtitle: "", kind: .rest),
    ]

    static var week: [ExercisePlanDay] {
        [
            ExercisePlanDay(name: "Mon", sessions: [templates[0].duplicated]),
            ExercisePlanDay(name: "Tue", sessions: [templates[1].duplicated]),
            ExercisePlanDay(name: "Wed", sessions: [templates[6].duplicated]),
            ExercisePlanDay(name: "Thu", sessions: [templates[4].duplicated]),
            ExercisePlanDay(name: "Fri", sessions: [templates[2].duplicated, templates[3].duplicated]),
            ExercisePlanDay(name: "Sat", sessions: [templates[6].duplicated]),
            ExercisePlanDay(name: "Sun", sessions: [templates[5].duplicated]),
        ]
    }

    static var emptyWeek: [ExercisePlanDay] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map {
            ExercisePlanDay(name: $0, sessions: [])
        }
    }
}
