//
//  ExerciseReorderSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 17/8/2026.
//

import SwiftUI

// Re-orders the exercises of a run, and adds new ones from the library. The
// order is held locally so backing out leaves the run as it was — only Save
// hands the new order back.
struct ExerciseReorderSheet: View {
    let onSave: ([ExerciseActiveExercise]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var order: [ExerciseActiveExercise]
    @State private var isAddingExercise = false

    init(
        exercises: [ExerciseActiveExercise],
        onSave: @escaping ([ExerciseActiveExercise]) -> Void
    ) {
        self.onSave = onSave
        _order = State(initialValue: exercises)
    }

    var body: some View {
        BrightPageSheetView(
            title: "Re-order exercises",
            horizontalPadding: .spacing0x,
            trailing: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(order)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.defaultSkyBlue)
                }
            },
            content: {
                exerciseList
                    .safeAreaInset(edge: .bottom) {
                        addExerciseButton
                    }
            }
        )
        .sheet(isPresented: $isAddingExercise) {
            NavigationStack {
                ExerciseCategorySheet(category: .gym, showCloseButton: true) { exercise in
                    add(exercise.name)
                }
            }
        }
    }

    // `editActions: .move` gives the rows the system's lift-and-drag straight
    // out of the box — no edit mode. The lifted preview runs wider than the card
    // it wraps, so it takes a tighter radius than the card's own.
    private var exerciseList: some View {
        List($order, editActions: .move) { $exercise in
            row(exercise)
                .contentShape(.dragPreview, RoundedRectangle(cornerRadius: .cornerRadius18, style: .continuous))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: .spacing1x,
                    leading: .spacing3x,
                    bottom: .spacing1x,
                    trailing: .spacing3x
                ))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ exercise: ExerciseActiveExercise) -> some View {
        HStack(spacing: .spacing2x) {
            HStack(spacing: .spacing2x) {
                thumbnail(for: exercise)

                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(exercise.name, size: .body2, weight: .regular)
                        .fixedSize(horizontal: false, vertical: true)

                    BrightText(setsLabel(of: exercise), size: .body3, color: .lightTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: .spacing2x)
            }
            .padding(.spacing2x)
            .frame(maxWidth: .infinity, minHeight: ExerciseLibraryRow.Constants.minHeight, alignment: .leading)
            .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))

            Image(systemName: "arrow.up.and.down.circle.fill")
                .font(.standard(size: .standout3, weight: .regular))
                .foregroundStyle(Color.defaultGreen)
        }
    }

    @ViewBuilder
    private func thumbnail(for exercise: ExerciseActiveExercise) -> some View {
        if let definition = ExerciseDemoLibrary.exercise(named: exercise.name) {
            Image(systemName: definition.category.symbol)
                .font(.standard(size: .standout4, weight: .light))
                .foregroundStyle(Color.lightTextColor)
                .frame(width: ExerciseLibraryRow.Constants.thumbnailWidth)
        } else {
            Color.clear
                .frame(width: ExerciseLibraryRow.Constants.thumbnailWidth)
        }
    }

    private var addExerciseButton: some View {
        BrightRoundButton(systemImage: "plus", size: .finalBossLarge) {
            isAddingExercise = true
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.spacing3x)
    }

    private func add(_ name: String) {
        guard !order.contains(where: { $0.name == name }) else { return }
        let item = ExerciseTemplateItem(exerciseName: name, target: "")
        withAnimation(.brightSnappy) {
            order.append(contentsOf: ExerciseActiveExercise.fromTemplate([item]))
        }
    }

    private func setsLabel(of exercise: ExerciseActiveExercise) -> String {
        let count = exercise.workingSetCount
        return "\(count) set\(count == 1 ? "" : "s")"
    }
}

#Preview {
    ExerciseReorderSheet(exercises: ExerciseDemoData.activeExercises) { _ in }
        .environment(ExerciseBuilder())
}
