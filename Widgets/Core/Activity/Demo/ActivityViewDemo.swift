//
//  ActivityViewDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 11/11/2026.
//

import SwiftUI

enum ActivityMetric: String, CaseIterable, Identifiable {
    case totalEnergy
    case activeEnergy
    case exerciseEnergy
    case restingEnergy
    case steps

    var id: Self { self }

    var bars: HealthWidgetDemoV5.BarMetric {
        switch self {
        case .totalEnergy: HealthWidgetDemoV5.totalEnergy
        case .activeEnergy: HealthWidgetDemoV5.activeEnergy
        case .exerciseEnergy: HealthWidgetDemoV5.exerciseEnergy
        case .restingEnergy: HealthWidgetDemoV5.restingEnergy
        case .steps: ActivityViewDemo.steps
        }
    }

    var title: String { bars.appearance.title }

    var unit: String { bars.appearance.unit ?? "Steps" }

    // The hours so far today against the same hours yesterday. With a resting part, active and resting
    // are compared apart, as the bars draw them.
    var comparisons: [ActivityComparison] {
        let hours = 0 ... HealthWidgetDemoV5.currentHour
        let yesterday = Self.dayScale(for: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now)
        let unit = bars.appearance.unit
        let today = hours.map { bars.hourly[$0] }
        guard let rest = bars.hourlyRest else {
            let tint = self.tint
            let active = today.filter { $0 > 0 }
            return [
                ActivityComparison(title: "Total", systemImage: bars.appearance.systemImage, tint: tint, unit: unit, values: today, yesterday: yesterday, measure: .total),
                ActivityComparison(title: "AVG", systemImage: bars.appearance.systemImage, tint: tint, unit: unit, values: today, yesterday: yesterday, measure: .average),
                ActivityComparison(title: "Peak", systemImage: "arrow.up", tint: tint, unit: unit, values: today, yesterday: yesterday, measure: .peak),
                ActivityComparison(title: "Active Hours", systemImage: "clock.fill", tint: tint, unit: "hrs", values: active.map { _ in 1 }, yesterday: 1, measure: .total),
            ]
        }
        let resting = hours.map { rest[$0] }
        let active = zip(today, resting).map(-)
        return [ActivityComparison.Measure.total, .average, .peak].flatMap { measure in
            let lead = switch measure {
            case .total: "Total"
            case .average: "AVG"
            case .peak: "Peak"
            }
            let image = measure == .peak ? "arrow.up" : "flame.fill"
            return [
                ActivityComparison(title: "\(lead) Active", systemImage: image, tint: .defaultOrange, unit: unit, values: active, yesterday: yesterday, measure: measure),
                ActivityComparison(title: "\(lead) Resting", systemImage: image, tint: .defaultCyan, unit: unit, values: resting, yesterday: yesterday, measure: measure),
            ]
        }
    }

    func format(_ value: Double) -> String {
        bars.appearance.format(value)
    }

    var tint: Color {
        switch bars.fill {
        case let .solid(color): color
        case .rising: .defaultGreen
        }
    }

    // Today's hours are the widget's own, and other days the same hours a little higher or
    // lower, so the sheet opens on the bars the widget showed. Longer ranges stretch the
    // seeded demo to this metric's daily totals.
    func points(for period: BrightChartV5v2Period, type: BrightChartV5v2Type) -> [BrightChartV5v2Point] {
        let calendar = BrightChartV5v2Period.calendar
        guard period.range == .day else {
            let scale = dailyAverage / Constants.seededAverage
            return BrightChartV5v2Demo.points(for: period, type: type).map { point in
                let value = point.value * scale
                return BrightChartV5v2Point(date: point.date, value: value, rest: restShare.map { value * $0 })
            }
        }
        let scale = Self.dayScale(for: period.start)
        return period.buckets.compactMap { date in
            guard date <= .now else { return nil }
            let hour = calendar.component(.hour, from: date)
            return BrightChartV5v2Point(date: date, value: bars.hourly[hour] * scale, rest: bars.hourlyRest.map { $0[hour] * scale })
        }
    }

