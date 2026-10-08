//
//  IntakeDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemo {
    static let intake = BarMetric(
        appearance: BrightWidgetAppearanceV5(title: "Intake", systemImage: "arrow.right", tint: .defaultGreen, unit: "Cal"),
        fill: .solid(.defaultGreen),
        weekFill: .rising,
        hourly: [0, 0, 0, 0, 0, 0, 0, 180, 320, 0, 90, 0, 520, 140, 0, 60, 0, 0, 640, 220, 0, 120, 0, 0],
        daily: [1_720, 1_610, 1_680, 1_790, 1_540, 1_750, 1_832],
        dayTarget: 2_200,
        yesterday: 2_100,
        summarisesTargets: true,
        customSubtitle: { intakeSubtitle(for: $0) }
    )

    // Today's calories so far against the day's goal, with the running total hour by hour.
    static var intakeRing: BrightRingGroupWidgetV5.Ring {
        let timeline = intakeTimeline
        return .init(
            label: "Intake",
            shortLabel: "I",
            value: timeline.last ?? 0,
            goal: intake.dayTarget ?? 0,
            color: .defaultGreen,
            timeline: timeline
        )
    }

    // Calories eaten by the end of each hour so far today.
    static var intakeTimeline: [Double] {
        intake.bars(for: .today).compactMap(\.value).reduce(into: []) { totals, hour in
            totals.append((totals.last ?? 0) + hour)
        }
    }

    private static let latestMeal: (calories: Double, date: Date) = (403, minutesAgo(47))

    // The week names the latest meal; a day counts down what's left of the goal.
    private static func intakeSubtitle(for range: BrightWidgetRangeV5) -> String {
        if range.isWeek {
            return "Latest: \(Int(latestMeal.calories)) Cal, \(latestMeal.date.formatted(.brightTimestamp))"
        }
        let today = intake.bars(for: .today).compactMap(\.value).reduce(0, +)
        return "\(Int(max((intake.dayTarget ?? 0) - today, 0)).formatted()) Remaining"
    }
}
