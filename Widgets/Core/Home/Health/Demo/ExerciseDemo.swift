//
//  ExerciseDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 13/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    static let exerciseStrengthPercent = 68
    static let exerciseCardioPercent = 32

    static let exerciseWeeks: [BrightExerciseSplitsWidgetV5.Week] = [
        .init(name: "Week 1", strengthFraction: 0.60, cardioFraction: 0.40, ratio: "60/40"),
        .init(name: "Week 2", strengthFraction: 0.64, cardioFraction: 0.36, ratio: "64/36"),
        .init(name: "Week 3", strengthFraction: 0.70, cardioFraction: 0.30, ratio: "70/30"),
        .init(name: "Week 4", strengthFraction: 0.78, cardioFraction: 0.22, ratio: "78/22"),
    ]
}
