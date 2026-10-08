//
//  MacrosDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemo {
    static let macrosAppearance = BrightWidgetAppearanceV5(
        title: "Weekly Macros split",
        systemImage: "chart.pie.fill",
        tint: .textColor
    )

    static let macrosYesterday = "Yest. C:50, F:20, P:30"

    // Each day's carbs, fat and protein as a share of its calories, oldest first and
    // ending today.
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
            return BrightBarChartWidgetV5.Bar(index: index, value: day.carbs + day.fat + day.protein, segments: segments)
        }
    }

    private static let macroDays: [(carbs: Double, fat: Double, protein: Double)] = [
        (45, 25, 30),
        (40, 15, 45),
        (30, 25, 45),
        (35, 20, 45),
        (30, 10, 60),
        (55, 25, 20),
        (35, 20, 45),
    ]
}
