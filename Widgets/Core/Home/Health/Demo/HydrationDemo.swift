//
//  HydrationDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemo {
    static let water = BarMetric(
        appearance: BrightWidgetAppearanceV5(
            title: "Water",
            systemImage: "drop.fill",
            tint: .defaultCyan,
            unit: "L",
            decimals: 2
        ),
        fill: .solid(.defaultCyan),
        hourly: [0, 0, 0, 0, 0, 0, 0, 0.5, 0, 0.25, 0, 0.4, 0, 0.6, 0, 0, 0.35, 0, 0.44, 0.3, 0, 0.25, 0, 0],
        daily: [3.4, 4.1, 3.2, 3.6, 2.9, 4.4, 2.54],
        yesterday: 4.4
    )

    static var waterToday: Double {
        water.bars(for: .today).compactMap(\.value).reduce(0, +)
    }
}
