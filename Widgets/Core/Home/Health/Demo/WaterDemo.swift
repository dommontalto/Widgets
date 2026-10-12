//
//  WaterDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    static let water = BarMetric(
        appearance: BrightWidgetAppearanceV5(
            title: "Water",
            systemImage: "drop.fill",
            tint: .defaultCyan,
            unit: "L",
            decimals: 2
        ),
        fill: .solid(.defaultCyan),
        hourly: [0, 0, 0, 0, 0, 0, 0.15, 0.4, 0.1, 0.25, 0.2, 0.3, 0.15, 0.45, 0.2, 0.25, 0.3, 0.15, 0.35, 0.25, 0.1, 0.2, 0.05, 0],
        daily: [3.4, 4.1, 3.2, 3.6, 2.9, 3.5]
    )

    static let waterGoal: Double = 4

    // Today's drinks so far, one in each hour the hourly bars have water, so the tank fills
    // to the same total as the bars and the rings.
    static var waterDrinks: [BrightWaterWidgetV5.Drink] {
        let midnight = Calendar.current.startOfDay(for: anchor)
        return (0 ... currentHour).compactMap { hour in
            let litres = water.hourly[hour]
            guard litres > 0 else { return nil }
            let date = min(midnight.addingTimeInterval((Double(hour) + 0.5) * 60 * 60), anchor)
            return .init(date: date, litres: litres)
        }
    }

    static var waterBar: BrightHorizontalBarChartWidgetV5.Bar {
        bar(.init(label: "Water", shortLabel: "W", value: waterToday, goal: waterGoal, color: .defaultCyan, decimals: 2), unit: "L", systemImage: "drop.fill")
    }

    static var waterBehind: String {
        behind(.init(label: "Water", shortLabel: "W", value: waterToday, goal: waterGoal, color: .defaultCyan, decimals: 2), unit: " L")
    }

    static var waterToday: Double {
        water.today
    }

    // Today's litres so far against the day's goal. Named like today's ring in the row of
    // days, so resizing between the two keeps the one ring and moves it.
    static var waterRing: BrightRingGroupWidgetV5.Ring {
        let label = anchor.formatted(.brightDate)
        return .init(label: label, shortLabel: String(label.prefix(1)), value: waterToday, goal: waterGoal, color: .defaultCyan, decimals: 2, warnsWhenOver: false)
    }

    // The last three days, oldest first, each against the day's goal. Today and yesterday
    // say so; the day before goes by its name.
    static var waterRings: [BrightRingGroupWidgetV5.Ring] {
        let days = Array(water.daily.suffix(2)) + [waterToday]
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
