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

    static var macrosYesterday: String {
        let day = macroShares[macroShares.count - 2]
        return "Yesterday: C:\(Int(day.carbs)), F:\(Int(day.fat)), P:\(Int(day.protein))"
    }

    // Today's grams against each goal: today's intake calories split by today's shares.
    // The goals split the intake target the same way.
    static var macroRings: [BrightRingGroupWidgetV5.Ring] {
        let today = macroShares[macroShares.count - 1]
        return [
            .init(label: "Carbs", shortLabel: "C", value: grams(intake.today, share: today.carbs, caloriesPerGram: 4), goal: 240, color: .defaultGreen),
            .init(label: "Fats", shortLabel: "F", value: grams(intake.today, share: today.fat, caloriesPerGram: 9), goal: 60, color: .defaultYellow),
            .init(label: "Protein", shortLabel: "P", value: grams(intake.today, share: today.protein, caloriesPerGram: 4), goal: 175, color: .defaultPink),
        ]
    }

    static func macroRing(_ macro: HealthMacroV5) -> BrightRingGroupWidgetV5.Ring {
        switch macro {
        case .carbs: macroRings[0]
        case .fats: macroRings[1]
        case .protein: macroRings[2]
        }
    }

    static func macroBar(_ macro: HealthMacroV5) -> BrightHorizontalBarChartWidgetV5.Bar {
        bar(macroRing(macro), unit: "g", systemImage: "arrow.right")
    }

    static func macroBehind(_ macro: HealthMacroV5) -> String {
        behind(macroRing(macro), unit: "g")
    }

    static var macroBars: [BrightHorizontalBarChartWidgetV5.Bar] {
        macroRings.map { bar($0, unit: "g") }
    }

    // Each day's intake calories, split into carbs, fat and protein as shares of them,
    // oldest first and ending today.
    static var macroWeek: [BrightVerticalBarChartWidgetV5.Bar] {
        let calories = intake.daily + [intake.today]
        let weekday = currentWeekday
        return (0 ..< macroShares.count).map { index in
            guard index <= weekday else {
                return BrightVerticalBarChartWidgetV5.Bar(index: index, value: nil)
            }
            let day = macroShares.count - 1 - (weekday - index)
            let shares = macroShares[day]
            let segments = [
                BrightVerticalBarChartWidgetV5.Segment(label: "C", value: shares.carbs, color: .defaultGreen),
                BrightVerticalBarChartWidgetV5.Segment(label: "F", value: shares.fat, color: .defaultYellow),
                BrightVerticalBarChartWidgetV5.Segment(label: "P", value: shares.protein, color: .defaultPink),
            ]
            return BrightVerticalBarChartWidgetV5.Bar(index: index, value: calories[day], segments: segments)
        }
    }

    // Each day's percentage of calories from carbs, fat and protein, lined up with the
    // intake's week and ending today.
    private static let macroShares: [(carbs: Double, fat: Double, protein: Double)] = [
        (45, 25, 30),
        (40, 15, 45),
        (30, 25, 45),
        (35, 20, 45),
        (30, 10, 60),
        (55, 25, 20),
        (35, 25, 40),
    ]

    private static func grams(_ calories: Double, share: Double, caloriesPerGram: Double) -> Double {
        (calories * share / 100 / caloriesPerGram).rounded()
    }
}
