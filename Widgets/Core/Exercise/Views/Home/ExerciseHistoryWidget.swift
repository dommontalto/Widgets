//
//  ExerciseHistoryWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 21/7/2026.
//

import SwiftUI

struct ExerciseHistoryWidget: View {
    @State private var workouts = ExerciseDemoData.workoutHistory
    @State private var selectedWorkout: ExerciseWorkout?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText("Logs", size: .body1)
                BrightText("Past 14 days", size: .body2, color: .lightTextColor)
            }

            key

            VStack(spacing: .spacing0x) {
                ForEach(workouts) { workout in
                    workoutRow(workout)

                    if workout.id != workouts.last?.id {
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
        .sheet(item: $selectedWorkout) { workout in
            ExerciseCompleteSheet(
                sessions: ExerciseDemoComplete.sessions(for: workout)
            )
        }
    }

    // Reads the same as the consistency heatmap's, with imported workouts
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

    private func workoutRow(_ workout: ExerciseWorkout) -> some View {
        let color = color(for: workout)
        return Button {
            selectedWorkout = workout
        } label: {
            HStack(spacing: .spacing105x) {
                // The same square the consistency heatmap draws, so a log entry
                // and its cell on the grid read as the same thing.
                RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous)
                    .fill(color)
                    .frame(width: Constants.swatchSize, height: Constants.swatchSize)
                    .frame(width: Constants.iconWidth)

                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(workout.name, size: .body2, color: .semiLightTextColor, weight: .regular)
                    BrightText(workout.summary, size: .body3, color: .lightTextColor)
                        .monospacedDigit()
                }

                Spacer(minLength: .spacing2x)

                VStack(alignment: .trailing, spacing: .spacing05x) {
                    BrightText(workout.timestamp, size: .body3, color: .lightTextColor)
                    Image(systemName: "chevron.right")
                        .font(.standard(size: .body5, weight: .regular))
                        .foregroundStyle(Color.lightTextColor)
                }
            }
            .padding(.vertical, .spacing105x)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // The same three the consistency heatmap uses, and red for anything that
    // came in from Apple Health rather than being run here.
    private func color(for workout: ExerciseWorkout) -> Color {
        guard !workout.isFromAppleHealth else { return .defaultRed }

        return switch workout.type {
        case .cardio: .defaultSkyBlue
        case .both: .defaultGreen
        case .strength, .rest: .defaultPurple
        }
    }

    private enum Constants {
        static let iconWidth: CGFloat = 28
        static let swatchSize: CGFloat = 16
        static let keySwatchSize: CGFloat = 12
    }
}

#Preview {
    ExerciseHistoryWidget()
        .padding(.spacing4x)
}
