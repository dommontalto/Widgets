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
    // The run in progress, owned above the cover so minimising it keeps the sets,
    // the clock and the rest timer alive.
    @Binding var run: ExerciseLiveWorkoutRun?

    @Environment(ExerciseWorkoutBuilder.self) private var builder

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
                run: liveRun(for: workout),
                onMinimise: minimise,
                onClose: close,
                onUpdateWorkout: { items in builder.updateItems(of: workout.id, to: items) }
            ) { finished in
                run = nil
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

    // Reuses the run already going, so reopening a minimised workout picks it up
    // rather than starting it again.
    private func liveRun(for workout: ExerciseQuickWorkout) -> ExerciseLiveWorkoutRun {
        if let run, run.workout?.id == workout.id { return run }
        let started = ExerciseLiveWorkoutRun(name: workout.name, workout: workout, templateItems: workout.items)
        run = started
        return started
    }

    // Puts the cover away and leaves the run for the docked card.
    private func minimise() {
        path.removeAll()
        stage = nil
    }

    private func close() {
        run = nil
        path.removeAll()
        stage = nil
    }
}

extension View {
    func exerciseWorkoutFlow(_ stage: Binding<ExerciseWorkoutStage?>) -> some View {
        modifier(ExerciseWorkoutFlowModifier(stage: stage))
    }
}

private struct ExerciseWorkoutFlowModifier: ViewModifier {
    @Binding var stage: ExerciseWorkoutStage?

    @Environment(ExerciseLiveWorkoutStore.self) private var store

    func body(content: Content) -> some View {
        @Bindable var store = store

        return content
            .safeAreaInset(edge: .bottom) {
                dock
            }
            .animation(.brightSnappy, value: stage)
            .fullScreenCover(
                isPresented: Binding(
                    get: { stage != nil },
                    set: { if !$0 { stage = nil } }
                )
            ) {
                ExerciseWorkoutFlow(stage: $stage, run: $store.run)
            }
    }

    // Docked behind the cover: a minimised run keeps the live card on screen,
    // controls and all, and tapping it opens the workout back up where it left off.
    @ViewBuilder private var dock: some View {
        if let run = store.run, stage == nil {
            ExerciseLiveWorkoutStatusWidget(
                status: run.status,
                heartRate: Constants.demoHeartRate,
                onRPE: reopen,
                onFailedSet: reopen,
                onExtendRest: run.extendRest(by:),
                onSkip: run.skip,
                onComplete: { if !run.completeActiveSet() { reopen() } }
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: reopen)
            .padding(.horizontal, .spacing3x)
            .padding(.bottom, .spacing1x)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // Rating a set and finishing the workout both belong to the live screen, so
    // the dock hands those back rather than duplicating them.
    private func reopen() {
        guard let workout = store.run?.workout else { return }
        stage = .live(workout)
    }

    private enum Constants {
        static let demoHeartRate = "132"
    }
}
