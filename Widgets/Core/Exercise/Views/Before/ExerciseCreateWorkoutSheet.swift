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

    @Environment(ExerciseWorkoutBuilder.self) private var builder

    @FocusState private var isTyping: Bool

    @State private var name: String

    @State private var symbol: ExerciseWorkoutIcon

    @State private var swapTarget: ExerciseSwapTarget?

    @State private var isAddingExercise = false

    @State private var addedExercise: String?

    @State private var nameNudge = 0

    // The draft as it looked on arrival, so Save can tell edits from a no-op.
    @State private var baselineDraft: String?

    @Namespace private var iconPickerSpace

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
            _symbol = State(initialValue: ExerciseWorkoutIcon.allCases[0])
        }
    }

    var body: some View {
        BrightPageView(
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultSheetBackground,
            toolbar: {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: "Edit Workout", file: #file)
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

                            iconPicker

                            ForEach(builder.added, id: \.self) { exercise in
                                exerciseCard(exercise)
                            }

                            BrightPillButton("Add exercise", systemImage: "plus", buttonSize: .medium) {
                                isAddingExercise = true
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.spacing3x)
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
                ExerciseCategoryView(category: .gym) { replacement in
                    builder.replace(target.id, with: replacement.name)
                }
            }
        }
        .sheet(isPresented: $isAddingExercise) {
            NavigationStack {
                ExerciseCategoryView(category: .gym) { exercise in
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

    private var iconPicker: some View {
        HStack(spacing: Constants.iconTileGap) {
            ForEach(ExerciseWorkoutIcon.allCases) { icon in
                Image(systemName: icon.symbol)
                    .font(.standard(size: .heading, weight: .light))
                    .foregroundStyle(icon == symbol ? icon.accentColor : .semiLightTextColor)
                    .frame(width: Constants.iconTile, height: Constants.iconTile)
                    .background {
                        Circle()
                            .fill(Color.defaultMainGrey.opacity(.finalBossLowOpacity))
                    }
                    .matchedGeometryEffect(id: icon, in: iconPickerSpace)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .leading) {
            Color.clear
                .frame(width: Constants.iconTile, height: Constants.iconTile)
                .modifier(GlassEffect(shape: .circle))
                .matchedGeometryEffect(id: symbol, in: iconPickerSpace, isSource: false)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    select(at: value.location.x)
                }
        )
        .brightHaptic(.light, trigger: symbol)
        .animation(.brightSnappy, value: symbol)
    }

    // One gesture drives both tap and drag, so the glass follows the finger
    // across the row instead of jumping between taps.
    private func select(at x: CGFloat) {
        let icons = ExerciseWorkoutIcon.allCases
        let slot = Constants.iconTile + Constants.iconTileGap
        let index = min(max(0, Int(x / slot)), icons.count - 1)
        guard icons[index] != symbol else { return }
        symbol = icons[index]
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
            Image(systemName: "dumbbell.fill")
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
        static let iconTile: CGFloat = 44
        static let iconTileGap: CGFloat = .spacing2x
    }
}

#Preview {
    NavigationStack {
        ExerciseCreateWorkoutSheet {}
            .environment(previewBuilder)
    }
}

@MainActor private let previewBuilder: ExerciseWorkoutBuilder = {
    let builder = ExerciseWorkoutBuilder()
    builder.add("Bench Press")
    builder.add("Shoulder Press")
    return builder
}()
