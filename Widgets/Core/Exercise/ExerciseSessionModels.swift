//
//  ExerciseSessionModels.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

struct ExerciseSessionDetail {
    let stats: [ExerciseSessionStat]
    let exercises: [ExerciseLoggedExercise]
    let splits: [ExerciseSplit]
    let note: String
}
 
struct ExerciseSessionStat {
    let label: String
    let value: String
    var unit: String?
}

struct ExerciseLoggedExercise {
    let name: String
    let sets: [ExerciseLoggedSet]
}

struct ExerciseLoggedSet {
    let weight: String
    let reps: String
    var isRecord = false
}

struct ExerciseSplit {
    let label: String
    let pace: String
    let paceFraction: CGFloat
    let heartRate: Int
    let elevation: String
}
