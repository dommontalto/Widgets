//
//  ExerciseWorkoutFlow.swift
//  Widgets
//
//  Created by Dom Montalto on 5/8/2026.
//

import SwiftUI

// Backend: a session is one leg of lifting plus one leg per cardio or sport,
// taken in the order the exercises were added. Everything logged set by set
// collapses into the single live workout; each run or sport gets its own setup
// and live screen, and the session isn't finished until the last leg stops. The
// split comes from the exercise's category here, so the demo library stands in
// for whatever the API reports it as.
enum ExerciseWorkoutStage: Hashable {
    case preWorkout(ExerciseQuickWorkout)
    case live(ExerciseQuickWorkout)
    // A session can hold more than one run or sport, so each carries the leg it
    // stands for.
    case preCardio(ExerciseQuickWorkout, leg: Int)
    case cardio(ExerciseQuickWorkout, leg: Int)
    case complete(ExerciseWorkout)

    private var key: String {
        switch self {
        case let .preWorkout(workout): "preWorkout-\(workout.id)"
        case let .live(workout): "live-\(workout.id)"
        case let .preCardio(workout, leg): "preCardio-\(workout.id)-\(leg)"
        case let .cardio(workout, leg): "cardio-\(workout.id)-\(leg)"
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
                templateItems: workout.strengthItems,
                onClose: close,
                onUpdateWorkout: { items in builder.updateItems(of: workout.id, to: items) }
            ) { finished in
                // A session that holds a run as well isn't over yet: the lifting
                // is logged and the first run is set up next.
                if workout.hasCardio {
                    path.append(.preCardio(workout, leg: 0))
                } else {
                    path.append(.complete(finished))
                }
            }

        case let .preCardio(workout, leg):
            ExercisePreCardioSheet(
                workout: workout,
                leg: leg,
                chrome: .pushed,
                onClose: close
            ) { started in
                path.append(.cardio(started, leg: leg))
            }

        case let .cardio(workout, leg):
            ExerciseLiveCardioSheet(
                onStop: {
                    // Straight into the next run's setup while there is one, so
                    // a session of several legs only finishes once.
                    if leg + 1 < workout.cardioItems.count {
                        path.append(.preCardio(workout, leg: leg + 1))
                    } else {
                        path.append(.complete(ExerciseDemoData.logged(workout)))
                    }
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
