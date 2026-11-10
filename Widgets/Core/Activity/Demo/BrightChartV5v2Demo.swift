//
//  BrightChartV5v2Demo.swift
//  Widgets
//
//  Created by Dom Montalto on 10/11/2026.
//

import Foundation

// Seeded by date, so a period reads the same every time it pages back into view.
enum BrightChartV5v2Demo {
    static func points(for period: BrightChartV5v2Period, type: BrightChartV5v2Type) -> [BrightChartV5v2Point] {
        let now = Date.now
        return period.buckets.compactMap { date in
            guard date <= now else { return nil }
            let key = Int(date.timeIntervalSince1970 / 60)
            if type == .dotted, period.range == .day, noise(key, salt: 7) < 0.45 { return nil }
            return BrightChartV5v2Point(date: date, value: value(at: date, key: key, period: period, type: type))
        }
    }

    private static func value(at date: Date, key: Int, period: BrightChartV5v2Period, type: BrightChartV5v2Type) -> Double {
        let calendar = BrightChartV5v2Period.calendar
        let salt = switch type {
        case .bar: 1
        case .line: 2
        case .dotted: 3
        }
        let jitter = (noise(key, salt: salt) - 0.5) * 30

        let base: Double
        switch period.range {
        case .day:
            let hour = Double(calendar.component(.hour, from: date))
            let waking = hour >= 7 && hour <= 22
            base = waking ? 62 + 18 * sin((hour - 7) / 15 * .pi) : 24
        case .week, .month, .threeMonths:
            let weekday = calendar.component(.weekday, from: date)
            let weekend = weekday == 1 || weekday == 7
            let dayOfYear = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
            base = 58 + 12 * sin(dayOfYear / 365 * 2 * .pi) - (weekend ? 10 : 0)
        case .year:
            let month = Double(calendar.component(.month, from: date))
            base = 60 + 14 * sin((month - 3) / 12 * 2 * .pi)
            return min(max(base + jitter / 3, 5), 98)
        }
        return min(max(base + jitter, 5), 98)
    }

    private static func noise(_ key: Int, salt: Int) -> Double {
        var x = UInt64(bitPattern: Int64(key &* 31 &+ salt)) &+ 0x9E37_79B9_7F4A_7C15
        x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9
        x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB
        x ^= x >> 31
        return Double(x % 10_000) / 10_000
    }
}
