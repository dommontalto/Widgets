//
//  ActivityDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    static let totalEnergy = BarMetric(
        appearance: BrightWidgetAppearanceV5(
            title: "Total Energy",
            systemImage: "flame.fill",
            tint: .defaultOrange,
            unit: "Cal",
            iconGradient: [.defaultOrange, .defaultSand, .defaultCyan]
        ),
        fill: .solid(.defaultCyan),
        hourly: zip(restingHours, activeHours).map(+),
        hourlyRest: restingHours.indices.map { workoutHours.contains($0) ? 0 : restingHours[$0] },
        daily: [1_420, 2_150, 1_610, 1_980, 1_240, 2_060],
        dailyTargets: [1_150, 1_600, 1_300, 1_500, 1_050, 1_550, 1_400]
    )

    static let activeEnergy = BarMetric(
        appearance: BrightWidgetAppearanceV5(title: "Active Energy", systemImage: "flame.fill", tint: .defaultOrange, unit: "Cal"),
        fill: .solid(.defaultOrange),
        hourly: activeHours,
        daily: [480, 390, 605, 403, 343, 435]
    )

    static let restingEnergy = BarMetric(
        appearance: BrightWidgetAppearanceV5(title: "Resting Energy", systemImage: "flame.fill", tint: .defaultCyan, unit: "Cal"),
        fill: .solid(.defaultCyan),
        hourly: restingHours,
        daily: [1_380, 1_410, 1_395, 1_440, 1_402, 1_418]
    )

    // Total Energy is these two added up, so its orange lands on the same hours as Active Energy.
    private static let activeHours: [Double] = [0, 0, 6, 0, 0, 10, 45, 120, 55, 50, 30, 20, 60, 35, 25, 28, 100, 150, 70, 30, 20, 15, 10, 5]
    private static let restingHours: [Double] = [40, 42, 38, 40, 41, 44, 48, 52, 50, 70, 82, 64, 68, 74, 80, 72, 62, 60, 58, 56, 55, 54, 52, 50]
    // Hours spent wholly in a workout, drawn all orange.
    private static let workoutHours: Set<Int> = [7, 17]
}
