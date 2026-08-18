//
//  ExerciseCreateWorkoutSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

private struct ExerciseSwapTarget: Identifiable {
    let id: String
}

struct ExerciseCreateWorkoutSheet: View {
    // The saved workout being edited, or nil when building a new one.
    let editing: ExerciseQuickWorkout?

    let onSave: () -> Void

    @Environment(ExerciseBuilder.self) private var builder

    @FocusState private var isTyping: Bool

    @State private var name: String

    @State private var symbol: ExerciseWorkoutIcon

    @State private var swapTarget: ExerciseSwapTarget?

    @State private var isAddingExercise = false

    @State private var addedExercise: String?

    @State private var nameNudge = 0

    // The draft as it looked on arrival, so Save can tell edits from a no-op.
    @State private var baselineDraft: String?


    // Mirrors the set row's own scaling so the headers stay over their columns
    // and the list's height matches the rows it holds.
    @ScaledMetric(relativeTo: .body) private var rowHeight = ExerciseSetRow.Constants.rowHeight

    @ScaledMetric(relativeTo: .body) private var fieldWidth = ExerciseSetRow.Constants.fieldWidth

    @ScaledMetric(relativeTo: .body) private var fieldGap = ExerciseSetRow.Constants.fieldGap

    init(editing: ExerciseQuickWorkout? = nil, onSave: @escaping () -> Void) {
        self.editing = editing
        self.onSave = onSave
        _name = State(initialValue: editing?.name ?? "")
        if let editing, let icon = ExerciseWorkoutIcon.matching(editing) {
            _symbol = State(initialValue: icon)
        } else {
            _symbol = State(initialValue: ExerciseWorkoutIcon.strength[0])
        }
    }

