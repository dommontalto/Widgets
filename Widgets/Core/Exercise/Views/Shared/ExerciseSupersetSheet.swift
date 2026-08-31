//
//  ExerciseSupersetSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 17/8/2026.
//

import SwiftUI

// Groups the exercises of a run into supersets; re-ordering lives in
// ExerciseReorderSheet. The order is held locally so backing out leaves the run
// as it was — only Save hands the new order back.
struct ExerciseSupersetSheet: View {
    private enum Constants {
        // Each superset takes the next colour along, so two groups sitting
        // beside each other never read as one.
        static let supersetColors: [Color] = [
            .defaultSkyBlue,
            .defaultRed,
            .defaultBrightGreen,
            .defaultBrightViolet,
            .defaultYellow,
            .defaultOrange,
            .defaultPink,
            .defaultSkyBlueCyan,
        ]
        static let connectorWidth: CGFloat = 3
        // Glass circle sized to the handle's glyph beside it, rather than to the
        // 44pt box that holds the handle off the edge.
        static let linkButtonSize: BrightButtonSizes = .small
        // Half the gap between two cards — each row pads by this much, so the
        // connector spans twice it.
        static let rowGap: CGFloat = .spacing1x
        static let cardCornerRadius: CGFloat = .cornerRadius18
    }

