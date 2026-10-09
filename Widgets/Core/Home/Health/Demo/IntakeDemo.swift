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
        hourly: [0, 0, 0, 0, 0, 0, 40, 180, 320, 60, 90, 60, 420, 140, 80, 60, 90, 90, 480, 160, 60, 80, 40, 0],
        daily: [1_720, 1_610, 1_680, 1_790, 1_540, 1_750, 1_832],
        dayTarget: 2_200,
        yesterday: 2_100,
        summarisesTargets: true,
        customSubtitle: { intakeSubtitle(for: $0) }
    )

    // Today's calories so far against the day's goal.
    static var intakeRing: BrightRingGroupWidgetV5.Ring {
        let today = intake.bars(for: .today).compactMap(\.value).reduce(0, +)
        return .init(label: "Intake", shortLabel: "I", value: today, goal: intake.dayTarget ?? 0, color: .defaultGreen)
    }

    private static let latestMeal = minutesAgo(47)

    // The week names the latest meal; a day counts down what's left of the goal.
    private static func intakeSubtitle(for range: BrightWidgetRangeV5) -> String {
        if range.isWeek {
            return "Latest: \(latestMeal.formatted(.brightTimestamp))"
        }
        let today = intake.bars(for: .today).compactMap(\.value).reduce(0, +)
        return "\(Int(max((intake.dayTarget ?? 0) - today, 0)).formatted()) Remaining"
    }
}
