//
//  MacrosDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    static let macrosAppearance = BrightWidgetAppearanceV5(
        title: "Weekly Macros",
        systemImage: "chart.pie.fill",
        tint: .textColor
    )

    static let macrosYesterday = "Yesterday: C:50, F:20, P:30"

    // Today's grams against each goal.
    static let macroRings: [BrightRingGroupWidgetV5.Ring] = [
        .init(label: "Carbs", shortLabel: "C", value: 75, goal: 200, color: .defaultGreen),
        .init(label: "Fats", shortLabel: "F", value: 27, goal: 46, color: .defaultYellow),
        .init(label: "Protein", shortLabel: "P", value: 102, goal: 140, color: .defaultPink),
    ]

    static func macroRing(_ macro: HealthMacroV5) -> BrightRingGroupWidgetV5.Ring {
        switch macro {
        case .carbs: macroRings[0]
        case .fats: macroRings[1]
        case .protein: macroRings[2]
        }
    }

    // Each day's calories, split into carbs, fat and protein as shares of them, oldest
    // first and ending today.
    static var macroWeek: [BrightBarChartWidgetV5.Bar] {
        let today = currentWeekday
        return (0 ..< macroDays.count).map { index in
            guard index <= today else {
                return BrightBarChartWidgetV5.Bar(index: index, value: nil)
            }
            let day = macroDays[macroDays.count - 1 - (today - index)]
            let segments = [
                BrightBarChartWidgetV5.Segment(label: "C", value: day.carbs, color: .defaultGreen),
                BrightBarChartWidgetV5.Segment(label: "F", value: day.fat, color: .defaultYellow),
                BrightBarChartWidgetV5.Segment(label: "P", value: day.protein, color: .defaultPink),
            ]
            return BrightBarChartWidgetV5.Bar(index: index, value: day.calories, segments: segments)
        }
    }

    private static let macroDays: [(calories: Double, carbs: Double, fat: Double, protein: Double)] = [
        (2_150, 45, 25, 30),
        (1_780, 40, 15, 45),
        (2_400, 30, 25, 45),
        (1_950, 35, 20, 45),
        (1_620, 30, 10, 60),
        (2_280, 55, 25, 20),
        (1_870, 35, 20, 45),
    ]
}
