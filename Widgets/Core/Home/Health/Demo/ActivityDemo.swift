//
//  ActivityDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemo {
    static let totalEnergy = BarMetric(
        appearance: BrightWidgetAppearanceV5(
            title: "Total Energy",
            systemImage: "flame.fill",
            tint: .defaultOrange,
            unit: "Cal",
            iconGradient: [.defaultOrange, .defaultSand, .defaultCyan]
        ),
        fill: .solid(.defaultCyan),
        hourly: [62, 58, 57, 56, 58, 60, 85, 140, 95, 110, 90, 80, 120, 95, 85, 88, 160, 210, 130, 90, 80, 75, 70, 65],
        daily: [2_050, 1_980, 1_829, 2_310, 1_905, 2_420, 1_823],
        hourTarget: 160,
        dayTarget: 2_200,
        yesterday: 2_100
    )

    static let activeEnergy = BarMetric(
        appearance: BrightWidgetAppearanceV5(title: "Active Energy", systemImage: "flame.fill", tint: .defaultOrange, unit: "Cal"),
        fill: .solid(.defaultOrange),
        hourly: [0, 0, 0, 0, 0, 0, 25, 80, 35, 50, 30, 20, 60, 35, 25, 28, 100, 150, 70, 30, 20, 15, 10, 5],
        daily: [480, 390, 605, 403, 343, 435, 541],
        yesterday: 2_100
    )

    static let steps = BarMetric(
        appearance: BrightWidgetAppearanceV5(title: "Steps", systemImage: "shoeprints.fill", tint: .defaultYellow),
        fill: .solid(.defaultYellow),
        hourly: [0, 0, 0, 0, 0, 0, 120, 1_450, 820, 400, 600, 350, 900, 520, 300, 450, 1_600, 2_100, 800, 400, 200, 100, 0, 0],
        daily: [7_200, 4_100, 2_394, 5_345, 12_340, 2_388, 8_290],
        yesterday: 12_839
    )
}
