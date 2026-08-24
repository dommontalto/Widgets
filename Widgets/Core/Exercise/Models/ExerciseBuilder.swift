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

struct ExerciseSetDraft: Identifiable, Hashable {
    let id = UUID()
    var kind: ExerciseSetKind
    var weight: String
    var reps: String
    var rest: String
}

// Where a session records, decided once at its first setup screen. The watch
// option is part 3, with the watch app.
enum ExerciseSessionSource: String, CaseIterable, Identifiable {
    case phone
    case phoneAndWatch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .phone: "iPhone"
        case .phoneAndWatch: "iPhone + Watch"
        }
    }

    var symbols: [String] {
        switch self {
        case .phone: ["iphone"]
        case .phoneAndWatch: ["iphone", "applewatch"]
        }
    }
}

@MainActor @Observable
final class ExerciseBuilder {
    var added: [String] = []

    // Where the session records, chosen once and shown on every leg's setup
    // screen. Each leg reads it as it starts, so a mid-session change applies
    // from the next leg.
    var source: ExerciseSessionSource = .phone

    // Which exercises are supersetted together, keyed by name. Exercises sharing
    // an ID run as one block.
    var supersets: [String: UUID] = [:]
    var sets: [String: [ExerciseSetDraft]] = [:]
    // What each run or sport in the draft is chasing, keyed the way sets are.
    var plans: [String: ExerciseCardioPlan] = [:]
    var saved: [ExerciseQuickSession] = ExerciseDemoSessions.all
    var path = NavigationPath()

    var count: Int { added.count }

    func isAdded(_ name: String) -> Bool {
        added.contains(name)
    }

    // Which half of the create screen an exercise gets: gym and bodyweight are
    // logged set by set, cardio and sports run against a plan.
    func isCardio(_ name: String) -> Bool {
        ExerciseDemoLibrary.isCardio(name)
    }

    func add(_ name: String) {
        guard !isAdded(name) else { return }
        added.append(name)
        if isCardio(name) {
            plans[name] = ExerciseCardioPlan()
        } else {
            sets[name] = ExerciseBuilder.defaultSets
        }
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
        plans[name] = nil
    }

    func reset() {
        added.removeAll()
        sets.removeAll()
        plans.removeAll()
    }

    func delete(_ session: ExerciseQuickSession) {
        saved.removeAll { $0.id == session.id }
    }

    func duplicate(_ session: ExerciseQuickSession) {
        let copy = ExerciseQuickSession(
            name: uniqueName(from: session.name),
            subtitle: session.subtitle,
            items: session.items
        )
        if let index = saved.firstIndex(where: { $0.id == session.id }) {
            saved.insert(copy, at: index + 1)
        } else {
            saved.append(copy)
        }
    }

    // Pulls a saved session back into the draft so the create screen can edit it.
    // Template sets carry no rest interval, so they take the default.
    func loadDraft(from session: ExerciseQuickSession) {
        reset()
        for item in session.items {
            guard !isAdded(item.exerciseName) else { continue }
            added.append(item.exerciseName)
            guard !isCardio(item.exerciseName) else {
                plans[item.exerciseName] = item.plan ?? ExerciseCardioPlan()
                continue
            }
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

    func update(_ session: ExerciseQuickSession, named name: String) {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              let index = saved.firstIndex(where: { $0.id == session.id })
        else { return }
        // An empty draft means only the name changed, so the session keeps what
        // it already held.
        saved[index] = ExerciseQuickSession(
            name: title,
            subtitle: added.isEmpty ? session.subtitle : subtitle,
            items: added.isEmpty ? session.items : templateItems
        )
        reset()
    }

    // Folds a finished run back into the session it started from, so the sets
    // and exercises added along the way are there next time.
    func updateItems(of sessionID: String, to items: [ExerciseTemplateItem]) {
        guard let index = saved.firstIndex(where: { $0.id == sessionID }) else { return }
        var session = saved[index]
        session.items = items
        saved[index] = session
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

    func save(named name: String) {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !added.isEmpty else { return }
        saved.append(
            ExerciseQuickSession(name: title, subtitle: subtitle, items: templateItems)
        )
        reset()
    }

    // A lone run reads back as its plan, e.g. "5 km • 4 intervals"; anything more
    // counts what's in it instead.
    var subtitle: String {
        if added.count == 1, let plan = plans[added[0]] {
            return plan.subtitle
        }
        return "\(added.count) exercise\(added.count == 1 ? "" : "s")"
    }

    // The draft as the superset sheet reads it.
    var draftExercises: [ExerciseActiveExercise] {
        ExerciseActiveExercise.fromTemplate(templateItems).map { exercise in
            var copy = exercise
            copy.supersetID = supersets[exercise.name]
            return copy
        }
    }

    // Takes the sheet's result back: the order it left them in, and which of
    // them it grouped.
    func applySupersets(_ exercises: [ExerciseActiveExercise]) {
        added = exercises.map(\.name)
        supersets = exercises.reduce(into: [:]) { map, exercise in
            if let group = exercise.supersetID { map[exercise.name] = group }
        }
    }

    private var templateItems: [ExerciseTemplateItem] {
        // Groups flatten to small ints, numbered by first appearance.
        var groups: [UUID: Int] = [:]
        for exercise in added {
            guard let group = supersets[exercise], groups[group] == nil else { continue }
            groups[group] = groups.count + 1
        }
        return added.map { exercise in
            ExerciseTemplateItem(
                exerciseName: exercise,
                target: target(for: exercise),
                sets: (sets[exercise] ?? []).map { draft in
                    ExerciseTemplateSet(
                        weight: draft.weight.filter { $0.isNumber || $0 == "." },
                        reps: draft.reps.filter(\.isNumber),
                        kind: draft.kind
                    )
                },
                plan: plans[exercise],
                supersetGroup: supersets[exercise].flatMap { groups[$0] }
            )
        }
    }

    // The exercises the pill at `id` stands for: its whole superset block, or
    // just itself. A group needs two members to count as one.
    func groupMembers(for exercise: String) -> [String] {
        guard let group = supersets[exercise] else { return [exercise] }
        let members = added.filter { supersets[$0] == group }
        return members.count > 1 ? members : [exercise]
    }

    // One entry per picker pill: supersetted exercises collapse into their
    // first member.
    var groupLeaders: [String] {
        var seen: Set<UUID> = []
        return added.filter { exercise in
            guard let group = supersets[exercise], groupMembers(for: exercise).count > 1 else { return true }
            return seen.insert(group).inserted
        }
    }

    func groupTitle(for exercise: String) -> String {
        groupMembers(for: exercise).joined(separator: " & ")
    }

    func planBinding(for exercise: String) -> Binding<ExerciseCardioPlan> {
        Binding(
            get: { [weak self] in self?.plans[exercise] ?? ExerciseCardioPlan() },
            set: { [weak self] plan in self?.plans[exercise] = plan }
        )
    }

    private func target(for exercise: String) -> String {
        if let plan = plans[exercise] { return plan.subtitle }
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
