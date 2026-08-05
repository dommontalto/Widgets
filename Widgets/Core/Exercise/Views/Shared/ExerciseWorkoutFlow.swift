//
//  ExerciseWorkoutFlow.swift
//  Widgets
//
//  Created by Dom Montalto on 5/8/2026.
//

import SwiftUI

/// Where a workout run currently is. One value drives one presentation, so
/// moving between stages swaps the content instead of dismissing and
/// re-presenting — no staging state, no waiting for a cover to close.
enum ExerciseWorkoutStage {
    case preWorkout(ExerciseQuickWorkout)
    case live(ExerciseQuickWorkout)
    case cardio
    case complete(ExerciseWorkout)
}

struct ExerciseWorkoutFlow: View {
    @Binding var stage: ExerciseWorkoutStage?

    var body: some View {
        switch stage {
        case let .preWorkout(workout):
            ExercisePreWorkoutSheet(workout: workout) { started in
                stage = .live(started)
            }

        case let .live(workout):
            NavigationStack {
                ExerciseLiveWorkoutSheet(
                    workoutName: workout.name,
                    templateItems: workout.items
                ) { finished in
                    stage = .complete(finished)
                }
            }

        case .cardio:
            ExerciseLiveCardioSheet { stage = nil }

        case let .complete(workout):
            ExerciseWorkoutCompleteSheet(workout: workout)

        case nil:
            EmptyView()
        }
    }
}

extension View {
    /// Presents the whole pre-workout → live → complete run in a single sheet.
    func exerciseWorkoutFlow(_ stage: Binding<ExerciseWorkoutStage?>) -> some View {
        sheet(
            isPresented: Binding(
                get: { stage.wrappedValue != nil },
                set: { if !$0 { stage.wrappedValue = nil } }
            )
        ) {
            ExerciseWorkoutFlow(stage: stage)
        }
    }
}
