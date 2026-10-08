//
//  WaterDemo.swift
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

    static let waterGoal: Double = 4

    static var waterToday: Double {
        water.bars(for: .today).compactMap(\.value).reduce(0, +)
    }

    // Today's litres so far against the day's goal.
    static var waterRing: BrightRingGroupWidgetV5.Ring {
        .init(label: "Water", shortLabel: "W", value: waterToday, goal: waterGoal, color: .defaultCyan, decimals: 2, warnsWhenOver: false)
    }

    // The last three days, oldest first, each against the day's goal. Today and yesterday
    // say so; the day before goes by its name.
    static var waterRings: [BrightRingGroupWidgetV5.Ring] {
        let days = Array(water.daily.suffix(3))
        return days.enumerated().map { index, litres in
            let daysAgo = days.count - 1 - index
            let date = anchor.addingTimeInterval(-Double(daysAgo) * 24 * 60 * 60)
            let label = daysAgo < 2 ? date.formatted(.brightDate) : date.formatted(.brightWeekday)
            return .init(
                label: label,
                shortLabel: String(label.prefix(1)),
                value: litres,
                goal: waterGoal,
                color: .defaultCyan,
                decimals: 2,
                warnsWhenOver: false
            )
        }
    }
}
