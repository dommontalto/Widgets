//
//  ExerciseBuilder.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

enum ExerciseSetKind: Hashable {
    case warmUp
    case working(Int)
    case dropSet

    var symbol: String? {
        switch self {
        case .warmUp: "figure.cooldown"
        case .working: nil
        case .dropSet: "arrow.down"
        }
    }

    var label: String? {
        if case let .working(index) = self { return "\(index)" }
        return nil
    }

    var isWorking: Bool {
        if case .working = self { return true }
        return false
    }

    // Warm-ups sit outside the set count; working and drop sets take a number.
    var countsAsSet: Bool {
        self != .warmUp
    }

    var color: Color {
        switch self {
        case .warmUp: .defaultGreen
        case .working: .defaultOrange
        case .dropSet: .defaultBrightPink
        }
    }

    // Working carries its number, so the menu offers an unnumbered one and lets
    // the renumbering settle it.
    static let pickable: [ExerciseSetKind] = [.working(0), .warmUp, .dropSet]

    var pickerLabel: String {
        switch self {
        case .warmUp: "Warm-up set"
        case .working: "Working set"
        case .dropSet: "Drop set"
        }
    }

    var pickerSymbol: String {
        switch self {
        case .warmUp: "figure.cooldown"
        case .working: "number"
        case .dropSet: "arrow.down"
        }
    }
}

enum ExerciseWorkoutIcon: String, CaseIterable, Identifiable {
    case dumbbell
    case barbell
    case functional
    case core
    case mobility
    case yoga

    case run
    case ride
    case swim
    case row
    case hike
    case jumpRope

    var id: String { rawValue }

    // Which picker the icon belongs to — and, for a saved workout, whether it
    // routes to the live cardio screen instead of the set-by-set one.
    static let strength: [ExerciseWorkoutIcon] = [.dumbbell, .barbell, .functional, .core, .mobility, .yoga]

    static let cardio: [ExerciseWorkoutIcon] = [.run, .ride, .swim, .row, .hike, .jumpRope]

    var isCardio: Bool { ExerciseWorkoutIcon.cardio.contains(self) }

    var symbol: String {
        switch self {
        case .dumbbell: "dumbbell"
        case .barbell: "figure.strengthtraining.traditional"
        case .functional: "figure.strengthtraining.functional"
        case .core: "figure.core.training"
        case .mobility: "figure.cooldown"
        case .yoga: "figure.yoga"
        case .run: "figure.run"
        case .ride: "figure.outdoor.cycle"
        case .swim: "figure.pool.swim"
        case .row: "figure.outdoor.rowing"
        case .hike: "figure.hiking"
        case .jumpRope: "figure.jumprope"
        }
    }

    var accentColor: Color {
        isCardio ? .defaultSkyBlue : .defaultPurple
    }

    static func matching(_ workout: ExerciseQuickWorkout) -> ExerciseWorkoutIcon? {
        allCases.first { $0.symbol == workout.symbol }
    }
}

struct ExerciseSetDraft: Identifiable, Hashable {
    let id = UUID()
    var kind: ExerciseSetKind
    var weight: String
    var reps: String
    var rest: String
}

@MainActor @Observable
final class ExerciseBuilder {
    var added: [String] = []
    var sets: [String: [ExerciseSetDraft]] = [:]
    var saved: [ExerciseQuickWorkout] = ExerciseDemoWorkouts.all
    var path = NavigationPath()

    var count: Int { added.count }

    func savedWorkouts(cardio: Bool) -> [ExerciseQuickWorkout] {
        saved.filter { $0.isCardio == cardio }
    }

    func isAdded(_ name: String) -> Bool {
        added.contains(name)
    }

    func add(_ name: String) {
        guard !isAdded(name) else { return }
        added.append(name)
        sets[name] = ExerciseBuilder.defaultSets
    }

    func toggle(_ name: String) {
        if isAdded(name) {
            remove(name)
        } else {
            add(name)
        }
    }

    func remove(_ name: String) {
        added.removeAll { $0 == name }
        sets[name] = nil
    }

