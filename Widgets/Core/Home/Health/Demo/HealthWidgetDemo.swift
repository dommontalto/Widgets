//
//  HealthWidgetDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

enum HealthWidgetDemo {
    // One reading a minute for the last hour, oldest first: a ride early on,
    // then a cool-down with a brief dip near the end.
    private static let lastHourValues: [Double] = [
        96, 98, 94, 92, 99, 104, 101, 97, 108, 112, 123, 106, 102, 110, 114, 108,
        104, 99, 103, 111, 107, 100, 97, 102, 98, 94, 96, 99, 93, 90, 92, 88,
        91, 87, 89, 86, 88, 84, 86, 83, 85, 82, 84, 81, 83, 80, 82, 79,
        81, 74, 71, 76, 84, 86, 83, 82, 84, 81, 83, 82, 80,
    ]

    // The eleven hours before it: slow swings around a resting rate with seeded jitter,
    // so it's the same every launch, warming up into the ride over the last 15 minutes.
    private static let earlierValues: [Double] = (0 ..< earlierMinutes).map { minute in
        let time = Double(minute)
        let swing = 8 * sin(time / 95) + 5 * sin(time / 37 + 1.3)
        let warmUp = max(time - Double(earlierMinutes - 15), 0) / 15 * 20
        return (74 + swing + warmUp + jitter(minute)).rounded()
    }

    private static let earlierMinutes = 11 * 60

    private static let heartRateValues = earlierValues + lastHourValues

    private static let anchor = Date.now

    static let heartRate: [BrightLineChartWidgetV5.Sample] = heartRateValues.enumerated().map { minute, value in
        BrightLineChartWidgetV5.Sample(date: minutesAgo(heartRateValues.count - 1 - minute), value: value)
    }

    static let heartRateEvents: [BrightLineChartWidgetV5.Event] = [
        BrightLineChartWidgetV5.Event(
            start: minutesAgo(54),
            end: minutesAgo(32),
            systemImage: "figure.outdoor.cycle",
            color: .defaultOrange
        ),
    ]

    // MARK: - Intake and activity

    // One bar measure: its readings for each hour of a day and each day of this week,
    // Monday first, and what it's held against.
    struct BarMetric {
        let title: String
        let systemImage: String
        let tint: Color
        let unit: String?
        let fill: BrightBarChartWidgetV5.Fill
        // The week's bars where they differ from the hours'.
        var weekFill: BrightBarChartWidgetV5.Fill?
        let hourly: [Double]
        let daily: [Double]
        var hourTarget: Double?
        var dayTarget: Double?
        let yesterday: Double
        // Large widgets list the week against the day target rather than as plain values.
        var summarisesTargets = false

        func bars(for range: BrightBarChartWidgetV5.Range) -> [BrightBarChartWidgetV5.Bar] {
            switch range {
            case .rolling12h:
                // Wraps into yesterday, which the demo treats as the same day again.
                (0 ..< range.slotCount).map { index in
                    let hour = (HealthWidgetDemo.currentHour - (range.slotCount - 1) + index + 24) % 24
                    return BrightBarChartWidgetV5.Bar(index: index, value: hourly[hour])
                }
            case .today:
                HealthWidgetDemo.upToNow(hourly, current: HealthWidgetDemo.currentHour)
            case .week:
                weekBars
            }
        }

        func fill(for range: BrightBarChartWidgetV5.Range) -> BrightBarChartWidgetV5.Fill {
            range == .week ? weekFill ?? fill : fill
        }

        func target(for range: BrightBarChartWidgetV5.Range) -> Double? {
            range.isHourly ? hourTarget : dayTarget
        }

        var weekBars: [BrightBarChartWidgetV5.Bar] {
            HealthWidgetDemo.upToNow(daily, current: HealthWidgetDemo.currentWeekday)
        }

        var summary: BrightBarChartWidgetV5.Summary {
            if summarisesTargets, let dayTarget {
                .targets(weekBars, target: dayTarget)
            } else {
                .values(weekBars)
            }
        }
    }

    static let intake = BarMetric(
        title: "Intake",
        systemImage: "arrow.right",
        tint: .defaultGreen,
        unit: "Cal",
        fill: .solid(.defaultGreen),
        weekFill: .rising,
        hourly: [0, 0, 0, 0, 0, 0, 0, 180, 320, 0, 90, 0, 520, 140, 0, 60, 0, 0, 640, 220, 0, 120, 0, 0],
        daily: [1_968, 2_420, 2_010, 2_150, 2_380, 2_240, 1_890],
        dayTarget: 2_200,
        yesterday: 2_100,
        summarisesTargets: true
    )

    static let totalEnergy = BarMetric(
        title: "Total Energy",
        systemImage: "flame.fill",
        tint: .defaultOrange,
        unit: "Cal",
        fill: .solid(.defaultCyan),
        hourly: [62, 58, 57, 56, 58, 60, 85, 140, 95, 110, 90, 80, 120, 95, 85, 88, 160, 210, 130, 90, 80, 75, 70, 65],
        daily: [1_829, 2_310, 1_905, 2_420, 1_823, 2_050, 1_980],
        hourTarget: 120,
        dayTarget: 2_200,
        yesterday: 2_100
    )

    static let activeEnergy = BarMetric(
        title: "Active Energy",
        systemImage: "flame.fill",
        tint: .defaultOrange,
        unit: "Cal",
        fill: .solid(.defaultOrange),
        hourly: [0, 0, 0, 0, 0, 0, 25, 80, 35, 50, 30, 20, 60, 35, 25, 28, 100, 150, 70, 30, 20, 15, 10, 5],
        daily: [605, 403, 343, 435, 541, 480, 390],
        yesterday: 2_100
    )

    static let steps = BarMetric(
        title: "Steps",
        systemImage: "shoeprints.fill",
        tint: .defaultYellow,
        unit: nil,
        fill: .solid(.defaultYellow),
        hourly: [0, 0, 0, 0, 0, 0, 120, 1_450, 820, 400, 600, 350, 900, 520, 300, 450, 1_600, 2_100, 800, 400, 200, 100, 0, 0],
        daily: [2_394, 5_345, 12_340, 2_388, 9_394, 7_200, 4_100],
        yesterday: 12_839
    )

    static let latestMeal: (calories: Double, date: Date) = (403, minutesAgo(47))

    // The hour now running, e.g. "5-6 pm".
    static var currentHourRange: String {
        let start = Calendar.current.dateInterval(of: .hour, for: anchor)?.start ?? anchor
        let hour = Calendar.current.component(.hour, from: start) % 12
        return "\(hour == 0 ? 12 : hour)-\(start.addingTimeInterval(60 * 60).formatted(.brightHour))"
    }

    private static var currentHour: Int {
        Calendar.current.component(.hour, from: anchor)
    }

    // Monday is 0.
    private static var currentWeekday: Int {
        (Calendar.current.component(.weekday, from: anchor) + 5) % 7
    }

    // Slots after the current one haven't happened yet.
    private static func upToNow(_ values: [Double], current: Int) -> [BrightBarChartWidgetV5.Bar] {
        values.enumerated().map { index, value in
            BrightBarChartWidgetV5.Bar(index: index, value: index <= current ? value : nil)
        }
    }

    private static func jitter(_ minute: Int) -> Double {
        var hash = UInt64(minute + 1) &* 0x9E37_79B9_7F4A_7C15
        hash ^= hash >> 31
        return Double(hash % 9) - 4
    }

    private static func minutesAgo(_ minutes: Int) -> Date {
        anchor.addingTimeInterval(-Double(minutes) * 60)
    }
}
