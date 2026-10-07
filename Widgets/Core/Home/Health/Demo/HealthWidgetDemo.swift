//
//  HealthWidgetDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

// Demo readings for the home widgets, one file per measure. All of it is dated from
// launch, so the widgets always look live.
enum HealthWidgetDemo {
    static let anchor = Date.now

    // One bar measure: its readings for each hour of a day and each day of this week,
    // Monday first, and what it's held against.
    struct BarMetric {
        let appearance: BrightWidgetAppearanceV5
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
        // Replaces the hour now running under the title.
        var customSubtitle: ((BrightWidgetRangeV5) -> String)?

        func bars(for range: BrightWidgetRangeV5) -> [BrightBarChartWidgetV5.Bar] {
            if range.isWeek {
                return weekBars
            }
            if range.isRolling {
                // Wraps into yesterday, which the demo treats as the same day again.
                return (0 ..< range.slotCount).map { index in
                    let hour = (HealthWidgetDemo.currentHour - (range.slotCount - 1) + index + 24) % 24
                    return BrightBarChartWidgetV5.Bar(index: index, value: hourly[hour])
                }
            }
            let start = Calendar.current.component(.hour, from: range.interval(endingAt: HealthWidgetDemo.anchor).start)
            let current = HealthWidgetDemo.currentHour - start
            return (0 ..< range.slotCount).map { index in
                BrightBarChartWidgetV5.Bar(index: index, value: index <= current ? hourly[(start + index) % 24] : nil)
            }
        }

        func fill(for range: BrightWidgetRangeV5) -> BrightBarChartWidgetV5.Fill {
            range.isWeek ? weekFill ?? fill : fill
        }

        func target(for range: BrightWidgetRangeV5) -> Double? {
            range.isWeek ? dayTarget : hourTarget
        }

        func subtitle(for range: BrightWidgetRangeV5) -> String {
            customSubtitle?(range) ?? "Latest: \(HealthWidgetDemo.currentHourRange)"
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

    // The hour now running, e.g. "5-6 pm".
    static var currentHourRange: String {
        let start = Calendar.current.dateInterval(of: .hour, for: anchor)?.start ?? anchor
        let hour = Calendar.current.component(.hour, from: start) % 12
        return "\(hour == 0 ? 12 : hour)-\(start.addingTimeInterval(60 * 60).formatted(.brightHour))"
    }

    static var currentHour: Int {
        Calendar.current.component(.hour, from: anchor)
    }

    // Monday is 0.
    static var currentWeekday: Int {
        (Calendar.current.component(.weekday, from: anchor) + 5) % 7
    }

    // Slots after the current one haven't happened yet.
    static func upToNow(_ values: [Double], current: Int) -> [BrightBarChartWidgetV5.Bar] {
        values.enumerated().map { index, value in
            BrightBarChartWidgetV5.Bar(index: index, value: index <= current ? value : nil)
        }
    }

    static func minutesAgo(_ minutes: Int) -> Date {
        anchor.addingTimeInterval(-Double(minutes) * 60)
    }
}
