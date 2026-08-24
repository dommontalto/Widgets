//
//  ExerciseHistoryWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 21/7/2026.
//

import SwiftUI

struct ExerciseHistoryWidget: View {
    @State private var sessions = ExerciseDemoData.sessionHistory
    @State private var selectedSession: ExerciseLoggedSession?
    @State private var showingAllLogs = false

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            header

            key
                .padding(.vertical, .spacing2x)

            VStack(spacing: .spacing0x) {
                ForEach(sessions) { session in
                    ExerciseLogRow(session: session, isLast: session.id == sessions.last?.id) {
                        selectedSession = session
                    }

                    if session.id != sessions.last?.id {
                        ExerciseLogDivider()
                    }
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
        .sheet(item: $selectedSession) { session in
            ExerciseCompleteSheet(
                sessions: ExerciseDemoComplete.sessions(for: session)
            )
        }
        .sheet(isPresented: $showingAllLogs) {
            ExerciseAllLogsSheet(sessions: sessions)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText("Logs", size: .body1)
                BrightText("Past 14 days", size: .body2, color: .lightTextColor)
            }

            Spacer()

            BrightPillButton("Show More", buttonSize: .small) {
                showingAllLogs = true
            }
        }
    }

    // Reads the same as the consistency heatmap's, with imported sessions
    // standing in for its rest days.
    private var key: some View {
        FlowLayout(spacing: .spacing2x) {
            keyItem("Strength", color: .defaultPurple)
            keyItem("Cardio", color: .defaultSkyBlue)
            keyItem("Both", color: .defaultGreen)
            keyItem("Apple Health", color: .defaultRed)
        }
    }

    private func keyItem(_ title: String, color: Color) -> some View {
        HStack(spacing: .spacing1x) {
            RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous)
                .fill(color)
                .frame(width: Constants.keySwatchSize, height: Constants.keySwatchSize)

            BrightText(title, size: .body3, color: .lightTextColor)
        }
    }

    private enum Constants {
        static let keySwatchSize: CGFloat = 12
    }
}

#Preview {
    ExerciseHistoryWidget()
        .padding(.spacing4x)
}