    func domain(for range: BrightChartV5v2Range) -> ClosedRange<Double> {
        let top = range == .day
            ? (bars.hourly.max() ?? 1) * Constants.dayScaleRange.upperBound
            : dailyAverage / Constants.seededAverage * Constants.seededMax
        return 0 ... Self.roundedUp(top)
    }

    private var dailyAverage: Double {
        bars.daily.isEmpty ? 1 : bars.daily.reduce(0, +) / Double(bars.daily.count)
    }

    private var restShare: Double? {
        bars.hourlyRest.map { $0.reduce(0, +) / max(bars.hourly.reduce(0, +), 1) }
    }

    // Up to two significant figures, so the guide reads 220 or 2,800 rather than 213.6.
    private static func roundedUp(_ value: Double) -> Double {
        guard value > 0 else { return 1 }
        let step = pow(10, floor(log10(value)) - 1)
        return ceil(value / step) * step
    }

    // Today is the widget's own hours; any other day is them a little higher or lower, the same each time.
    private static func dayScale(for date: Date) -> Double {
        let calendar = BrightChartV5v2Period.calendar
        guard !calendar.isDateInToday(date) else { return 1 }
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return Constants.dayScaleRange.lowerBound + noise(day) * (Constants.dayScaleRange.upperBound - Constants.dayScaleRange.lowerBound)
    }

    private static func noise(_ seed: Int) -> Double {
        let x = sin(Double(seed) * 12.9898) * 43_758.5453
        return x - floor(x)
    }

    private enum Constants {
        static let seededAverage = 60.0
        static let seededMax = 100.0
        static let dayScaleRange = 0.8 ... 1.2
    }
}

// One tile of the sheet's comparison: a figure from today's hours, and how far it is from yesterday's,
// whose hours are today's scaled by `yesterday`.
struct ActivityComparison: Identifiable {
    enum Measure {
        case total
        case average
        case peak
    }

    let title: String
    let systemImage: String
    let tint: Color
    let unit: String?
    let values: [Double]
    let yesterday: Double
    let measure: Measure

    var id: String { title }

    var value: Double {
        figure(values)
    }

    var change: Double {
        value - figure(values.map { $0 * yesterday })
    }

    var changeSystemImage: String {
        change > 0 ? "arrow.up.right" : change < 0 ? "arrow.down.right" : "arrow.right"
    }

    private func figure(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        switch measure {
        case .total: return values.reduce(0, +)
        case .average: return values.reduce(0, +) / Double(values.count)
        case .peak: return values.max() ?? 0
        }
    }
}

enum ActivityViewDemo {
    static let steps = HealthWidgetDemoV5.BarMetric(
        appearance: BrightWidgetAppearanceV5(title: "Steps", systemImage: "shoeprints.fill", tint: .defaultYellow),
        fill: .solid(.defaultYellow),
        hourly: [0, 0, 60, 0, 0, 120, 820, 1_640, 960, 540, 380, 450, 300, 1_120, 690, 410, 760, 590, 2_180, 400, 260, 120, 40, 0],
        daily: [9_840, 12_310, 7_220, 10_480, 8_960, 13_120]
    )

    static let lighthouse = CycleTrackingImpactData(
        items: [
            CycleTrackingImpactItem(text: "Active energy is up 18% on last week", isPositive: true),
            CycleTrackingImpactItem(text: "Most of your movement lands after 4 pm", isPositive: true),
            CycleTrackingImpactItem(text: "Mornings are quieter than usual", isPositive: false),
        ],
        description: "You're moving more this week, mostly in the afternoons."
    )

    static let atlas = CycleTrackingImpactData(
        items: [
            CycleTrackingImpactItem(text: "Steps sit in the top 30% for your age", isPositive: true),
            CycleTrackingImpactItem(text: "Resting energy is close to average", isPositive: true),
        ],
        description: nil
    )

    static let experiments = CycleTrackingImpactData(
        items: [
            CycleTrackingImpactItem(text: "A 10 minute walk after lunch adds about 1,200 steps", isPositive: true),
            CycleTrackingImpactItem(text: "Late workouts haven't changed resting energy yet", isPositive: false),
        ],
        description: nil
    )
}
