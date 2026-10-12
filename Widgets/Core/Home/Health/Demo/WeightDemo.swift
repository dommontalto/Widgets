//
//  WeightDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    static let weightAppearance = BrightWidgetAppearanceV5(
        title: "Weight",
        systemImage: "scalemass.fill",
        tint: .defaultPurple,
        unit: "kg",
        decimals: 1
    )

    // The last 14 morning weigh-ins, a few days skipped, ending today.
    static let weightPoints = readings(
        [(20, 83.5), (18, 83.3), (17, 83.4), (14, 83.1), (12, 83.0), (11, 82.8), (10, 82.9), (8, 82.9), (7, 82.8), (5, 82.6), (4, 82.7), (2, 82.5), (1, 82.6), (0, 82.4)]
    )

    static let weightChanges: [BrightDottedLineChartWidgetV5.Change] = [
        .init(span: "7d", value: "-0.36"),
        .init(span: "14d", value: "-0.71"),
        .init(span: "30d", value: "-1.4"),
    ]

    static let weightNote = "Stress and poor sleep can raise water retention."

    static let vo2MaxAppearance = BrightWidgetAppearanceV5(
        title: "VO2 Max",
        systemImage: "lungs.fill",
        tint: .defaultSkyBlue,
        unit: "ml/kg/min"
    )

    static let vo2MaxPoints = readings(
        [(22, 50), (20, 49), (18, 51), (16, 50), (14, 52), (12, 54), (10, 51), (8, 51), (6, 50), (5, 48), (4, 52), (3, 51), (1, 52), (0, 57)]
    )

    // Each pair is how many days ago, and the reading.
    private static func readings(_ days: [(Int, Double)]) -> [BrightDottedLineChartWidgetV5.Point] {
        days.map { daysAgo, value in
            BrightDottedLineChartWidgetV5.Point(date: anchor.addingTimeInterval(-Double(daysAgo) * 24 * 60 * 60), value: value)
        }
    }
}