    var body: some View {
        BrightPageView(
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultSheetBackground,
            toolbar: {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: title, file: #file)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(saveTitle, action: save)
                        .buttonStyle(.borderedProminent)
                        .tint(canSave ? .defaultSkyBlue : .defaultMainGrey)
                        .id(canSave)
                }
            },
            content: {
                ScrollViewReader { scroller in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: .spacing3x) {
                            nameField

                            ExerciseIconPicker(
                                icons: ExerciseWorkoutIcon.strength,
                                selection: $symbol
                            )

                            ForEach(builder.added, id: \.self) { exercise in
                                exerciseCard(exercise)
                            }
                        }
                        .padding(.spacing3x)
                    }
                    .safeAreaInset(edge: .bottom) {
                        addExerciseButton
                    }
                    .onChange(of: addedExercise) { _, exercise in
                        guard let exercise else { return }
                        withAnimation(.brightEaseInOut) { scroller.scrollTo(exercise, anchor: .top) }
                        addedExercise = nil
                    }
                }
            }
        )
        .sheet(item: $swapTarget) { target in
            NavigationStack {
                ExerciseCategorySheet(category: .gym, showCloseButton: true) { replacement in
                    builder.replace(target.id, with: replacement.name)
                }
            }
        }
        .sheet(isPresented: $isAddingExercise) {
            NavigationStack {
                ExerciseCategorySheet(category: .gym, showCloseButton: true) { exercise in
                    builder.add(exercise.name)
                    addedExercise = exercise.name
                }
            }
        }
        .onAppear {
            // The builder is already loaded by the time we arrive, so the first
            // signature is the untouched workout.
            if baselineDraft == nil { baselineDraft = draftSignature }
        }
    }

    // MARK: - Content

    private var nameField: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            TextField("Workout name", text: $name)
                .focused($isTyping)
                .font(.standard(size: .standout28, weight: .regular))
                .foregroundStyle(Color.textColor)
                .brightWiggle(trigger: nameNudge)

            BrightText("\(builder.count) exercise\(builder.count == 1 ? "" : "s")", size: .body1, color: .semiLightTextColor)
        }
    }

    private func exerciseCard(_ exercise: String) -> some View {
        VStack(spacing: .spacing3x) {
            cardHeader(exercise)
                .padding(.horizontal, .spacing3x)

            columnHeaders
                .padding(.horizontal, .spacing2x)
                .padding(.horizontal, .spacing3x)

            setsList(exercise)

            cardFooter(exercise)
                .padding(.horizontal, .spacing3x)
        }
        .padding(.vertical, .spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private func cardHeader(_ exercise: String) -> some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.standard(size: .body2, weight: .medium))
                .foregroundStyle(Color.textColor)

            BrightText(exercise, size: .body2, color: .semiLightTextColor, weight: .regular)

            Spacer(minLength: .spacing2x)

            Menu {
                Button("Move up", systemImage: "arrow.up") {
                    builder.moveUp(exercise)
                }
                Button("Swap out exercise", systemImage: "rectangle.2.swap") {
                    swapTarget = ExerciseSwapTarget(id: exercise)
                }
                Button("Remove exercise", systemImage: "trash", role: .destructive) {
                    builder.remove(exercise)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.standard(size: .standout4, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)
            }
        }
    }

    private var addExerciseButton: some View {
        BrightRoundButton(systemImage: "plus", size: .finalBossLarge) {
            isAddingExercise = true
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.spacing3x)
    }

    private func cardFooter(_ exercise: String) -> some View {
        HStack(spacing: .spacing2x) {
            BrightText(volumeLabel(for: exercise), size: .body2, color: .textColor.opacity(.veryLowOpacity))

            Spacer(minLength: .spacing2x)

            ShareLink(item: builder.exportText(for: exercise)) {
                BrightRoundButton(systemImage: "link")
                    .allowsHitTesting(false)
            }

            BrightRoundButton(systemImage: "plus") {
                withAnimation(.brightSnappy) { builder.addSet(to: exercise) }
            }
        }
    }

    private var columnHeaders: some View {
        HStack(spacing: fieldGap) {
            Spacer(minLength: .spacing0x)

            ForEach(Constants.columnTitles, id: \.self) { title in
                BrightText(title, size: .body2, color: .semiLightTextColor, weight: .regular)
                    .multilineTextAlignment(.center)
                    .frame(width: fieldWidth)
            }
        }
    }

    private func setsList(_ exercise: String) -> some View {
        let drafts = builder.sets[exercise] ?? []
        return List {
            ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
                ExerciseSetRow(
                    kind: draft.kind,
                    isTinted: index.isMultiple(of: 2),
                    weight: builder.binding(for: draft.id, in: exercise, keyPath: \.weight),
                    reps: builder.binding(for: draft.id, in: exercise, keyPath: \.reps),
                    rest: builder.binding(for: draft.id, in: exercise, keyPath: \.rest),
                    isTyping: $isTyping,
                    onPickKind: { kind in
                        withAnimation(.brightSnappy) { builder.setKind(kind, of: draft.id, in: exercise) }
                    }
                )
                .listRowInsets(EdgeInsets(top: 0, leading: .spacing3x, bottom: 0, trailing: .spacing3x))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        withAnimation(.brightSnappy) { builder.removeSet(draft.id, from: exercise) }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.defaultRed)
                }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(.spacing0x)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .contentMargins(.vertical, .spacing0x, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, rowHeight)
        .frame(height: rowHeight * CGFloat(drafts.count))
        .animation(.brightSnappy, value: drafts.count)
    }

    // MARK: - Actions

    private func save() {
        guard !isNameEmpty else {
            nameNudge += 1
            return
        }
        if let editing {
            builder.update(editing, named: name, icon: symbol)
        } else {
            builder.save(named: name, icon: symbol)
        }
        onSave()
    }

    // MARK: - Derived state

    private var isNameEmpty: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // A new workout is created; an existing one is saved back.
    private var saveTitle: String {
        editing == nil ? "Create" : "Save"
    }

    private var title: String {
        editing == nil ? "Create Workout" : "Edit Workout"
    }

    // Editing only offers Save once something actually differs; a new workout
    // just needs a name.
    private var canSave: Bool {
        guard !isNameEmpty else { return false }
        guard let editing else { return true }
        guard let baselineDraft else { return false }
        return name != editing.name
            || symbol.symbol != editing.symbol
            || draftSignature != baselineDraft
    }

    private var draftSignature: String {
        builder.added
            .map { exercise in
                let sets = (builder.sets[exercise] ?? [])
                    .map { "\($0.kind)|\($0.weight)|\($0.reps)|\($0.rest)" }
                    .joined(separator: ";")
                return "\(exercise)>\(sets)"
            }
            .joined(separator: "\n")
    }

    private func volumeLabel(for exercise: String) -> String {
        let sets = builder.sets[exercise] ?? []
        let volume = sets.reduce(into: 0.0) { total, set in
            let weight = Double(set.weight.filter { $0.isNumber || $0 == "." }) ?? 0
            let reps = Double(set.reps.filter(\.isNumber)) ?? 0
            total += weight * reps
        }
        return "\(Int(volume)) kg total"
    }

    private enum Constants {
        static let columnTitles = ["Weights", "Reps", "Rest"]
    }
}

#Preview {
    NavigationStack {
        ExerciseCreateWorkoutSheet {}
            .environment(previewBuilder)
    }
}

@MainActor private let previewBuilder: ExerciseBuilder = {
    let builder = ExerciseBuilder()
    builder.add("Bench Press")
    builder.add("Shoulder Press")
    return builder
}()
