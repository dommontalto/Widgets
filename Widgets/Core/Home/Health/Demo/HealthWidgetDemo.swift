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
    private static let heartRateValues: [Double] = [
        96, 98, 94, 92, 99, 104, 101, 97, 108, 112, 123, 106, 102, 110, 114, 108,
        104, 99, 103, 111, 107, 100, 97, 102, 98, 94, 96, 99, 93, 90, 92, 88,
        91, 87, 89, 86, 88, 84, 86, 83, 85, 82, 84, 81, 83, 80, 82, 79,
        81, 74, 71, 76, 84, 86, 83, 82, 84, 81, 83, 82, 80,
    ]

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

    private static func minutesAgo(_ minutes: Int) -> Date {
        anchor.addingTimeInterval(-Double(minutes) * 60)
    }
}
