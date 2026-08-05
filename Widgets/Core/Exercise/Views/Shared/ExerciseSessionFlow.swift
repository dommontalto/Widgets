//
//  ExerciseSessionFlow.swift
//  Widgets
//
//  Created by Dom Montalto on 5/8/2026.
//

import SwiftUI

/// Where a session run currently is. One value drives one presentation, so
/// moving between stages swaps the content instead of dismissing and
/// re-presenting — no staging state, no waiting for a cover to close.
enum ExerciseSessionStage {
    case preSession(ExerciseQuickSession)
    case live(ExerciseQuickSession)
    case cardio
    case complete(ExerciseSession)
}

struct ExerciseSessionFlow: View {
    @Binding var stage: ExerciseSessionStage?

    var body: some View {
        switch stage {
        case let .preSession(session):
            ExercisePreSessionSheet(session: session) { started in
                stage = .live(started)
            }

        case let .live(session):
            NavigationStack {
                ExerciseLiveSessionSheet(
                    sessionName: session.name,
                    templateItems: session.items
                ) { finished in
                    stage = .complete(finished)
                }
            }

        case .cardio:
            ExerciseLiveCardioSheet { stage = nil }

        case let .complete(session):
            ExerciseSessionCompleteSheet(session: session)

        case nil:
            EmptyView()
        }
    }
}

extension View {
    /// Presents the whole pre-session → live → complete run in a single sheet.
    func exerciseSessionFlow(_ stage: Binding<ExerciseSessionStage?>) -> some View {
        sheet(
            isPresented: Binding(
                get: { stage.wrappedValue != nil },
                set: { if !$0 { stage.wrappedValue = nil } }
            )
        ) {
            ExerciseSessionFlow(stage: stage)
        }
    }
}
