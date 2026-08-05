//
//  ExerciseDemoWorkouts.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

struct ExerciseQuickWorkout: Identifiable {
    let name: String
    let symbol: String
    let accentColor: Color
    let subtitle: String
    let isCardio: Bool
    var items: [ExerciseTemplateItem] = []

    var id: String { name }
}

enum ExerciseDemoWorkouts {
    static let all: [ExerciseQuickWorkout] = [quickFiveK, quickPush]

    static let quickFiveK = ExerciseQuickWorkout(
        name: "Quick 5K",
        symbol: "figure.run",
        accentColor: .defaultSkyBlue,
        subtitle: "5 km \u{2022} Zone 2",
        isCardio: true
    )

    static let quickPush = ExerciseQuickWorkout(
        name: "Quick Push",
        symbol: "dumbbell",
        accentColor: .defaultPurple,
        subtitle: "4 exercises",
        isCardio: false,
        items: [
            ExerciseTemplateItem(
                exerciseName: "Bench Press",
                target: "4 \u{00D7} 8",
                sets: [
                    ExerciseTemplateSet(weight: "40", reps: "12", kind: .warmUp),
                    ExerciseTemplateSet(weight: "60", reps: "8", kind: .working(1)),
                    ExerciseTemplateSet(weight: "70", reps: "8", kind: .working(2)),
                    ExerciseTemplateSet(weight: "80", reps: "8", kind: .working(3)),
                    ExerciseTemplateSet(weight: "60", reps: "8", kind: .dropSet),
                ]
            ),
            ExerciseTemplateItem(
                exerciseName: "Shoulder Press",
                target: "3 \u{00D7} 10",
                sets: [
                    ExerciseTemplateSet(weight: "20", reps: "12", kind: .warmUp),
                    ExerciseTemplateSet(weight: "26", reps: "10", kind: .working(1)),
                    ExerciseTemplateSet(weight: "30", reps: "10", kind: .working(2)),
                    ExerciseTemplateSet(weight: "30", reps: "10", kind: .working(3)),
                ]
            ),
            ExerciseTemplateItem(
                exerciseName: "Bicep Curl",
                target: "3 \u{00D7} 12",
                sets: [
                    ExerciseTemplateSet(weight: "10", reps: "15", kind: .warmUp),
                    ExerciseTemplateSet(weight: "15", reps: "12", kind: .working(1)),
                    ExerciseTemplateSet(weight: "17.5", reps: "12", kind: .working(2)),
                    ExerciseTemplateSet(weight: "17.5", reps: "12", kind: .working(3)),
                ]
            ),
            ExerciseTemplateItem(
                exerciseName: "Tricep Pushdown",
                target: "3 \u{00D7} 12",
                sets: [
                    ExerciseTemplateSet(weight: "15", reps: "15", kind: .warmUp),
                    ExerciseTemplateSet(weight: "22.5", reps: "12", kind: .working(1)),
                    ExerciseTemplateSet(weight: "25", reps: "12", kind: .working(2)),
                    ExerciseTemplateSet(weight: "25", reps: "12", kind: .dropSet),
                ]
            ),
        ]
    )
}
