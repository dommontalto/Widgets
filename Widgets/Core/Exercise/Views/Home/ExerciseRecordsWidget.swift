//
//  ExerciseRecordsWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

struct ExerciseRecordsWidget: View {
    private struct Record: Identifiable {
        let id = UUID()
        let exerciseName: String
        let detail: String
        let date: String
    }

    private let records = [
        Record(exerciseName: "Bench Press", detail: "100 kg \u{00D7} 5 \u{2022} est 1RM 112 kg", date: "23 Jul"),
        Record(exerciseName: "Bicep Curl", detail: "40 kg \u{00D7} 8", date: "23 Jul"),
        Record(exerciseName: "Outdoor Run", detail: "Fastest km 4\u{2019}46\u{201D}", date: "22 Jul"),
        Record(exerciseName: "Squat", detail: "140 kg \u{00D7} 3", date: "18 Jul"),
        Record(exerciseName: "Deadlift", detail: "180 kg \u{00D7} 1", date: "12 Jul"),
    ]

    @State private var openedExerciseName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText("Personal records", size: .body1)
                BrightText("Past 30 days", size: .body2, color: .lightTextColor)
            }

            VStack(spacing: .spacing0x) {
                ForEach(records) { record in
                    recordRow(record)

                    if record.id != records.last?.id {
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
        .sheet(item: openedExerciseBinding) { exercise in
            BrightPageSheetView(title: exercise.name) {
                BrightPlaceholderView(
                    systemImage: exercise.category.symbol,
                    title: exercise.name,
                    subtitle: exercise.equipmentLabel
                )
            }
        }
    }

    private var openedExerciseBinding: Binding<ExerciseDefinition?> {
        Binding(
            get: { openedExerciseName.flatMap(ExerciseDemoLibrary.exercise(named:)) },
            set: { openedExerciseName = $0?.name }
        )
    }

    private func recordRow(_ record: Record) -> some View {
        Button {
            openedExerciseName = record.exerciseName
        } label: {
            HStack(spacing: .spacing105x) {
                Image(systemName: "trophy")
                    .font(.standardSFPro(size: .subheading2, weight: .light))
                    .foregroundStyle(Color.defaultOrange)
                    .frame(width: Constants.iconWidth)

                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(record.exerciseName, size: .body2, color: .semiLightTextColor, weight: .regular)
                    BrightText(record.detail, size: .body3, color: .lightTextColor)
                        .monospacedDigit()
                }

                Spacer(minLength: .spacing2x)

                VStack(alignment: .trailing, spacing: .spacing05x) {
                    BrightText(record.date, size: .body3, color: .lightTextColor)
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

    private class Constants {
        static let iconWidth: CGFloat = 28
    }
}

#Preview {
    ExerciseRecordsWidget()
        .padding(.spacing4x)
}
