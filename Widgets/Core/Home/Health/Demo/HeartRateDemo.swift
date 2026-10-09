//
//  HeartRateDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    static let heartRate: [BrightLineChartWidgetV5.Sample] = heartRateValues.enumerated().map { minute, value in
        BrightLineChartWidgetV5.Sample(date: minutesAgo(heartRateValues.count - 1 - minute), value: value)
    }

    static let heartRateEvents: [BrightLineChartWidgetV5.Event] = [
        // Asleep for the first stretch of the twelve hours, so the longer ranges show it.
        BrightLineChartWidgetV5.Event(
            start: minutesAgo(11 * 60 + 30),
            end: minutesAgo(8 * 60),
            systemImage: "bed.double",
            color: .defaultCyan
        ),
        BrightLineChartWidgetV5.Event(
            start: minutesAgo(54),
            end: minutesAgo(32),
            systemImage: "figure.strengthtraining.traditional",
            color: .defaultPink
        ),
    ]

    // One reading a minute for the last hour, oldest first: a strength session early
    // on, then a cool-down with a brief dip near the end.
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

    private static func jitter(_ minute: Int) -> Double {
        var hash = UInt64(minute + 1) &* 0x9E37_79B9_7F4A_7C15
        hash ^= hash >> 31
        return Double(hash % 9) - 4
    }
}
