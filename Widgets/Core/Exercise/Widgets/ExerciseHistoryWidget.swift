//
//  ExerciseHistoryWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 21/7/2026.
//

import SwiftUI

struct ExerciseHistoryWidget: View {
    @State private var sessions = ExerciseDemoData.sessionHistory
    @State private var selectedSession: ExerciseSession?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText("Logs", size: .body1)
                BrightText("Past 14 days", size: .body2, color: .lightTextColor)
            }

            VStack(spacing: .spacing0x) {
                ForEach(sessions) { session in
                    sessionRow(session)

                    if session.id != sessions.last?.id {
                        Rectangle()
                            .fill(Color.textColor.opacity(.ultraLowOpacity))
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
        .sheet(item: $selectedSession) { session in
            if session.type == .cardio {
                HeartWorkoutSummarySheet(workout: HeartDemoData.workout)
            } else {
                ExerciseWorkoutCompleteSheet(session: session)
            }
        }
    }

    private func sessionRow(_ session: ExerciseSession) -> some View {
        let color = color(for: session.type)
        return Button {
            selectedSession = session
        } label: {
            HStack(spacing: .spacing105x) {
                Image(systemName: session.type == .cardio ? "figure.run" : "dumbbell")
                    .font(.standardSFPro(size: .subheading2, weight: .light))
                    .foregroundStyle(color)
                    .frame(width: Constants.iconWidth)

                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(session.name, size: .body2, color: .semiLightTextColor, weight: .regular)
                    BrightText(session.summary, size: .body3, color: .lightTextColor)
                        .monospacedDigit()
                }

                Spacer(minLength: .spacing2x)

                VStack(alignment: .trailing, spacing: .spacing05x) {
                    BrightText(session.timestamp, size: .body3, color: .lightTextColor)
                    Image(systemName: "chevron.right")
                        .font(.standardSFPro(size: .body5, weight: .regular))
                        .foregroundStyle(Color.lightTextColor)
                }
            }
            .padding(.vertical, .spacing105x)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func color(for type: ExerciseDayType) -> Color {
        type == .cardio ? .defaultSkyBlue : .defaultPurple
    }

    private enum Constants {
        static let iconWidth: CGFloat = 28
    }
}

#Preview {
    ExerciseHistoryWidget()
        .padding(.spacing4x)
}
