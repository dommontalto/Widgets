//
//  LighthouseDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

// Hard-coded Lighthouse reply so a sleep question shows the opening line and
// three insight/widget pairs without a backend.
enum LighthouseDemo {
    static let sleepPartOne = "Notice how few REM stages of sleep you had?"

    static let sleepItems: [LighthouseStoryItem] = [
        LighthouseStoryItem(
            text: "You barely reached REM last night. Your deep and REM stages were short and broken up.",
            widget: .sleep
        ),
        LighthouseStoryItem(
            text: "Your heart rate was high while you poorly slept, meaning your body didn't have time to rest.",
            widget: .heart
        ),
        LighthouseStoryItem(
            text: "And now it's 11am and you haven't properly rested.",
            widget: .activity
        ),
    ]

    // Overnight sleep card (Score 54, 8H 13MIN, 67 BPM) with a REM-poor stage
    // graph: only a few short, broken-up REM segments, which are the bars that
    // light up on load.
    static let sleepDashboardData: HealthDashboardSleepData = {
        let calendar = Calendar.current
        let night = calendar.startOfDay(for: Date())

        func time(_ hour: Int, _ minute: Int) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: night) ?? night
        }

        func bar(_ sh: Int, _ sm: Int, _ eh: Int, _ em: Int, _ state: SleepGraphResponseValues.SleepState)
            -> SleepGraphResponseValues {
            SleepGraphResponseValues(start: time(sh, sm), end: time(eh, em), sleepState: state)
        }

        let values: [SleepGraphResponseValues] = [
            bar(0, 13, 0, 45, .light), bar(0, 45, 1, 0, .rem), bar(1, 0, 1, 35, .deep),
            bar(1, 35, 1, 48, .awake), bar(1, 48, 2, 30, .light), bar(2, 30, 3, 15, .deep),
            bar(3, 15, 3, 28, .rem), bar(3, 28, 4, 10, .light), bar(4, 10, 4, 55, .deep),
            bar(4, 55, 5, 12, .awake), bar(5, 12, 6, 5, .light), bar(6, 5, 6, 20, .rem),
            bar(6, 20, 7, 5, .light), bar(7, 5, 7, 20, .rem), bar(7, 20, 7, 45, .deep),
            bar(7, 45, 8, 26, .light),
        ]

        return HealthDashboardSleepData(
            sleepStart: time(0, 13),
            sleepEnd: time(8, 26),
            score: 54,
            durationHours: 8,
            durationMinutes: 13,
            values: values,
            heartRate: 67
        )
    }()

    // A dense, naturally varying overnight trace so the line reads like a real
    // heart-rate graph, elevated to match the reply ("HR was high").
    static let heartDashboardData: HealthDashboardHeartData = {
        // ~120 points 4 minutes apart, summed from a few overlapping sines so the
        // line wanders smoothly without big jumps between neighbours.
        let count = 120
        let values: [Int] = (0 ..< count).map { i in
            let t = Double(i)
            let v = 80.0
                + 8.0 * sin(t / 17.0)
                + 5.0 * sin(t / 6.5 + 1.2)
                + 2.5 * sin(t / 2.7)
            return Int(v.rounded())
        }
        let calendar = Calendar.current
        let start = calendar.date(
            bySettingHour: 23, minute: 0, second: 0,
            of: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ) ?? Date()
        let formatter = ISO8601DateFormatter()
        let times = values.indices.map {
            formatter.string(from: start.addingTimeInterval(Double($0) * 4 * 60))
        }
        return HealthDashboardHeartData(
            hrAvg: 80,
            hrData: values,
            hrTime: times,
            hrHigh: values.max() ?? 96,
            hrLow: values.min() ?? 64,
            hasData: true
        )
    }()

    // The activity number the activity widget counts up to.
    static let activityValue = 320

    // TDEE breakdown so the activity widget's four contributors show real
    // numbers; EAT matches the headline active number.
    static let activityTdee = ActivityTdeeBreakdownResponseData(
        bmr: 1480,
        neat: 420,
        tef: 180,
        eat: activityValue,
        unit: "kcal"
    )

    // Seven days of expenditure/intake bars so the activity widget renders the
    // real chart with proper y-axis numbers.
    static let activityGraphData: ActivityGraphData = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expenditure: [Double] = [2100, 2400, 2600, 2250, 2500, 2050, 2300]
        let intake: [Double] = [1950, 2200, 2050, 2300, 2150, 1900, 2100]
        let bars = (0 ..< 7).map { i -> ActivityGraphData.BarValue in
            let date = calendar.date(byAdding: .day, value: i - 6, to: today) ?? today
            return ActivityGraphData.BarValue(date: date, activeValue: expenditure[i], restingValue: intake[i])
        }
        return ActivityGraphData(
            barValues: bars,
            unit: "Cal",
            highestValue: (expenditure + intake).max() ?? 2600
        )
    }()
}
