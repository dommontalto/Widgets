//
//  ExerciseReorderSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 22/8/2026.
//

import SwiftUI

// Re-orders a run's exercises with the system's lift-and-drag. The order is
// held locally so backing out leaves the run as it was — only Save hands the
// new order back.
struct ExerciseReorderSheet: View {
    private enum Constants {
        static let cardCornerRadius: CGFloat = .cornerRadius18
        // Half the gap between two cards — each row carries this much top and
        // bottom, matching the superset sheet's rhythm.
        static let rowGap: CGFloat = .spacing1x
    }

    let onSave: ([ExerciseActiveExercise]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var order: [ExerciseActiveExercise]

    init(
        exercises: [ExerciseActiveExercise],
        onSave: @escaping ([ExerciseActiveExercise]) -> Void
    ) {
        self.onSave = onSave
        _order = State(initialValue: exercises)
    }

    var body: some View {
        BrightPageSheetView(
            title: "Reorder",
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
            }
        )
    }

    // `editActions: .move` gives the rows the system's lift-and-drag straight
    // out of the box — no edit mode.
    private var exerciseList: some View {
        List($order, editActions: .move) { $exercise in
            row($exercise.wrappedValue)
                // Same placement as the Bright app's customise-menu list: the
                // preview shape sits on the row, outside the card, and states a
                // plain rounded rect — a `.continuous` style here gets swapped
                // for the system's own platter rounding.
                .contentShape(.dragPreview, RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: Constants.rowGap,
                    leading: .spacing3x,
                    bottom: Constants.rowGap,
                    trailing: .spacing3x
                ))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        remove($exercise.wrappedValue)
                    } label: {
                        Image(systemName: "trash")
                    }
                    // The Bright app tints its whole TabView, which outranks the
                    // destructive role's red on a swipe action.
                    .tint(.defaultRed)
                }
        }
        .listStyle(.plain)
        .listRowSpacing(.spacing0x)
        .scrollContentBackground(.hidden)
    }

    private func row(_ exercise: ExerciseActiveExercise) -> some View {
        HStack(spacing: .spacing2x) {
            thumbnail(for: exercise)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(exercise.name, size: .body2, weight: .regular)
                    .fixedSize(horizontal: false, vertical: true)

                BrightText(setsLabel(of: exercise), size: .body3, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: .spacing2x)

            // Matches the tick on a library row: same glyph size, and the same
            // 44pt box holding it off the card's trailing edge.
            Image(systemName: "arrow.up.and.down.circle.fill")
                .font(.standard(size: .standout2, weight: .light))
                .foregroundStyle(Color.defaultGreen)
                .frame(width: ExerciseLibraryRow.Constants.tickTouchSize,
                       height: ExerciseLibraryRow.Constants.tickTouchSize)
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, minHeight: ExerciseLibraryRow.Constants.minHeight, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: Constants.cardCornerRadius))
    }

    @ViewBuilder
    private func thumbnail(for exercise: ExerciseActiveExercise) -> some View {
        if let definition = ExerciseDemoLibrary.exercise(named: exercise.name) {
            Image(systemName: definition.symbol)
                .font(.standard(size: .standout4, weight: .light))
                .foregroundStyle(Color.lightTextColor)
                .frame(width: ExerciseLibraryRow.Constants.thumbnailWidth)
        } else {
            Color.clear
                .frame(width: ExerciseLibraryRow.Constants.thumbnailWidth)
        }
    }

    private func remove(_ exercise: ExerciseActiveExercise) {
        withAnimation(.brightSnappy) {
            order.removeAll { $0.id == exercise.id }
            clearLoneSupersets()
        }
    }

    // A superset can't survive with one member left in it, and this sheet has
    // no group UI to show one — so a removal that strands a partner also frees
    // it.
    private func clearLoneSupersets() {
        let counts = order.compactMap(\.supersetID).reduce(into: [UUID: Int]()) { map, group in
            map[group, default: 0] += 1
        }
        for index in order.indices where counts[order[index].supersetID ?? UUID()] == 1 {
            order[index].supersetID = nil
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
