//
//  ExerciseAllLogsSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 24/8/2026.
//

import SwiftUI

struct ExerciseAllLogsSheet: View {
    let sessions: [ExerciseLoggedSession]

    @State private var selectedSession: ExerciseLoggedSession?

    var body: some View {
        BrightPageSheetView(title: "Logs") {
            list
        }
        .sheet(item: $selectedSession) { session in
            ExerciseCompleteSheet(
                sessions: ExerciseDemoComplete.sessions(for: session)
            )
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: .spacing0x) {
                ForEach(sessions) { session in
                    let isLast = session.id == sessions.last?.id
                    ExerciseLogRow(session: session, isLast: isLast) {
                        selectedSession = session
                    }

                    if !isLast {
                        ExerciseLogDivider()
                    }
                }
            }
            .padding(.spacing3x)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(CardModifier(color: .defaultSheetModalCards))
        }
        .scrollIndicators(.hidden)
        .padding(.top, .spacing2x)
    }
}

#Preview {
    ExerciseAllLogsSheet(sessions: ExerciseDemoData.sessionHistory)
}