    let onSave: ([ExerciseActiveExercise]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var order: [ExerciseActiveExercise]
    @State private var linkAnchor: UUID?
    @State private var groupSlots: [UUID: Int] = [:]
    @State private var linkTick = 0
    @State private var modeTick = 0

    init(
        exercises: [ExerciseActiveExercise],
        onSave: @escaping ([ExerciseActiveExercise]) -> Void
    ) {
        self.onSave = onSave
        _order = State(initialValue: exercises)
    }

    var body: some View {
        BrightPageSheetView(
            title: "Supersets",
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
        .brightHaptic(.light, trigger: modeTick)
        .brightHaptic(.success, trigger: linkTick)
    }

    private var exerciseList: some View {
        List(order) { exercise in
            row(exercise)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                // The vertical gap is padding inside the row, not a row inset:
                // the connector between two linked cards draws into it, and a row
                // clips anything outside its own bounds.
                .listRowInsets(EdgeInsets(
                    top: .spacing0x,
                    leading: .spacing3x,
                    bottom: .spacing0x,
                    trailing: .spacing3x
                ))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        remove(exercise)
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

            linkButton(for: exercise)
                // Matches the tick on a library row: the same 44pt box holding
                // it off the card's trailing edge.
                .frame(width: ExerciseLibraryRow.Constants.tickTouchSize,
                       height: ExerciseLibraryRow.Constants.tickTouchSize)
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, minHeight: ExerciseLibraryRow.Constants.minHeight, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: Constants.cardCornerRadius))
        .overlay(alignment: .bottom) {
            connector(below: exercise)
        }
        .padding(.vertical, Constants.rowGap)
    }

    // Bridges the gap down to the next card in the same superset, so a group reads
    // as one run rather than two rows that happen to match. Only the upper card
    // draws it, so it lands in the gap and never over either card.
    @ViewBuilder
    private func connector(below exercise: ExerciseActiveExercise) -> some View {
        if let color = groupColor(of: exercise), leadsIntoNext(exercise) {
            Rectangle()
                .fill(color)
                .frame(width: Constants.connectorWidth, height: Constants.rowGap * 2)
                // A bottom-aligned overlay hangs its own bottom edge on the card's,
                // so the whole height has to shift down to clear it.
                .offset(y: Constants.rowGap * 2)
        }
    }

    private func leadsIntoNext(_ exercise: ExerciseActiveExercise) -> Bool {
        guard let group = exercise.supersetID,
              let index = order.firstIndex(where: { $0.id == exercise.id }),
              order.indices.contains(index + 1)
        else { return false }
        return order[index + 1].supersetID == group
    }

    // Picking an exercise arms it: only that row takes the pairing colour, while
    // every free row's link becomes a plain circle to tap. A row already in
    // another superset keeps its own colour and still takes the tap, moving
    // across into the armed group. The one exception is the armed exercise's own
    // superset — tapping a partner there breaks the link instead. Tapping the
    // armed row again backs out.
    @ViewBuilder
    private func linkButton(for exercise: ExerciseActiveExercise) -> some View {
        if let anchor = linkAnchor {
            if exercise.id == anchor {
                BrightRoundButton(systemImage: "link", size: Constants.linkButtonSize, imageColor: pendingColor(for: anchor)) {
                    cancelAnchor()
                }
            } else if let group = armedGroup, exercise.supersetID == group {
                BrightRoundButton(systemImage: "link", size: Constants.linkButtonSize, imageColor: groupColors[group]) {
                    unlink(exercise)
                }
            } else if let color = groupColor(of: exercise) {
                BrightRoundButton(systemImage: "link", size: Constants.linkButtonSize, imageColor: color) {
                    link(exercise, to: anchor)
                }
            } else {
                BrightRoundButton(systemImage: "circle", size: Constants.linkButtonSize, imageColor: .semiLightTextColor) {
                    link(exercise, to: anchor)
                }
            }
        } else {
            BrightRoundButton(systemImage: "link", size: Constants.linkButtonSize, imageColor: groupColor(of: exercise)) {
                withAnimation(.brightSnappy) {
                    linkAnchor = exercise.id
                    modeTick += 1
                }
            }
        }
    }

    @ViewBuilder
    private func thumbnail(for exercise: ExerciseActiveExercise) -> some View {
        if let definition = ExerciseDemoLibrary.exercise(named: exercise.name) {
            Image(systemName: definition.symbol)
                .font(.standard(size: .standout3, weight: .light))
                .foregroundStyle(Color.lightTextColor)
                .frame(width: ExerciseLibraryRow.Constants.thumbnailWidth)
        } else {
            Color.clear
                .frame(width: ExerciseLibraryRow.Constants.thumbnailWidth)
        }
    }

    // MARK: - Supersets

    // A group holds its palette slot for as long as it lives, so an existing
    // superset never changes colour because another one appeared or dissolved.
    private var liveGroups: [UUID] {
        Set(order.compactMap(\.supersetID)).sorted { slot(of: $0) < slot(of: $1) }
    }

    private var groupColors: [UUID: Color] {
        var colors: [UUID: Color] = [:]
        for group in liveGroups {
            colors[group] = Constants.supersetColors[slot(of: group) % Constants.supersetColors.count]
        }
        return colors
    }

    private func slot(of group: UUID) -> Int {
        groupSlots[group] ?? 0
    }

    // The lowest slot no live group is wearing — what a fresh superset takes, and
    // what the armed row already shows as its pairing colour.
    private var nextSlot: Int {
        let taken = Set(liveGroups.map { slot(of: $0) })
        var candidate = 0
        while taken.contains(candidate) { candidate += 1 }
        return candidate
    }

    private func groupColor(of exercise: ExerciseActiveExercise) -> Color? {
        guard let group = exercise.supersetID else { return nil }
        return groupColors[group]
    }

    // The superset the armed exercise belongs to, if it's in one — that's what
    // separates the unlink half of the gesture from the link half.
    private var armedGroup: UUID? {
        guard let linkAnchor else { return nil }
        return order.first { $0.id == linkAnchor }?.supersetID
    }

    // The colour the pair is about to take: an existing group keeps its own, a
    // fresh one takes the next free colour — and keeps it even when the target it
    // pulls in leaves a group behind.
    private func pendingColor(for anchorID: UUID) -> Color {
        if let group = order.first(where: { $0.id == anchorID })?.supersetID,
           let color = groupColors[group] {
            return color
        }
        return Constants.supersetColors[nextSlot % Constants.supersetColors.count]
    }

    private func cancelAnchor() {
        withAnimation(.brightSnappy) {
            linkAnchor = nil
            modeTick += 1
        }
    }

    // A target already in another superset moves across to the anchor's — the
    // group the gesture started from wins the colour.
    private func link(_ target: ExerciseActiveExercise, to anchorID: UUID) {
        guard target.id != anchorID,
              let anchorIndex = order.firstIndex(where: { $0.id == anchorID }),
              let targetIndex = order.firstIndex(where: { $0.id == target.id })
        else { return }

        // Every state this touches — the slot the new group claims, the order, the
        // armed row — changes inside the one transaction. A stray unanimated
        // update in the same tick merges with this one and strips the animation
        // off the list's move.
        withAnimation(.brightSnappy) {
            let group = order[anchorIndex].supersetID ?? newGroup()
            let vacated = order[targetIndex].supersetID

            // Whichever of the two already sits higher stays where it is and the
            // other slots in beneath it, so linking never flips the pair around.
            let upper = min(anchorIndex, targetIndex)
            let lower = max(anchorIndex, targetIndex)

            var updated = order
            updated[upper].supersetID = group
            updated[lower].supersetID = group

            // Slots in under the last exercise already in the group, so a third
            // link makes a giant set rather than splitting the pair. A move keeps
            // the row identity, so the list slides it up instead of swapping one
            // cell out for another.
            var insertion = upper + 1
            while insertion < lower, updated[insertion].supersetID == group {
                insertion += 1
            }
            if insertion != lower {
                updated.move(fromOffsets: IndexSet(integer: lower), toOffset: insertion)
            }

            order = updated
            if let vacated, vacated != group {
                clearGroup(vacated, exceptFor: nil)
            }

            linkAnchor = nil
            linkTick += 1
        }
    }

    private func newGroup() -> UUID {
        let group = UUID()
        groupSlots[group] = nextSlot
        return group
    }

    private func unlink(_ exercise: ExerciseActiveExercise) {
        guard let group = exercise.supersetID else { return }
        withAnimation(.brightSnappy) {
            clearGroup(group, exceptFor: exercise.id)
            linkAnchor = nil
            modeTick += 1
        }
    }

    private func remove(_ exercise: ExerciseActiveExercise) {
        withAnimation(.brightSnappy) {
            order.removeAll { $0.id == exercise.id }
            if let group = exercise.supersetID {
                clearGroup(group, exceptFor: nil)
            }
            if linkAnchor == exercise.id { linkAnchor = nil }
        }
    }

    // Drops `id` out of the group, and the group itself once a lone exercise is
    // all that's left of it.
    private func clearGroup(_ group: UUID, exceptFor id: UUID?) {
        if let id, let index = order.firstIndex(where: { $0.id == id }) {
            order[index].supersetID = nil
        }
        let remaining = order.indices.filter { order[$0].supersetID == group }
        if remaining.count == 1, let last = remaining.first {
            order[last].supersetID = nil
        }
        groupSlots = groupSlots.filter { group, _ in order.contains { $0.supersetID == group } }
    }

    private func setsLabel(of exercise: ExerciseActiveExercise) -> String {
        let count = exercise.workingSetCount
        return "\(count) set\(count == 1 ? "" : "s")"
    }
}

#Preview {
    ExerciseSupersetSheet(exercises: ExerciseDemoData.activeExercises) { _ in }
        .environment(ExerciseBuilder())
}
