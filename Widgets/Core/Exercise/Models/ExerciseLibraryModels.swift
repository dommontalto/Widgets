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

    var accentColor: Color {
        self == .cardio ? .defaultSkyBlue : .defaultPurple
    }
}

nonisolated enum ExerciseWorkoutCategory: String, CaseIterable, Identifiable {
    case gym
    case bodyweight
    case cardio
    case sports

    static let standard: [ExerciseWorkoutCategory] = allCases

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
    let workoutCategory: ExerciseWorkoutCategory
    let equipment: ExerciseEquipment
    let primaryMuscle: ExerciseMuscle
    let secondaryMuscles: [ExerciseMuscle]
    let category: ExerciseLibraryCategory
    let instructions: [String]
    let records: [ExerciseWorkoutStat]
    let history: [ExerciseHistoryEntry]
    let progression: [ExerciseProgressionPoint]
    let progressionMetric: String

    var id: String { name }

    // The only icons an exercise ever wears are its library tab's four.
    var symbol: String { workoutCategory.symbol }

    var equipmentLabel: String { equipment.displayName }
}
