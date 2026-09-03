//
//  ExerciseLibraryModels.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

nonisolated enum ExerciseEquipment: String, CaseIterable, Identifiable {
    case barbell
    case dumbbell
    case cable
    case machine
    case bodyweight
    case kettlebell
    case band

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

nonisolated enum ExerciseMuscle: String, CaseIterable, Identifiable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case forearms
    case quads
    case hamstrings
    case glutes
    case calves
    case core
    case fullBody

    var id: String { rawValue }

    var displayName: String {
        self == .fullBody ? "Full body" : rawValue.capitalized
    }
}

nonisolated enum ExerciseLibraryCategory: String, CaseIterable, Identifiable {
    case push
    case pull
    case legs
    case core
    case cardio

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    // Push, pull, legs and core are all lifting; only the cardio tab isn't.
    var type: ExerciseCategory {
        self == .cardio ? .cardio : .gym
    }

    var accentColor: Color { type.tint }
}

nonisolated enum ExerciseCategory: String, CaseIterable, Identifiable {
    case gym
    case bodyweight
    case cardio
    case sports

    static let standard: [ExerciseCategory] = allCases

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .gym: "figure.strengthtraining.traditional"
        case .bodyweight: "figure.play"
        case .cardio: "figure.run"
        case .sports: "figure.rugby"
        }
    }

    var countUnit: String {
        self == .sports ? "sports" : "exercises"
    }

    // Gym and bodyweight are logged set by set; cardio and sports run against a
    // plan instead.
    var isCardio: Bool {
        self == .cardio || self == .sports
    }

    // The one place the exercise feature's two colours are decided.
    var tint: Color {
        switch self {
        case .cardio, .sports: .defaultSkyBlue
        case .gym, .bodyweight: .defaultPurplePink
        }
    }
}

nonisolated struct ExerciseProgressionPoint: Identifiable {
    let id: Int
    let weeksAgo: Int
    let value: Double
}

nonisolated struct ExerciseHistoryEntry: Identifiable {
    let id = UUID()
    let date: String
    let summary: String
    let bestSet: String
}

nonisolated struct ExerciseDefinition: Identifiable {
    let name: String
    let type: ExerciseCategory
    let equipment: ExerciseEquipment
    let primaryMuscle: ExerciseMuscle
    let secondaryMuscles: [ExerciseMuscle]
    let category: ExerciseLibraryCategory
    let instructions: [String]
    let records: [ExerciseStrengthStat]
    let history: [ExerciseHistoryEntry]
    let progression: [ExerciseProgressionPoint]
    let progressionMetric: String

    var id: String { name }

    // The only icons an exercise ever wears are its library tab's four.
    var symbol: String { type.symbol }

    var equipmentLabel: String { equipment.displayName }
}
