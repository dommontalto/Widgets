//
//  ExerciseCreateSessionSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

private struct ExerciseSwapTarget: Identifiable {
    let id: String
}

private struct ExerciseProgressionTarget: Identifiable {
    let id: String
}

// One screen for whatever the session holds. The picker under the name walks
// through the exercises added to it, and each one brings its own editor: sets
// for a lift, a cardio plan for a run or a sport.
struct ExerciseCreateSessionSheet: View {
    // The saved session being edited, or nil when building a new one.
    let editing: ExerciseQuickSession?

    let onSave: () -> Void

    @Environment(ExerciseBuilder.self) private var builder

    @FocusState private var isTyping: Bool

    @State private var name: String

    @State private var selected: String?

    @State private var swapTarget: ExerciseSwapTarget?

    @State private var progressionTarget: ExerciseProgressionTarget?

    // Each lift's progression rule, kept apart from the builder because saved
    // sessions don't carry it yet.
    @State private var progressions: [String: ExerciseProgression] = [:]

    @State private var isAddingExercise = false

    @State private var isEditingSupersets = false

    @State private var isReordering = false

    @State private var nameNudge = 0

    // The session as it looked on arrival, so Save can tell edits from a no-op.
    @State private var baselineDraft: String?

    // Mirrors the set row's own scaling so the headers stay over their columns
    // and the list's height matches the rows it holds.
    @ScaledMetric(relativeTo: .body) private var rowHeight = ExerciseSetRow.Constants.rowHeight

    @ScaledMetric(relativeTo: .body) private var fieldWidth = ExerciseSetRow.Constants.fieldWidth

    @ScaledMetric(relativeTo: .body) private var fieldGap = ExerciseSetRow.Constants.fieldGap

