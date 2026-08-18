//
//  ExerciseLibrarySheet.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

struct ExerciseLibrarySheet: View {
    var onSelect: ((ExerciseDefinition) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    @State private var selectedEquipment: ExerciseEquipment?

    @State private var selectedMuscle: ExerciseMuscle?

    @State private var openedExercise: ExerciseDefinition?

    var body: some View {
        BrightPageSheetView(
            title: onSelect == nil ? "Exercises" : "Add exercise",
            horizontalPadding: .spacing0x
        ) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .spacing3x) {
                    BrightSearchBar("Search exercises", text: $searchText)
                        .padding(.horizontal, .spacing3x)

                    filters

                    BrightText("\(filtered.count) exercises", size: .body3, color: .lightTextColor)
                        .monospacedDigit()
                        .padding(.horizontal, .spacing3x)

                    ForEach(groupedMuscles, id: \.self) { muscle in
                        section(for: muscle)
                            .padding(.horizontal, .spacing3x)
                    }
                }
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing4x)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                ExerciseInlineTitle(title: onSelect == nil ? "Exercises" : "Add exercise", file: #file)
            }
        }
        .sheet(item: $openedExercise) { exercise in
            BrightPageSheetView(title: exercise.name, horizontalPadding: .spacing0x) {
                ExerciseDetailSheet(exercise: exercise)
            }
        }
        .animation(.brightEaseInOut, value: filtered.count)
    }

    // MARK: - Content

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacing1x) {
                ForEach(ExerciseMuscle.allCases) { muscle in
                    BrightTag(title: muscle.displayName, isSelected: selectedMuscle == muscle) {
                        withAnimation(.brightSnappy) {
                            selectedMuscle = selectedMuscle == muscle ? nil : muscle
                        }
                    }
                }
                ForEach(ExerciseEquipment.allCases) { equipment in
                    BrightTag(title: equipment.displayName, isSelected: selectedEquipment == equipment) {
                        withAnimation(.brightSnappy) {
                            selectedEquipment = selectedEquipment == equipment ? nil : equipment
                        }
                    }
                }
            }
            .padding(.horizontal, .spacing3x)
        }
        .scrollClipDisabled()
    }

    private func section(for muscle: ExerciseMuscle) -> some View {
        let exercises = filtered.filter { $0.primaryMuscle == muscle }
        return VStack(alignment: .leading, spacing: .spacing105x) {
            BrightText(muscle.displayName, size: .body1)
                .padding(.leading, .spacing1x)

            VStack(spacing: .spacing0x) {
                ForEach(exercises) { exercise in
                    row(exercise)

                    if exercise.id != exercises.last?.id {
                        Rectangle()
                            .fill(Color.textColor.opacity(.ultraLowOpacity))
                            .frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, .spacing3x)
            .padding(.vertical, .spacing1x)
            .modifier(CardModifier(color: .defaultSheetModalCards))
        }
    }

    private func row(_ exercise: ExerciseDefinition) -> some View {
        Button {
            if let onSelect {
                onSelect(exercise)
                dismiss()
            } else {
                openedExercise = exercise
            }
        } label: {
            HStack(spacing: .spacing2x) {
                Image(systemName: exercise.symbol)
                    .font(.standard(size: .subheading2, weight: .light))
                    .foregroundStyle(Color.lightTextColor)
                    .frame(width: Constants.iconWidth)

                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(exercise.name, size: .body2, color: .semiLightTextColor, weight: .regular)
                    BrightText(exercise.equipmentLabel, size: .body3, color: .lightTextColor)
                }

                Spacer(minLength: .spacing2x)

                Image(systemName: onSelect == nil ? "chevron.right" : "plus")
                    .font(.standard(size: .body5, weight: .regular))
                    .foregroundStyle(Color.lightTextColor)
            }
            .padding(.vertical, .spacing105x)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Derived state

    private var filtered: [ExerciseDefinition] {
        ExerciseDemoLibrary.all.filter { exercise in
            (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText))
                && (selectedEquipment == nil || exercise.equipment == selectedEquipment)
                && (selectedMuscle == nil || exercise.primaryMuscle == selectedMuscle
                    || exercise.secondaryMuscles.contains(selectedMuscle!))
        }
    }

    private var groupedMuscles: [ExerciseMuscle] {
        ExerciseMuscle.allCases.filter { muscle in
            filtered.contains { $0.primaryMuscle == muscle }
        }
    }

    private enum Constants {
        static let iconWidth: CGFloat = 28
    }
}

#Preview {
    ExerciseLibrarySheet()
}

#Preview("Picker") {
    ExerciseLibrarySheet { _ in }
}