    func moveUp(_ name: String) {
        guard let index = added.firstIndex(of: name), index > 0 else { return }
        added.swapAt(index, index - 1)
    }

    func reset() {
        added.removeAll()
        sets.removeAll()
    }

    func delete(_ workout: ExerciseQuickWorkout) {
        saved.removeAll { $0.id == workout.id }
    }

    func duplicate(_ workout: ExerciseQuickWorkout) {
        let copy = ExerciseQuickWorkout(
            name: uniqueName(from: workout.name),
            symbol: workout.symbol,
            accentColor: workout.accentColor,
            subtitle: workout.subtitle,
            isCardio: workout.isCardio,
            items: workout.items
        )
        if let index = saved.firstIndex(where: { $0.id == workout.id }) {
            saved.insert(copy, at: index + 1)
        } else {
            saved.append(copy)
        }
    }

    // Pulls a saved workout back into the draft so the create screen can edit it.
    // Template sets carry no rest interval, so they take the default.
    func loadDraft(from workout: ExerciseQuickWorkout) {
        reset()
        for item in workout.items {
            guard !isAdded(item.exerciseName) else { continue }
            added.append(item.exerciseName)
            sets[item.exerciseName] = item.sets.isEmpty
                ? ExerciseBuilder.defaultSets
                : renumbered(item.sets.map { set in
                    ExerciseSetDraft(
                        kind: set.kind,
                        weight: set.weight,
                        reps: set.reps,
                        rest: ExerciseBuilder.defaultRest
                    )
                })
        }
    }

    func update(
        _ workout: ExerciseQuickWorkout,
        named name: String,
        icon: ExerciseWorkoutIcon,
        subtitle cardioPlan: String? = nil
    ) {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              let index = saved.firstIndex(where: { $0.id == workout.id })
        else { return }
        // Cardio workouts have no exercises to edit, so an empty draft means the
        // name and icon changed and the original plan stands.
        saved[index] = ExerciseQuickWorkout(
            name: title,
            symbol: icon.symbol,
            accentColor: icon.accentColor,
            subtitle: cardioPlan ?? (added.isEmpty ? workout.subtitle : subtitle),
            isCardio: icon.isCardio,
            items: added.isEmpty ? workout.items : templateItems
        )
        reset()
    }

    // Folds a finished run back into the workout it started from, so the sets
    // and exercises added along the way are there next time.
    func updateItems(of workoutID: String, to items: [ExerciseTemplateItem]) {
        guard let index = saved.firstIndex(where: { $0.id == workoutID }) else { return }
        var workout = saved[index]
        workout.items = items
        saved[index] = workout
    }

    private func uniqueName(from name: String) -> String {
        let taken = Set(saved.map(\.name))
        guard taken.contains(name) else { return name }
        var candidate = "\(name) Copy"
        var suffix = 2
        while taken.contains(candidate) {
            candidate = "\(name) Copy \(suffix)"
            suffix += 1
        }
        return candidate
    }

    // Cardio carries its plan in the subtitle, e.g. "5 km • 4 intervals"; a gym
    // workout counts its exercises instead.
    func save(named name: String, icon: ExerciseWorkoutIcon = .dumbbell, subtitle cardioPlan: String? = nil) {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // A cardio workout is the run itself, so it saves with no exercises.
        guard !title.isEmpty, icon.isCardio || !added.isEmpty else { return }
        saved.append(
            ExerciseQuickWorkout(
                name: title,
                symbol: icon.symbol,
                accentColor: icon.accentColor,
                subtitle: icon.isCardio
                    ? (cardioPlan ?? ExerciseBuilder.cardioSubtitle)
                    : subtitle,
                isCardio: icon.isCardio,
                items: templateItems
            )
        )
        reset()
    }

    private static let cardioSubtitle = "Cardio"

    private var subtitle: String {
        "\(added.count) exercise\(added.count == 1 ? "" : "s")"
    }

