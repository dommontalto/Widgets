//
//  ExerciseAllLogsSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 24/8/2026.
//

import SwiftUI

struct ExerciseAllLogsSheet: View {
    let sessions: [ExerciseLoggedSession]

    @State private var path = NavigationPath()

    var body: some View {
        BrightPageSheetView(title: "Session History", path: $path) {
            list
                .navigationDestination(for: ExerciseLoggedSession.self) { session in
                    ExerciseCompleteSheet(
                        sessions: ExerciseDemoComplete.sessions(for: session),
                        chrome: .pushed,
                        backgroundColor: .defaultSheetBackground
                    )
                }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: .spacing0x) {
                ForEach(sessions) { session in
                    let isLast = session.id == sessions.last?.id
                    ExerciseLogRow(
                        session: session,
                        isFirst: session.id == sessions.first?.id,
                        isLast: isLast
                    ) {
                        path.append(session)
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
    }
}

#Preview {
    ExerciseAllLogsSheet(sessions: ExerciseDemoData.sessionHistory)
}
