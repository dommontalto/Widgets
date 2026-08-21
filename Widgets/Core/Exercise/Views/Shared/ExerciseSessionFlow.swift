//
//  ExerciseSessionFlow.swift
//  Widgets
//
//  Created by Dom Montalto on 5/8/2026.
//

import SwiftUI

// Backend: a session is one leg of lifting plus one leg per cardio or sport,
// taken in the order the exercises were added. Everything logged set by set
// collapses into the single live session; each run or sport gets its own setup
// and live screen, and the session isn't finished until the last leg stops. The
// split comes from the exercise's category here, so the demo library stands in
// for whatever the API reports it as.
enum ExerciseSessionStage: Hashable {
    // Every stage carries the leg it stands for — a session can hold several
    // strength blocks and several runs, each its own screen.
    case preStrength(ExerciseQuickSession, leg: Int)
    case live(ExerciseQuickSession, leg: Int)
    case preCardio(ExerciseQuickSession, leg: Int)
    case cardio(ExerciseQuickSession, leg: Int)
    case complete(ExerciseLoggedSession)

    // The leg's setup screen — lifting or a run, whatever the user put there.
    static func setup(for session: ExerciseQuickSession, leg: Int) -> ExerciseSessionStage? {
        guard let next = session.legs[safe: leg] else { return nil }
        return next.isCardio
            ? .preCardio(session, leg: leg)
            : .preStrength(session, leg: leg)
    }

    private var key: String {
        switch self {
        case let .preStrength(session, leg): "preStrength-\(session.id)-\(leg)"
        case let .live(session, leg): "live-\(session.id)-\(leg)"
        case let .preCardio(session, leg): "preCardio-\(session.id)-\(leg)"
        case let .cardio(session, leg): "cardio-\(session.id)-\(leg)"
        case let .complete(session): "complete-\(session.id)"
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

struct ExerciseSessionFlow: View {
    @Binding var stage: ExerciseSessionStage?

    @Environment(ExerciseBuilder.self) private var builder

    @State private var path: [ExerciseSessionStage] = []

    var body: some View {
        NavigationStack(path: $path) {
            page(for: stage)
                .navigationDestination(for: ExerciseSessionStage.self) { stage in
                    page(for: stage)
                        .navigationBarBackButtonHidden()
                }
        }
    }

    @ViewBuilder private func page(for stage: ExerciseSessionStage?) -> some View {
        switch stage {
        case let .preStrength(session, leg):
            ExercisePreStrengthSheet(session: session, leg: leg, chrome: .pushed, onClose: close) { started in
                path.append(.live(started, leg: leg))
            }

        case let .live(session, leg):
            ExerciseLiveStrengthSheet(
                sessionName: session.name,
                templateItems: session.legs[safe: leg].map(session.items(in:)) ?? session.strengthItems,
                onClose: close,
                onUpdateSession: { blockItems in
                    // The run edited one leg; the template holds them all,
                    // so the block splices back into its own stretch.
                    guard case let .strength(range) = session.legs[safe: leg] else { return }
                    var items = session.items
                    items.replaceSubrange(range, with: blockItems)
                    builder.updateItems(of: session.id, to: items)
                }
            ) { finished in
                advance(session, after: leg, finished: finished)
            }

        case let .preCardio(session, leg):
            ExercisePreCardioSheet(
                session: session,
                leg: leg,
                chrome: .pushed,
                onClose: close
            ) { started in
                path.append(.cardio(started, leg: leg))
            }

        case let .cardio(session, leg):
            ExerciseLiveCardioSheet(
                onStop: {
                    advance(session, after: leg, finished: ExerciseDemoData.logged(session))
                },
                onClose: close
            )

        case let .complete(session):
            ExerciseCompleteSheet(
                sessions: ExerciseDemoComplete.sessions(for: session),
                chrome: .pushed,
                onClose: close
            )

        case nil:
            EmptyView()
        }
    }

    // A finished leg hands straight to the next one's setup while there is one,
    // so a session of several legs only finishes once.
    private func advance(_ session: ExerciseQuickSession, after leg: Int, finished: ExerciseLoggedSession) {
        if let next = ExerciseSessionStage.setup(for: session, leg: leg + 1) {
            path.append(next)
        } else {
            path.append(.complete(finished))
        }
    }

    private func close() {
        stage = nil
    }
}

extension View {
    func exerciseSessionFlow(_ stage: Binding<ExerciseSessionStage?>) -> some View {
        fullScreenCover(
            isPresented: Binding(
                get: { stage.wrappedValue != nil },
                set: { if !$0 { stage.wrappedValue = nil } }
            )
        ) {
            ExerciseSessionFlow(stage: stage)
        }
    }
}
