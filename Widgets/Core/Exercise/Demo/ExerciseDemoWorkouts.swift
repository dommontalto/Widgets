//
//  ExerciseDemoWorkouts.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

// One of the icons a session wears — the icon of an exercise it holds.
nonisolated struct ExerciseSessionGlyph: Identifiable {
    let id: String
    let color: Color

    var symbol: String { id }
}

struct ExerciseQuickWorkout: Identifiable {
    let name: String
    let subtitle: String
    var items: [ExerciseTemplateItem] = []

    var id: String { name }

    // A session runs as cardio only when there's nothing in it to log set by set.
    var isCardio: Bool {
        !items.isEmpty && items.allSatisfy { ExerciseDemoLibrary.isCardio($0.exerciseName) }
    }

    var symbol: String { glyphs.first?.symbol ?? ExerciseWorkoutCategory.gym.symbol }

    var accentColor: Color { glyphs.first?.color ?? ExerciseWorkoutCategory.gym.accentColor }

    // The card wears what's in the session: one icon per exercise in the order
    // they were added, up to four, and never the same icon twice.
    var glyphs: [ExerciseSessionGlyph] {
        var glyphs: [ExerciseSessionGlyph] = []
        for item in items {
            let glyph = ExerciseDemoLibrary.glyph(for: item.exerciseName)
            guard !glyphs.contains(where: { $0.id == glyph.id }) else { continue }
            glyphs.append(glyph)
            if glyphs.count == ExerciseQuickWorkout.maxGlyphs { break }
        }
        return glyphs
    }

    static let maxGlyphs = 4
}

enum ExerciseDemoWorkouts {
    static let all: [ExerciseQuickWorkout] = [quickFiveK, quickTenK, quickPush, quickPull]

    static let quickFiveK = ExerciseQuickWorkout(
        name: "Quick 5K",
        subtitle: "5 km \u{2022} Zone 2",
        items: [
            ExerciseTemplateItem(
                exerciseName: "Outdoor Run",
                target: "5 km \u{2022} Zone 2",
                plan: ExerciseCardioPlan(goal: .distance, secondary: .pace, distance: "5", pace: "5\u{2019}00")
            ),
        ]
    )

    static let quickTenK = ExerciseQuickWorkout(
        name: "Quick 10K",
        subtitle: "10 km \u{2022} Zone 3",
        items: [
            ExerciseTemplateItem(
                exerciseName: "Outdoor Run",
                target: "10 km \u{2022} Zone 3",
                plan: ExerciseCardioPlan(goal: .distance, secondary: .pace, distance: "10", pace: "5\u{2019}20")
            ),
        ]
    )

    static let quickPush = ExerciseQuickWorkout(
        name: "Quick Push",
        subtitle: "4 exercises",
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

    static let quickPull = ExerciseQuickWorkout(
        name: "Quick Pull",
        subtitle: "3 exercises",
        items: [
            ExerciseTemplateItem(
                exerciseName: "Pull Up",
                target: "4 \u{00D7} 8",
                sets: [
                    ExerciseTemplateSet(weight: "0", reps: "6", kind: .warmUp),
                    ExerciseTemplateSet(weight: "0", reps: "8", kind: .working(1)),
                    ExerciseTemplateSet(weight: "5", reps: "8", kind: .working(2)),
                    ExerciseTemplateSet(weight: "5", reps: "8", kind: .working(3)),
                ]
            ),
            ExerciseTemplateItem(
                exerciseName: "Bent Over Row",
                target: "3 \u{00D7} 10",
                sets: [
                    ExerciseTemplateSet(weight: "40", reps: "12", kind: .warmUp),
                    ExerciseTemplateSet(weight: "60", reps: "10", kind: .working(1)),
                    ExerciseTemplateSet(weight: "65", reps: "10", kind: .working(2)),
                    ExerciseTemplateSet(weight: "65", reps: "10", kind: .working(3)),
                ]
            ),
            ExerciseTemplateItem(
                exerciseName: "Bicep Curl",
                target: "3 \u{00D7} 12",
                sets: [
                    ExerciseTemplateSet(weight: "10", reps: "15", kind: .warmUp),
                    ExerciseTemplateSet(weight: "15", reps: "12", kind: .working(1)),
                    ExerciseTemplateSet(weight: "17.5", reps: "12", kind: .working(2)),
                ]
            ),
        ]
    )
}
