//
//  ExerciseDemoSessions.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

struct ExerciseQuickSession: Identifiable {
    let name: String
    let symbol: String
    let accentColor: Color
    let subtitle: String
    let isCardio: Bool
    var items: [ExerciseTemplateItem] = []

    var id: String { name }
}

enum ExerciseDemoSessions {
    static let all: [ExerciseQuickSession] = [quickFiveK, quickPush]

    static let quickFiveK = ExerciseQuickSession(
        name: "Quick 5K",
        symbol: "figure.run",
        accentColor: .defaultSkyBlue,
        subtitle: "5 km \u{2022} Zone 2",
        isCardio: true
    )

    static let quickPush = ExerciseQuickSession(
        name: "Quick Push",
        symbol: "dumbbell",
        accentColor: .defaultPurple,
        subtitle: "4 exercises",
        isCardio: false,
        items: [
            ExerciseTemplateItem(exerciseName: "Bench Press", target: "4 \u{00D7} 8"),
            ExerciseTemplateItem(exerciseName: "Shoulder Press", target: "3 \u{00D7} 10"),
            ExerciseTemplateItem(exerciseName: "Bicep Curl", target: "3 \u{00D7} 12"),
            ExerciseTemplateItem(exerciseName: "Tricep Pushdown", target: "3 \u{00D7} 12"),
        ]
    )
}