    private var templateItems: [ExerciseTemplateItem] {
        added.map { exercise in
            ExerciseTemplateItem(
                exerciseName: exercise,
                target: target(for: exercise),
                sets: (sets[exercise] ?? []).map { draft in
                    ExerciseTemplateSet(
                        weight: draft.weight.filter { $0.isNumber || $0 == "." },
                        reps: draft.reps.filter(\.isNumber),
                        kind: draft.kind
                    )
                }
            )
        }
    }

    // Plain-text export of the workout, for sharing out of the sets editor.
    func exportText(for exercise: String) -> String {
        let drafts = sets[exercise] ?? []
        let rows = drafts.map { draft in
            let label = draft.kind.label ?? (draft.kind == .warmUp ? "Warm up" : "Cool down")
            return "\(label)\t\(draft.weight)\t\(draft.reps) reps\trest \(draft.rest)"
        }
        return ([exercise, "Set\tWeight\tReps\tRest"] + rows).joined(separator: "\n")
    }

    private func target(for exercise: String) -> String {
        let working = (sets[exercise] ?? []).filter {
            if case .working = $0.kind { return true }
            return false
        }
        guard let first = working.first else { return "\(working.count) sets" }
        return "\(working.count) \u{00D7} \(first.reps)"
    }

    func removeSet(_ id: UUID, from exercise: String) {
        guard var drafts = sets[exercise] else { return }
        drafts.removeAll { $0.id == id }
        sets[exercise] = renumbered(drafts)
    }

    func binding(for id: UUID, in exercise: String, keyPath: WritableKeyPath<ExerciseSetDraft, String>) -> Binding<String> {
        Binding(
            get: { [weak self] in
                guard let draft = self?.sets[exercise]?.first(where: { $0.id == id }) else { return "" }
                return draft[keyPath: keyPath]
            },
            set: { [weak self] value in
                guard let index = self?.sets[exercise]?.firstIndex(where: { $0.id == id }) else { return }
                self?.sets[exercise]?[index][keyPath: keyPath] = value
            }
        )
    }

    func replace(_ exercise: String, with replacement: String) {
        guard let index = added.firstIndex(of: exercise), !isAdded(replacement) else { return }
        added[index] = replacement
        sets[replacement] = sets[exercise]
        sets[exercise] = nil
    }

    // Warm-up and drop sets go back to working sets. A working set becomes a
    // warm-up when it extends the leading warm-up block, and a drop set anywhere
    // else — warm-ups are always contiguous and always first.
    func setKind(_ kind: ExerciseSetKind, of id: UUID, in exercise: String) {
        guard var drafts = sets[exercise],
              let index = drafts.firstIndex(where: { $0.id == id }) else { return }

        drafts[index].kind = kind
        sets[exercise] = renumbered(drafts)
    }

    private func renumbered(_ drafts: [ExerciseSetDraft]) -> [ExerciseSetDraft] {
        var renumbered = drafts
        var working = 0
        for index in renumbered.indices where renumbered[index].kind.isWorking {
            working += 1
            renumbered[index].kind = .working(working)
        }
        return renumbered
    }

    func addSet(to exercise: String) {
        let working = (sets[exercise] ?? []).filter {
            if case .working = $0.kind { return true }
            return false
        }
        let draft = ExerciseSetDraft(kind: .working(working.count + 1), weight: "10 kg", reps: "5", rest: "1:00")
        guard let dropSetIndex = sets[exercise]?.firstIndex(where: { $0.kind == .dropSet }) else {
            sets[exercise, default: []].append(draft)
            return
        }
        sets[exercise]?.insert(draft, at: dropSetIndex)
    }

    static let defaultRest = "1:00"

    private static let defaultSets: [ExerciseSetDraft] = [
        ExerciseSetDraft(kind: .warmUp, weight: "10 kg", reps: "5", rest: "1:00"),
        ExerciseSetDraft(kind: .working(1), weight: "10 kg", reps: "5", rest: "1:00"),
        ExerciseSetDraft(kind: .working(2), weight: "10 kg", reps: "5", rest: "1:00"),
        ExerciseSetDraft(kind: .working(3), weight: "10 kg", reps: "5", rest: "1:00"),
        ExerciseSetDraft(kind: .dropSet, weight: "10 kg", reps: "5", rest: "1:00"),
    ]
}
