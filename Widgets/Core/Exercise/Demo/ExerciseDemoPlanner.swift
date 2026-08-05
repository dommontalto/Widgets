//
//  ExerciseDemoPlanner.swift
//  Widgets
//
//  Created by Dom Montalto on 4/8/2026.
//

import SwiftUI

/// Demo data for the weekly workout planner. Kept apart from ExerciseDemoData
/// because it depends on the planner's own models.
enum ExerciseDemoPlanner {
    static let templates: [ExercisePlannedWorkout] = [
        ExercisePlannedWorkout(title: "Back & Biceps", subtitle: "10 exercises", kind: .strength),
        ExercisePlannedWorkout(title: "Chest & Legs", subtitle: "10 exercises", kind: .strength),
        ExercisePlannedWorkout(title: "Back & Core", subtitle: "6 exercises", kind: .strength),
        ExercisePlannedWorkout(title: "3K Run", subtitle: "Target: Zone 2", kind: .run),
        ExercisePlannedWorkout(title: "10K Run", subtitle: "Target: Zone 3", kind: .run),
        ExercisePlannedWorkout(title: "20K Cycle", subtitle: "Target: Zone 2", kind: .cycle),
        ExercisePlannedWorkout(title: "Rest Day", subtitle: "", kind: .rest),
    ]

    static var week: [ExercisePlanDay] {
        [
            ExercisePlanDay(name: "Mon", workouts: [templates[0].duplicated]),
            ExercisePlanDay(name: "Tue", workouts: [templates[1].duplicated]),
            ExercisePlanDay(name: "Wed", workouts: [templates[6].duplicated]),
            ExercisePlanDay(name: "Thu", workouts: [templates[4].duplicated]),
            ExercisePlanDay(name: "Fri", workouts: [templates[2].duplicated, templates[3].duplicated]),
            ExercisePlanDay(name: "Sat", workouts: [templates[6].duplicated]),
            ExercisePlanDay(name: "Sun", workouts: [templates[5].duplicated]),
        ]
    }

    static var emptyWeek: [ExercisePlanDay] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map {
            ExercisePlanDay(name: $0, workouts: [])
        }
    }
}