    init(editing: ExerciseQuickSession? = nil, onSave: @escaping () -> Void) {
        self.editing = editing
        self.onSave = onSave
        _name = State(initialValue: editing?.name ?? "")
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
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: .spacing3x) {
                        nameField
                            .padding(.horizontal, .spacing3x)

                        ExerciseSessionPicker(exercises: builder.added, selection: $selected)

                        editor
                            .padding(.horizontal, .spacing3x)
                    }
                    .padding(.vertical, .spacing3x)
                }
                .safeAreaInset(edge: .bottom) {
                    addExerciseButton
                }
            }
        )
        .sheet(item: $swapTarget) { target in
            NavigationStack {
                ExerciseLibrarySheet(
                    category: ExerciseDemoLibrary.type(of: target.id),
                    showCloseButton: true,
                    included: Set(builder.added)
                ) { replacement in
                    builder.replace(target.id, with: replacement.name)
                    selected = replacement.name
                }
            }
        }
        .sheet(item: $progressionTarget) { target in
            ExerciseProgressionSheet(progression: progression(for: target.id)) { applied in
                progressions[target.id] = applied
            }
        }
        .sheet(isPresented: $isEditingSupersets) {
            ExerciseSupersetSheet(exercises: builder.draftExercises) { edited in
                withAnimation(.brightSnappy) { builder.applySupersets(edited) }
            }
        }
        .sheet(isPresented: $isReordering) {
            ExerciseReorderSheet(exercises: builder.draftExercises) { edited in
                withAnimation(.brightSnappy) { builder.applySupersets(edited) }
            }
        }
        .sheet(isPresented: $isAddingExercise) {
            NavigationStack {
                ExerciseLibrarySheet(
                    category: .gym,
                    showCloseButton: true,
                    included: Set(builder.added)
                ) { exercise in
                    withAnimation(.brightSnappy) { builder.add(exercise.name) }
                    selected = exercise.name
                }
            }
        }
        .onAppear {
            // The builder is already loaded by the time we arrive, so the first
            // signature is the untouched session.
            if baselineDraft == nil { baselineDraft = draftSignature }
            if selected == nil { selected = builder.added.first }
        }
    }

    // MARK: - Header

    private var nameField: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            TextField("Session name", text: $name)
                .focused($isTyping)
                .font(.standard(size: .standout28, weight: .regular))
                .foregroundStyle(Color.textColor)
                .brightWiggle(trigger: nameNudge)

            BrightText(builder.subtitle, size: .body1, color: .semiLightTextColor)
        }
    }

    // MARK: - Editor

    @ViewBuilder
    private var editor: some View {
        if let selected, builder.isAdded(selected) {
            if builder.isCardio(selected) {
                cardioCard(selected)
            } else {
                exerciseCard(selected)
            }
        } else {
            BrightPlaceholderView(
                systemImage: ExerciseCategory.gym.symbol,
                title: "Nothing added yet",
                subtitle: "Add exercises, runs or sports and they'll line up above.",
                buttonTitle: "Add exercise"
            ) {
                isAddingExercise = true
            }
        }
    }

    private func cardioCard(_ exercise: String) -> some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            cardHeader(exercise)

            ExerciseCardioPlanEditor(plan: builder.planBinding(for: exercise), isTyping: $isTyping)
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

    // The lit tag above already names the exercise and wears its glyph, so the
    // card carries only what you can do to it.
    private func cardHeader(_ exercise: String) -> some View {
        HStack(spacing: .spacing2x) {
            Spacer(minLength: .spacing0x)

            Menu {
                Button("Supersets", systemImage: "link") {
                    isEditingSupersets = true
                }
                Button("Reorder", systemImage: "arrow.up.arrow.down") {
                    isReordering = true
                }
                Button("Swap out exercise", systemImage: "rectangle.2.swap") {
                    swapTarget = ExerciseSwapTarget(id: exercise)
                }
                Button("Remove exercise", systemImage: "trash", role: .destructive) {
                    remove(exercise)
                }
                .tint(.defaultRed)
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
            BrightRoundButton(systemImage: "chart.line.uptrend.xyaxis") {
                progressionTarget = ExerciseProgressionTarget(id: exercise)
            }

            BrightText(progression(for: exercise).summary, size: .body2)

            Spacer(minLength: .spacing2x)

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

    // The picker moves on to whatever sat next to the exercise that left, so the
    // screen below it never goes blank while the session still holds something.
    private func remove(_ exercise: String) {
        let index = builder.added.firstIndex(of: exercise) ?? 0
        withAnimation(.brightSnappy) { builder.remove(exercise) }
        guard selected == exercise else { return }
        selected = builder.added.indices.contains(index) ? builder.added[index] : builder.added.last
    }

    private func save() {
        guard !isNameEmpty else {
            nameNudge += 1
            return
        }
        if let editing {
            builder.update(editing, named: name)
        } else {
            builder.save(named: name)
        }
        onSave()
    }

    // MARK: - Derived state

    private var isNameEmpty: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // A new session is created; an existing one is saved back.
    private var saveTitle: String {
        editing == nil ? "Create" : "Save"
    }

    private var title: String {
        editing == nil ? "Create Session" : "Edit Session"
    }

    // Editing only offers Save once something actually differs; a new session
    // needs a name and something in it.
    private var canSave: Bool {
        guard !isNameEmpty, builder.count > 0 else { return false }
        guard let editing else { return true }
        guard let baselineDraft else { return false }
        return name != editing.name || draftSignature != baselineDraft
    }

    private var draftSignature: String {
        builder.added
            .map { exercise in
                if let plan = builder.plans[exercise] { return "\(exercise)>\(plan.signature)" }
                let sets = (builder.sets[exercise] ?? [])
                    .map { "\($0.kind)|\($0.weight)|\($0.reps)|\($0.rest)" }
                    .joined(separator: ";")
                return "\(exercise)>\(sets)"
            }
            .joined(separator: "\n")
    }

    private func progression(for exercise: String) -> ExerciseProgression {
        progressions[exercise] ?? ExerciseProgression()
    }

    private enum Constants {
        static let columnTitles = ["Weights", "Reps", "Rest"]
    }
}

#Preview {
    NavigationStack {
        ExerciseCreateSessionSheet {}
            .environment(previewBuilder)
    }
}

@MainActor private let previewBuilder: ExerciseBuilder = {
    let builder = ExerciseBuilder()
    builder.add("Bench Press")
    builder.add("Shoulder Press")
    builder.add("Outdoor Run")
    return builder
}()
