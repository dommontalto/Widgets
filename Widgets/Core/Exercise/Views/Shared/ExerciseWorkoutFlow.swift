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
    case preCardio(ExerciseQuickWorkout)
    case cardio(ExerciseQuickWorkout)
    case complete(ExerciseWorkout)

    private var key: String {
        switch self {
        case let .preWorkout(workout): "preWorkout-\(workout.id)"
        case let .live(workout): "live-\(workout.id)"
        case let .preCardio(workout): "preCardio-\(workout.id)"
        case let .cardio(workout): "cardio-\(workout.id)"
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
                // A session that holds a run as well isn't over yet: the lifting
                // is logged and the run is set up next.
                if workout.hasCardio {
                    path.append(.preCardio(workout))
                } else {
                    path.append(.complete(finished))
                }
            }

        case let .preCardio(workout):
            ExercisePreCardioSheet(workout: workout, chrome: .pushed, onClose: close) { started in
                path.append(.cardio(started))
            }

        case let .cardio(workout):
            ExerciseLiveCardioSheet(
                onStop: {
                    path.append(
                        .complete(
                            ExerciseDemoData.loggedCardio(
                                name: workout.name,
                                afterStrength: workout.hasStrength
                            )
                        )
                    )
                },
                onClose: close
            )

        case let .complete(workout):
            ExerciseCompleteSheet(
                sessions: ExerciseDemoComplete.sessions(for: workout),
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
