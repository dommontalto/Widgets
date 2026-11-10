//
//  ActivityViewDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 11/11/2026.
//

import SwiftUI

enum ActivityMetric: String, CaseIterable, Identifiable {
    case totalEnergy
    case activeEnergy
    case restingEnergy
    case steps

    var id: Self { self }

    var bars: HealthWidgetDemoV5.BarMetric {
        switch self {
        case .totalEnergy: HealthWidgetDemoV5.totalEnergy
        case .activeEnergy: HealthWidgetDemoV5.activeEnergy
        case .restingEnergy: ActivityViewDemo.restingEnergy
        case .steps: ActivityViewDemo.steps
        }
    }

    var title: String { bars.appearance.title }

    var unit: String { bars.appearance.unit ?? "Steps" }

    var tint: Color {
        switch bars.fill {
        case let .solid(color): color
        case .rising: .defaultGreen
        }
    }
}

enum ActivityViewDemo {
    static let restingEnergy = HealthWidgetDemoV5.BarMetric(
        appearance: BrightWidgetAppearanceV5(title: "Resting Energy", systemImage: "flame.fill", tint: .defaultCyan, unit: "Cal"),
        fill: .solid(.defaultCyan),
        hourly: [40, 42, 38, 40, 41, 44, 48, 52, 50, 70, 82, 64, 68, 74, 80, 72, 62, 60, 58, 56, 55, 54, 52, 50],
        daily: [1_380, 1_410, 1_395, 1_440, 1_402, 1_418]
    )

    static let steps = HealthWidgetDemoV5.BarMetric(
        appearance: BrightWidgetAppearanceV5(title: "Steps", systemImage: "shoeprints.fill", tint: .defaultYellow),
        fill: .solid(.defaultYellow),
        hourly: [0, 0, 0, 0, 0, 0, 0, 0, 0, 220, 380, 450, 300, 520, 690, 410, 760, 590, 840, 400, 260, 120, 40, 0],
        daily: [9_840, 12_310, 7_220, 10_480, 8_960, 13_120]
    )

    static let lighthouse = CycleTrackingImpactData(
        items: [
            CycleTrackingImpactItem(text: "Active energy is up 18% on last week", isPositive: true),
            CycleTrackingImpactItem(text: "Most of your movement lands after 4 pm", isPositive: true),
            CycleTrackingImpactItem(text: "Mornings are quieter than usual", isPositive: false),
        ],
        description: "You're moving more this week, mostly in the afternoons."
    )

    static let atlas = CycleTrackingImpactData(
        items: [
            CycleTrackingImpactItem(text: "Steps sit in the top 30% for your age", isPositive: true),
            CycleTrackingImpactItem(text: "Resting energy is close to average", isPositive: true),
        ],
        description: nil
    )

    static let experiments = CycleTrackingImpactData(
        items: [
            CycleTrackingImpactItem(text: "A 10 minute walk after lunch adds about 1,200 steps", isPositive: true),
            CycleTrackingImpactItem(text: "Late workouts haven't changed resting energy yet", isPositive: false),
        ],
        description: nil
    )
}
