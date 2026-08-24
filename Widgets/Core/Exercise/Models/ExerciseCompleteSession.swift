//
//  ExerciseCompleteSession.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

// A finished session as the complete sheet reads it. Strength and cardio share
// the sheet, and every widget hides when its data is absent — no kind switch.
struct ExerciseCompleteSession {
    var summary: HeartWorkoutSummaryResponseData
    var metrics: [ExerciseCompleteMetric] = []
    var fatigue: ExerciseCompleteFatigue?
    var exertion: ExerciseCompleteExertion?
    var records: [ExerciseCompleteRecord] = []
    var progressions: [ExerciseCompleteProgression] = []
    var intervals: ExerciseCompleteIntervalStrip?
    // What the part picker draws for this session. Cardio and sports carry
    // their own category; strength leaves it nil.
    var category: ExerciseCategory?

    // Strength always shows the gym glyph, bodyweight included, so a mixed
    // session's picker reads as "the lifting part" rather than naming the kit.
    var symbol: String {
        category?.symbol ?? ExerciseCategory.gym.symbol
    }

    var partTitle: String {
        (category ?? .gym).displayName
    }

    var partTint: Color {
        (category ?? .gym).tint
    }

    // The combined graph draws whichever traces exist; none at all means the
    // widget has nothing to say.
    var hasPerformanceGraph: Bool {
        summary.heartGraph?.data?.isEmpty == false
            || summary.altitudeGraph?.data?.isEmpty == false
            || summary.paceGraph?.data?.isEmpty == false
            || summary.cadenceGraph?.data?.isEmpty == false
    }
}

// MARK: - Summary metrics

struct ExerciseCompleteMetric: Identifiable {
    let icon: ExerciseCompleteIcon
    let title: String
    let value: String

    var id: String { title }
}

enum ExerciseCompleteIcon {
    case asset(String)
    case system(String, tint: Color)
}

// MARK: - Session fatigue

struct ExerciseCompleteFatigue {
    let value: Int
    let label: String

    // Share of the ring the reading fills, so the arc always agrees with the
    // number it circles.
    var fraction: Double {
        Double(min(max(value, 0), 100)) / 100
    }
}

// MARK: - Exertion

struct ExerciseCompleteExertion {
    let average: Int
    let label: String
    let peaks: [ExerciseCompletePeak]
}

struct ExerciseCompletePeak: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let rpe: Int
}

// MARK: - Personal records

struct ExerciseCompleteRecord: Identifiable {
    let id = UUID()
    let badge: String
    let glyph: ExerciseCompleteRecordGlyph
    let title: String
    let detail: String
    let value: String
    // The exercise the record was set on, when there is one — a cardio record
    // is a distance or a time and has none.
    var exercise: String?
    // The leg the record was set in, so a tap can open the session.
    var logId: String?
    var legIds: [String]?
}

enum ExerciseCompleteRecordGlyph {
    case symbol(String)
    // A distance badge reads as its distance over the glyph, e.g. "1K" above a hare.
    case captioned(String, symbol: String)
}

// MARK: - Progression

struct ExerciseCompleteProgression: Identifiable {
    let id = UUID()
    let exercise: String
    let direction: ExerciseCompleteProgressionDirection
    let change: String
    let sets: [ExerciseCompleteProgressionSet]
    // When the session was logged. Set on an exercise's own history, where the
    // exercise is already the page and the date is what tells the cards apart.
    var date: String?
}

enum ExerciseCompleteProgressionDirection {
    case increased
    case unchanged
    case decreased

    var color: Color {
        switch self {
        case .increased: .defaultGreen
        case .unchanged: .defaultBlue
        case .decreased: .defaultRed
        }
    }

    // One glyph turned three ways, so the three cards read as one scale.
    var rotation: Angle {
        switch self {
        case .increased: .zero
        case .unchanged: .degrees(90)
        case .decreased: .degrees(180)
        }
    }

    var note: String {
        switch self {
        case .increased: "Progression increased compared to last session."
        case .unchanged: "Progression stayed the same compared to last session."
        case .decreased: "Progression decreased compared to last session."
        }
    }
}

struct ExerciseCompleteProgressionSet: Identifiable {
    let id = UUID()
    let label: String
    let detail: String
    // The rep the set failed on, if it did.
    var failedRep: String?
    var rpe: Int?
    var isSkipped = false
}

// MARK: - Interval strip

struct ExerciseCompleteIntervalStrip {
    let steps: [ExerciseCompleteIntervalStep]
    let selectedIndex: Int
}

struct ExerciseCompleteIntervalStep: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    // Left nil on the finish, which stands for the run as a whole: it reads the
    // session's own metrics and lights the entire route.
    var metrics: [ExerciseCompleteMetric]?
    // The stretch of the route this step covers, as fractions of its length.
    var route: ClosedRange<Double>?
    var tint: Color = .defaultSkyBlue
}
