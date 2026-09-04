//
//  ExerciseDemoSessions.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

// One of the icons a session wears — the icon of an exercise it holds.
nonisolated struct ExerciseSessionGlyph: Identifiable {
    let id: String
    let color: Color

    var symbol: String { id }
}

nonisolated enum ExerciseSessionLeg: Hashable {
    case strength(Range<Int>)
    case cardio(Int)

    var isCardio: Bool {
        if case .cardio = self { return true }
        return false
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct ExerciseQuickSession: Identifiable {
    let name: String
    let subtitle: String
    var items: [ExerciseTemplateItem] = []

    var id: String { name }

    // Only what's logged set by set. A run or a sport isn't, so it never reaches
    // the live session's list.
    var strengthItems: [ExerciseTemplateItem] {
        items.filter { !ExerciseDemoLibrary.isCardio($0.exerciseName) }
    }

    // One leg each: every run and every sport gets its own setup screen and its
    // own live screen, in the order they were added. Two runs in a session means
    // two legs, not one — they're never merged.
    // Backend: keep each leg's own plan on the item, since the setup screen reads
    // its targets and intervals from there rather than from the session.
    var cardioItems: [ExerciseTemplateItem] {
        items.filter { ExerciseDemoLibrary.isCardio($0.exerciseName) }
    }

    // The session as it runs: the order the user arranged is sacred, so a run
    // or a sport splits the lifting around it. Contiguous set-by-set exercises
    // form one strength leg; every cardio item is its own. Each leg posts its
    // own log.
    var legs: [ExerciseSessionLeg] {
        var legs: [ExerciseSessionLeg] = []
        var blockStart: Int?
        for (index, item) in items.enumerated() {
            if ExerciseDemoLibrary.isCardio(item.exerciseName) {
                if let start = blockStart {
                    legs.append(.strength(start ..< index))
                    blockStart = nil
                }
                legs.append(.cardio(index))
            } else if blockStart == nil {
                blockStart = index
            }
        }
        if let start = blockStart {
            legs.append(.strength(start ..< items.count))
        }
        return legs
    }

    func items(in leg: ExerciseSessionLeg) -> [ExerciseTemplateItem] {
        switch leg {
        case let .strength(range): Array(items[range])
        case let .cardio(index): [items[index]]
        }
    }

    // A session runs as cardio only when there's nothing in it to log set by set.
    var isCardio: Bool {
        !items.isEmpty && strengthItems.isEmpty
    }

    var hasCardio: Bool { !cardioItems.isEmpty }

    var hasStrength: Bool { !strengthItems.isEmpty }

    var symbol: String { glyphs.first?.symbol ?? ExerciseCategory.gym.symbol }

    var accentColor: Color { glyphs.first?.color ?? ExerciseCategory.gym.tint }

    // The card wears what's in the session: one icon per exercise in the order
    // they were added, up to four, and never the same icon twice.
    var glyphs: [ExerciseSessionGlyph] {
        var glyphs: [ExerciseSessionGlyph] = []
        for item in items {
            let glyph = ExerciseDemoLibrary.glyph(for: item.exerciseName)
            guard !glyphs.contains(where: { $0.id == glyph.id }) else { continue }
            glyphs.append(glyph)
            if glyphs.count == ExerciseQuickSession.maxGlyphs { break }
        }
        return glyphs
    }

    static let maxGlyphs = 4
}

enum ExerciseDemoSessions {
    static let all: [ExerciseQuickSession] = [pushAndRun, quickFiveK, quickTenK, quickPush, quickPull]

    // Holds both kinds, so the run takes the lifting leg first and sets the run
    // up once that's logged.
    static let pushAndRun = ExerciseQuickSession(
        name: "Push & run",
        subtitle: "2 exercises \u{2022} 4 km",
        items: [
            ExerciseTemplateItem(
                exerciseName: "Bench Press",
                target: "3 \u{00D7} 8",
                sets: [
                    ExerciseTemplateSet(weight: "40", reps: "12", kind: .warmUp),
                    ExerciseTemplateSet(weight: "60", reps: "8", kind: .working(1)),
                    ExerciseTemplateSet(weight: "70", reps: "8", kind: .working(2)),
                    ExerciseTemplateSet(weight: "70", reps: "8", kind: .working(3)),
                ]
            ),
            ExerciseTemplateItem(
                exerciseName: "Shoulder Press",
                target: "3 \u{00D7} 10",
                sets: [
                    ExerciseTemplateSet(weight: "20", reps: "12", kind: .warmUp),
                    ExerciseTemplateSet(weight: "26", reps: "10", kind: .working(1)),
                    ExerciseTemplateSet(weight: "26", reps: "10", kind: .working(2)),
                    ExerciseTemplateSet(weight: "26", reps: "10", kind: .working(3)),
                ]
            ),
            ExerciseTemplateItem(
                exerciseName: "Outdoor Run",
                target: "4 km \u{2022} 5\u{2019}30",
                plan: ExerciseCardioPlan(
                    goal: .distance,
                    secondary: .pace,
                    distance: "4",
                    pace: "5\u{2019}30",
                    isIntervalsOn: true
                )
            ),
        ]
    )

    static let quickFiveK = ExerciseQuickSession(
        name: "Quick 5K",
        subtitle: "5 km \u{2022} Zone 2",
        items: [
            ExerciseTemplateItem(
                exerciseName: "Outdoor Run",
                target: "5 km \u{2022} Zone 2",
                plan: ExerciseCardioPlan(goal: .distance, secondary: .pace, distance: "5", pace: "5\u{2019}00")
            ),
        ]
    )

    static let quickTenK = ExerciseQuickSession(
        name: "Quick 10K",
        subtitle: "10 km \u{2022} Zone 3",
        items: [
            ExerciseTemplateItem(
                exerciseName: "Outdoor Run",
                target: "10 km \u{2022} Zone 3",
                plan: ExerciseCardioPlan(goal: .distance, secondary: .pace, distance: "10", pace: "5\u{2019}20")
            ),
        ]
    )

    static let quickPush = ExerciseQuickSession(
        name: "Quick Push",
        subtitle: "4 exercises",
        items: [
            ExerciseTemplateItem(
                exerciseName: "Bench Press",
                target: "4 \u{00D7} 8",
                sets: [
                    ExerciseTemplateSet(weight: "40", reps: "12", kind: .warmUp),
                    ExerciseTemplateSet(weight: "60", reps: "8", kind: .working(1)),
                    ExerciseTemplateSet(weight: "70", reps: "8", kind: .working(2)),
                    ExerciseTemplateSet(weight: "80", reps: "8", kind: .working(3)),
                    ExerciseTemplateSet(weight: "60", reps: "8", kind: .dropSet),
                ]
            ),
            ExerciseTemplateItem(
                exerciseName: "Shoulder Press",
                target: "3 \u{00D7} 10",
                sets: [
                    ExerciseTemplateSet(weight: "20", reps: "12", kind: .warmUp),
                    ExerciseTemplateSet(weight: "26", reps: "10", kind: .working(1)),
                    ExerciseTemplateSet(weight: "30", reps: "10", kind: .working(2)),
                    ExerciseTemplateSet(weight: "30", reps: "10", kind: .working(3)),
                ]
            ),
            ExerciseTemplateItem(
                exerciseName: "Bicep Curl",
                target: "3 \u{00D7} 12",
                sets: [
                    ExerciseTemplateSet(weight: "10", reps: "15", kind: .warmUp),
                    ExerciseTemplateSet(weight: "15", reps: "12", kind: .working(1)),
                    ExerciseTemplateSet(weight: "17.5", reps: "12", kind: .working(2)),
                    ExerciseTemplateSet(weight: "17.5", reps: "12", kind: .working(3)),
                ],
                supersetGroup: 1
            ),
            ExerciseTemplateItem(
                exerciseName: "Tricep Pushdown",
                target: "3 \u{00D7} 12",
                sets: [
                    ExerciseTemplateSet(weight: "15", reps: "15", kind: .warmUp),
                    ExerciseTemplateSet(weight: "22.5", reps: "12", kind: .working(1)),
                    ExerciseTemplateSet(weight: "25", reps: "12", kind: .working(2)),
                    ExerciseTemplateSet(weight: "25", reps: "12", kind: .dropSet),
                ],
                supersetGroup: 1
            ),
        ]
    )

    static let quickPull = ExerciseQuickSession(
        name: "Quick Pull",
        subtitle: "3 exercises",
        items: [
            ExerciseTemplateItem(
                exerciseName: "Pull Up",
                target: "4 \u{00D7} 8",
                sets: [
                    ExerciseTemplateSet(weight: "0", reps: "6", kind: .warmUp),
                    ExerciseTemplateSet(weight: "0", reps: "8", kind: .working(1)),
                    ExerciseTemplateSet(weight: "5", reps: "8", kind: .working(2)),
                    ExerciseTemplateSet(weight: "5", reps: "8", kind: .working(3)),
                ]
            ),
            ExerciseTemplateItem(
                exerciseName: "Bent Over Row",
                target: "3 \u{00D7} 10",
                sets: [
                    ExerciseTemplateSet(weight: "40", reps: "12", kind: .warmUp),
                    ExerciseTemplateSet(weight: "60", reps: "10", kind: .working(1)),
                    ExerciseTemplateSet(weight: "65", reps: "10", kind: .working(2)),
                    ExerciseTemplateSet(weight: "65", reps: "10", kind: .working(3)),
                ]
            ),
            ExerciseTemplateItem(
                exerciseName: "Bicep Curl",
                target: "3 \u{00D7} 12",
                sets: [
                    ExerciseTemplateSet(weight: "10", reps: "15", kind: .warmUp),
                    ExerciseTemplateSet(weight: "15", reps: "12", kind: .working(1)),
                    ExerciseTemplateSet(weight: "17.5", reps: "12", kind: .working(2)),
                ]
            ),
        ]
    )
}
