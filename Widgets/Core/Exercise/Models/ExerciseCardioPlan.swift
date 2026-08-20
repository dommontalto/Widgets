//
//  ExerciseCardioPlan.swift
//  Widgets
//
//  Created by Dom Montalto on 18/8/2026.
//

import SwiftUI

// What the run is chasing. Picked from the menu on the primary row's badge, the
// way a set's kind is picked on a strength session.
enum ExerciseCardioGoal: String, CaseIterable, Identifiable {
    case distance
    case duration
    case zone
    case calorie
    case freerun

    var id: String { rawValue }

    // Named for the menu; the primary row heading uses the same text.
    var title: String {
        switch self {
        case .distance: "Distance"
        case .duration: "Duration"
        case .zone: "Zone"
        case .calorie: "Calorie"
        case .freerun: "Freerun"
        }
    }

    var symbol: String {
        switch self {
        case .distance: "lines.measurement.horizontal.aligned.bottom"
        case .duration: "stopwatch"
        case .zone: "bolt.heart.fill"
        case .calorie: "flame.fill"
        case .freerun: "figure.run"
        }
    }

    var tint: Color {
        switch self {
        case .distance: .defaultBlue
        case .duration: .defaultBrightViolet
        case .zone: .defaultRed
        case .calorie: .defaultOrange
        case .freerun: .defaultGreen
        }
    }

    var unit: String? {
        switch self {
        case .distance: "KM"
        case .duration: "MIN"
        case .calorie: "CAL"
        case .zone, .freerun: nil
        }
    }

    // Freerun is the whole plan — nothing to target and nothing to add to it.
    var hasSecondarySection: Bool {
        self != .freerun
    }
}

// The follow-up target, picked from the menu on the optional row's badge. Which
// ones are offered depends on the primary goal.
enum ExerciseCardioSecondary: String, Identifiable {
    case pace
    case distance
    case duration
    case zone

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pace: "Pace"
        case .distance: "Distance"
        case .duration: "Duration"
        case .zone: "Zone"
        }
    }

    var symbol: String {
        switch self {
        case .pace: "clock"
        case .distance: ExerciseCardioGoal.distance.symbol
        case .duration: ExerciseCardioGoal.duration.symbol
        case .zone: ExerciseCardioGoal.zone.symbol
        }
    }

    var tint: Color {
        switch self {
        case .pace: .defaultGreen
        case .distance: ExerciseCardioGoal.distance.tint
        case .duration: ExerciseCardioGoal.duration.tint
        case .zone: ExerciseCardioGoal.zone.tint
        }
    }

    var unit: String? {
        switch self {
        case .distance: "KM"
        case .duration: "MIN"
        case .pace, .zone: nil
        }
    }
}

enum ExerciseHeartZone: Int, CaseIterable, Identifiable {
    case one = 1
    case two
    case three
    case four
    case five

    var id: Int { rawValue }

    var title: String { "ZONE \(rawValue)" }

    var range: String {
        switch self {
        case .one: "<139 BPM"
        case .two: "140-152 BPM"
        case .three: "152-166 BPM"
        case .four: "166-196 BPM"
        case .five: "+196 BPM"
        }
    }

    // BrightStatus owns the zone ramp, so the tick matches its tag.
    var color: Color {
        BrightStatus(status: title).color
    }
}

enum ExerciseIntervalPhase: String, CaseIterable, Identifiable {
    case warmup
    case run
    case walk
    case cooldown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warmup: "Warmup"
        case .run: "Run"
        case .walk: "Walk"
        case .cooldown: "Cooldown"
        }
    }

    var symbol: String {
        switch self {
        case .warmup: "figure.cooldown"
        case .run: "figure.run"
        case .walk: "figure.walk"
        case .cooldown: "snowflake"
        }
    }

}

struct ExerciseCardioInterval: Identifiable {
    let id = UUID()
    var phase: ExerciseIntervalPhase
    var value: String

    // Every leg is measured in metres.
    static let defaults: [ExerciseCardioInterval] = [
        ExerciseCardioInterval(phase: .warmup, value: "500"),
        ExerciseCardioInterval(phase: .run, value: "3000"),
        ExerciseCardioInterval(phase: .walk, value: "500"),
        ExerciseCardioInterval(phase: .run, value: "1000"),
        ExerciseCardioInterval(phase: .cooldown, value: "500"),
    ]
}

// Everything a cardio session is chasing, kept together so the create screen can
// hold one of these instead of a drawer full of fields.
struct ExerciseCardioPlan {
    var goal: ExerciseCardioGoal = .distance
    var secondary: ExerciseCardioSecondary = .pace
    var distance = ""
    var duration = ""
    var calories = ""
    var pace = ""
    var zone: ExerciseHeartZone = .two
    var isUTurnOn = false
    var isIntervalsOn = false
    var intervals = ExerciseCardioInterval.defaults

    // A stop condition pairs with an intensity and vice versa, so a distance or
    // timed run only takes a pace, while a zone run takes the distance or time it
    // runs for.
    var secondaryOptions: [ExerciseCardioSecondary] {
        switch goal {
        case .zone: [.distance, .duration]
        case .calorie: [.pace, .zone]
        default: [.pace]
        }
    }

    var hasIntervals: Bool {
        goal == .distance || goal == .duration
    }

    // Everything the plan holds, so an edit screen can tell a change from a no-op.
    var signature: String {
        let legs = intervals.map { "\($0.phase.rawValue):\($0.value)" }.joined(separator: ",")
        return [
            goal.rawValue, secondary.rawValue, distance, duration, calories, pace,
            "\(zone.rawValue)", "\(isUTurnOn)", "\(isIntervalsOn)", legs,
        ].joined(separator: "|")
    }

    // Reads back as the plan on the session's card, e.g. "5 km • 4 intervals".
    var subtitle: String {
        var parts: [String] = []

        switch goal {
        case .distance:
            if !distance.isEmpty { parts.append("\(distance) km") }
        case .duration:
            if !duration.isEmpty { parts.append("\(duration) min") }
        case .zone:
            parts.append("Zone \(zone.rawValue)")
        case .calorie:
            if !calories.isEmpty { parts.append("\(calories) cal") }
        case .freerun:
            parts.append("Freerun")
        }

        if goal.hasSecondarySection {
            switch secondary {
            case .pace:
                if !pace.isEmpty { parts.append(pace) }
            case .distance:
                if !distance.isEmpty, goal != .distance { parts.append("\(distance) km") }
            case .duration:
                if !duration.isEmpty, goal != .duration { parts.append("\(duration) min") }
            case .zone:
                if goal != .zone { parts.append("Zone \(zone.rawValue)") }
            }
        }

        if isIntervalsOn, hasIntervals {
            parts.append("\(intervals.count) intervals")
        }

        return parts.isEmpty ? "Cardio" : parts.joined(separator: " \u{2022} ")
    }
}
