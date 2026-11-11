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
    case restingEnergy
    case steps

    var id: Self { self }

    var bars: HealthWidgetDemoV5.BarMetric {
        switch self {
        case .totalEnergy: HealthWidgetDemoV5.totalEnergy
        case .activeEnergy: HealthWidgetDemoV5.activeEnergy
        case .restingEnergy: HealthWidgetDemoV5.restingEnergy
        case .steps: ActivityViewDemo.steps
        }
    }

    var title: String { bars.appearance.title }

    var unit: String { bars.appearance.unit ?? "Steps" }

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
        let isToday = calendar.isDateInToday(period.start)
        let day = calendar.ordinality(of: .day, in: .era, for: period.start) ?? 0
        let scale = isToday ? 1 : Constants.dayScaleRange.lowerBound + Self.noise(day) * (Constants.dayScaleRange.upperBound - Constants.dayScaleRange.lowerBound)
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
