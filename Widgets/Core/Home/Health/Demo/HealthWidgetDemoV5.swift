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
        let fill: BrightVerticalBarChartWidgetV5.Fill
        // The week's bars where they differ from the hours'.
        var weekFill: BrightVerticalBarChartWidgetV5.Fill?
        let hourly: [Double]
        // The six days before today, oldest first and ending yesterday. Today is the sum of
        // its hours so far, so the week, the day and the rings always agree.
        let daily: [Double]
        // Each day's own limit, lined up with the week of `daily` then today, drawn as the
        // mark inside its bar.
        var dailyTargets: [Double]?
        var hourTarget: Double?
        var dayTarget: Double?
        // Large widgets list the week against the day target rather than as plain values.
        var summarisesTargets = false
        // Replaces the hour now running under the title.
        var customSubtitle: ((BrightWidgetRangeV5) -> String)?

        func bars(for range: BrightWidgetRangeV5) -> [BrightVerticalBarChartWidgetV5.Bar] {
            if range.isWeek {
                return weekBars
            }
            if range.isRolling {
                // Wraps into yesterday, which the demo treats as the same day again.
                return (0 ..< range.slotCount).map { index in
                    let hour = (HealthWidgetDemoV5.currentHour - (range.slotCount - 1) + index + 24) % 24
                    return BrightVerticalBarChartWidgetV5.Bar(index: index, value: hourly[hour])
                }
            }
            let start = Calendar.current.component(.hour, from: range.interval(endingAt: HealthWidgetDemoV5.anchor).start)
            let current = HealthWidgetDemoV5.currentHour - start
            return (0 ..< range.slotCount).map { index in
                BrightVerticalBarChartWidgetV5.Bar(index: index, value: index <= current ? hourly[(start + index) % 24] : nil)
            }
        }

        func fill(for range: BrightWidgetRangeV5) -> BrightVerticalBarChartWidgetV5.Fill {
            range.isWeek ? weekFill ?? fill : fill
        }

        func target(for range: BrightWidgetRangeV5) -> Double? {
            range.isWeek ? dayTarget : hourTarget
        }

        func subtitle(for range: BrightWidgetRangeV5) -> String {
            customSubtitle?(range) ?? "Latest: \(HealthWidgetDemoV5.currentHourRange)"
        }

        var today: Double {
            bars(for: .today).compactMap(\.value).reduce(0, +)
        }

        var yesterday: Double {
            daily.last ?? 0
        }

        var weekBars: [BrightVerticalBarChartWidgetV5.Bar] {
            let week = daily + [today]
            let weekday = HealthWidgetDemoV5.currentWeekday
            return (0 ..< week.count).map { index in
                guard index <= weekday else {
                    return BrightVerticalBarChartWidgetV5.Bar(index: index, value: nil)
                }
                let day = week.count - 1 - (weekday - index)
                return BrightVerticalBarChartWidgetV5.Bar(index: index, value: week[day], target: dailyTargets?[day])
            }
        }

        var summary: BrightVerticalBarChartWidgetV5.Summary {
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

    static func bar(
        _ ring: BrightRingGroupWidgetV5.Ring,
        unit: String = "",
        systemImage: String? = nil,
        gradient: Gradient? = nil,
        reading: String? = nil,
        goalReading: String? = nil
    ) -> BrightHorizontalBarChartWidgetV5.Bar {
        .init(
            label: ring.label,
            value: ring.value,
            goal: ring.goal,
            color: ring.color,
            gradient: gradient,
            systemImage: systemImage,
            image: ring.image,
            shortLabel: ring.shortLabel,
            unit: unit,
            decimals: ring.decimals,
            reading: reading,
            goalReading: goalReading
        )
    }

    static func behind(_ ring: BrightRingGroupWidgetV5.Ring, unit: String = "") -> String {
        let gap = abs(ring.goal - ring.value).formatted(.number.precision(.fractionLength(0 ... ring.decimals)))
        return "\(gap)\(unit) \(ring.value > ring.goal ? "over" : "behind")"
    }

    static func minutesAgo(_ minutes: Int) -> Date {
        anchor.addingTimeInterval(-Double(minutes) * 60)
    }
}
