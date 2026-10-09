//
//  HealthWidgetDemoV5.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

// Demo readings for the home widgets, one file per measure. All of it is dated from
// launch, so the widgets always look live.
enum HealthWidgetDemoV5 {
    static let anchor = Date.now

    // One bar measure: its readings for each hour of a day and for the last seven days,
    // and what it's held against.
    struct BarMetric {
        let appearance: BrightWidgetAppearanceV5
        let fill: BrightBarChartWidgetV5.Fill
        // The week's bars where they differ from the hours'.
        var weekFill: BrightBarChartWidgetV5.Fill?
        let hourly: [Double]
        // Oldest first and ending today, so today always shows the last value
        // whichever day of the week it is.
        let daily: [Double]
        // Each day's own limit, lined up with `daily`, drawn as the mark inside its bar.
        var dailyTargets: [Double]?
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
                    let hour = (HealthWidgetDemoV5.currentHour - (range.slotCount - 1) + index + 24) % 24
                    return BrightBarChartWidgetV5.Bar(index: index, value: hourly[hour])
                }
            }
            let start = Calendar.current.component(.hour, from: range.interval(endingAt: HealthWidgetDemoV5.anchor).start)
            let current = HealthWidgetDemoV5.currentHour - start
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
            customSubtitle?(range) ?? "Latest: \(HealthWidgetDemoV5.currentHourRange)"
        }

        var weekBars: [BrightBarChartWidgetV5.Bar] {
            let today = HealthWidgetDemoV5.currentWeekday
            return (0 ..< daily.count).map { index in
                guard index <= today else {
                    return BrightBarChartWidgetV5.Bar(index: index, value: nil)
                }
                let day = daily.count - 1 - (today - index)
                return BrightBarChartWidgetV5.Bar(index: index, value: daily[day], target: dailyTargets?[day])
            }
        }

        var summary: BrightBarChartWidgetV5.Summary {
            if summarisesTargets, let dayTarget {
                .targets(weekBars, target: dayTarget)
            } else {
                .values(weekBars)
            }
        }
    }

    // The hour now running, e.g. "5 pm – 6 pm".
    static var currentHourRange: String {
        let hour = Calendar.current.dateInterval(of: .hour, for: anchor) ?? DateInterval(start: anchor, duration: 60 * 60)
        return "\(hour.start.formatted(.brightHour)) – \(hour.end.formatted(.brightHour))"
    }

    static var currentHour: Int {
        Calendar.current.component(.hour, from: anchor)
    }

    // Monday is 0.
    static var currentWeekday: Int {
        (Calendar.current.component(.weekday, from: anchor) + 5) % 7
    }

    static func minutesAgo(_ minutes: Int) -> Date {
        anchor.addingTimeInterval(-Double(minutes) * 60)
    }
}
