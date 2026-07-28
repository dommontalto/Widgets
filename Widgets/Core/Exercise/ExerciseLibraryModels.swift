//
//  ExerciseLibraryModels.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

enum ExerciseEquipment: String, CaseIterable, Identifiable {
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

enum ExerciseMuscle: String, CaseIterable, Identifiable {
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

enum ExerciseLibraryCategory: String, CaseIterable, Identifiable {
    case push
    case pull
    case legs
    case core
    case cardio

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .push: "dumbbell"
        case .pull: "figure.strengthtraining.traditional"
        case .legs: "figure.step.training"
        case .core: "figure.core.training"
        case .cardio: "figure.run"
        }
    }

    var accentColor: Color {
        self == .cardio ? .defaultSkyBlue : .defaultPurple
    }
}

struct ExerciseProgressionPoint: Identifiable {
    let id: Int
    let weeksAgo: Int
    let value: Double
}

struct ExerciseHistoryEntry: Identifiable {
    let id = UUID()
    let date: String
    let summary: String
    let bestSet: String
}

struct ExerciseDefinition: Identifiable {
    let name: String
    let equipment: ExerciseEquipment
    let primaryMuscle: ExerciseMuscle
    let secondaryMuscles: [ExerciseMuscle]
    let category: ExerciseLibraryCategory
    let instructions: [String]
    let records: [ExerciseSessionStat]
    let history: [ExerciseHistoryEntry]
    let progression: [ExerciseProgressionPoint]
    let progressionMetric: String

    var id: String { name }

    var equipmentLabel: String { equipment.displayName }
}
