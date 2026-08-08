//
//  ExerciseLiveWorkoutStore.swift
//  Widgets
//
//  Created by Dom Montalto on 8/8/2026.
//

import SwiftUI

// One run for the whole app. Every screen that hosts the workout flow reads it
// from here, so a minimised workout keeps its card no matter which screen or
// sheet is on top.
@MainActor @Observable
final class ExerciseLiveWorkoutStore {
    var run: ExerciseLiveWorkoutRun?
}
