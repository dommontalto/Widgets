//
//  ExerciseSessionModels.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

nonisolated struct ExerciseSessionDetail {
    let stats: [ExerciseSessionStat]
    let exercises: [ExerciseLoggedExercise]
    let splits: [ExerciseSplit]
    let note: String
}
 
nonisolated struct ExerciseSessionStat {
    let label: String
    let value: String
    var unit: String?
}

nonisolated struct ExerciseLoggedExercise {
    let name: String
    let sets: [ExerciseLoggedSet]
}

nonisolated struct ExerciseLoggedSet {
    let weight: String
    let reps: String
    var isRecord = false
}

nonisolated struct ExerciseSplit {
    let label: String
    let pace: String
    let paceFraction: CGFloat
    let heartRate: Int
    let elevation: String
}
