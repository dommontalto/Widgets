//
//  ExerciseWorkoutFlow.swift
//  Widgets
//
//  Created by Dom Montalto on 5/8/2026.
//

import SwiftUI

enum ExerciseWorkoutStage: Hashable {
    case preWorkout(ExerciseQuickWorkout)
    case live(ExerciseQuickWorkout)
    case cardio
    case complete(ExerciseWorkout)

    private var key: String {
        switch self {
        case let .preWorkout(workout): "preWorkout-\(workout.id)"
        case let .live(workout): "live-\(workout.id)"
        case .cardio: "cardio"
        case let .complete(workout): "complete-\(workout.id)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

enum ExercisePageChrome {
    case sheet
    case pushed
}

struct ExerciseWorkoutFlow: View {
    @Binding var stage: ExerciseWorkoutStage?

    @Environment(ExerciseBuilder.self) private var builder

    @State private var path: [ExerciseWorkoutStage] = []

    var body: some View {
        NavigationStack(path: $path) {
            page(for: stage)
                .navigationDestination(for: ExerciseWorkoutStage.self) { stage in
                    page(for: stage)
                        .navigationBarBackButtonHidden()
                }
        }
    }

    @ViewBuilder private func page(for stage: ExerciseWorkoutStage?) -> some View {
        switch stage {
        case let .preWorkout(workout):
            ExercisePreWorkoutSheet(workout: workout, chrome: .pushed, onClose: close) { started in
                path.append(.live(started))
            }

        case let .live(workout):
            ExerciseLiveWorkoutSheet(
                workoutName: workout.name,
                templateItems: workout.items,
                onClose: close,
                onUpdateWorkout: { items in builder.updateItems(of: workout.id, to: items) }
            ) { finished in
                path.append(.complete(finished))
            }

        case .cardio:
            ExerciseLiveCardioSheet(onStop: close, onClose: close)

        case let .complete(workout):
            ExerciseWorkoutCompleteSheet(
                workout: workout,
                backgroundColor: .defaultBackground,
                chrome: .pushed,
                onClose: close
            )

        case nil:
            EmptyView()
        }
    }

    private func close() {
        stage = nil
    }
}

extension View {
    func exerciseWorkoutFlow(_ stage: Binding<ExerciseWorkoutStage?>) -> some View {
        fullScreenCover(
            isPresented: Binding(
                get: { stage.wrappedValue != nil },
                set: { if !$0 { stage.wrappedValue = nil } }
            )
        ) {
            ExerciseWorkoutFlow(stage: stage)
        }
    }
}
