//
//  ExerciseSessionBuilder.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

enum ExerciseSetKind: Hashable {
    case warmUp
    case working(Int)
    case coolDown

    var symbol: String? {
        switch self {
        case .warmUp: "figure.cooldown"
        case .working: nil
        case .coolDown: "arrow.down"
        }
    }

    var label: String? {
        if case let .working(index) = self { return "\(index)" }
        return nil
    }

    var color: Color {
        switch self {
        case .warmUp: .defaultGreen
        case .working: .defaultOrange
        case .coolDown: .defaultBrightPink
        }
    }
}

enum ExerciseSessionIcon: String, CaseIterable, Identifiable {
    case dumbbell
    case strength
    case run
    case bike
    case swim
    case sports

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .dumbbell: "dumbbell"
        case .strength: "figure.strengthtraining.traditional"
        case .run: "figure.run"
        case .bike: "figure.outdoor.cycle"
        case .swim: "figure.pool.swim"
        case .sports: "figure.rugby"
        }
    }
}

struct ExerciseSetDraft: Identifiable, Hashable {
    let id = UUID()
    let kind: ExerciseSetKind
    var weight: String
    var reps: String
    var rest: String
}

@MainActor @Observable
final class ExerciseSessionBuilder {
    var added: [String] = []
    var sets: [String: [ExerciseSetDraft]] = [:]
    var saved: [ExerciseQuickSession] = []
    var path = NavigationPath()

    var count: Int { added.count }

    func isAdded(_ name: String) -> Bool {
        added.contains(name)
    }

    func add(_ name: String) {
        guard !isAdded(name) else { return }
        added.append(name)
        sets[name] = ExerciseSessionBuilder.defaultSets
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

    func delete(_ session: ExerciseQuickSession) {
        saved.removeAll { $0.id == session.id }
    }

    func canDelete(_ session: ExerciseQuickSession) -> Bool {
        saved.contains { $0.id == session.id }
    }

    func duplicate(_ session: ExerciseQuickSession) {
        let copy = ExerciseQuickSession(
            name: uniqueName(from: session.name),
            symbol: session.symbol,
            accentColor: session.accentColor,
            subtitle: session.subtitle,
            isCardio: session.isCardio,
            items: session.items
        )
        if let index = saved.firstIndex(where: { $0.id == session.id }) {
            saved.insert(copy, at: index + 1)
        } else {
            saved.append(copy)
        }
    }

    func rename(_ session: ExerciseQuickSession, to name: String) {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, title != session.name,
              let index = saved.firstIndex(where: { $0.id == session.id })
        else { return }
        saved[index] = ExerciseQuickSession(
            name: uniqueName(from: title),
            symbol: session.symbol,
            accentColor: session.accentColor,
            subtitle: session.subtitle,
            isCardio: session.isCardio,
            items: session.items
        )
    }

    private func uniqueName(from name: String) -> String {
        let taken = Set((ExerciseDemoSessions.all + saved).map(\.name))
        guard taken.contains(name) else { return name }
        var candidate = "\(name) Copy"
        var suffix = 2
        while taken.contains(candidate) {
            candidate = "\(name) Copy \(suffix)"
            suffix += 1
        }
        return candidate
    }

    func save(named name: String, symbol: String = "dumbbell") {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !added.isEmpty else { return }
        let items = added.map { exercise in
            ExerciseTemplateItem(
                exerciseName: exercise,
                target: target(for: exercise)
            )
        }
        saved.append(
            ExerciseQuickSession(
                name: title,
                symbol: symbol,
                accentColor: .defaultPurple,
                subtitle: added.count.counted("exercise"),
                isCardio: false,
                items: items
            )
        )
        reset()
    }

    /// Plain-text export of the session, for sharing out of the sets editor.
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
        guard let first = working.first else { return working.count.counted("set") }
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

    private func renumbered(_ drafts: [ExerciseSetDraft]) -> [ExerciseSetDraft] {
        var working = 0
        return drafts.map { draft in
            guard case .working = draft.kind else { return draft }
            working += 1
            return ExerciseSetDraft(kind: .working(working), weight: draft.weight, reps: draft.reps, rest: draft.rest)
        }
    }

    func addSet(to exercise: String) {
        let working = (sets[exercise] ?? []).filter {
            if case .working = $0.kind { return true }
            return false
        }
        let draft = ExerciseSetDraft(kind: .working(working.count + 1), weight: "10 kg", reps: "5", rest: "5:00")
        guard let coolDownIndex = sets[exercise]?.firstIndex(where: { $0.kind == .coolDown }) else {
            sets[exercise, default: []].append(draft)
            return
        }
        sets[exercise]?.insert(draft, at: coolDownIndex)
    }

    private static let defaultSets: [ExerciseSetDraft] = [
        ExerciseSetDraft(kind: .warmUp, weight: "10 kg", reps: "5", rest: "1:00"),
        ExerciseSetDraft(kind: .working(1), weight: "10 kg", reps: "5", rest: "5:00"),
        ExerciseSetDraft(kind: .working(2), weight: "10 kg", reps: "5", rest: "5:00"),
        ExerciseSetDraft(kind: .working(3), weight: "10 kg", reps: "5", rest: "5:00"),
        ExerciseSetDraft(kind: .coolDown, weight: "10 kg", reps: "5", rest: "5:00"),
    ]
}
