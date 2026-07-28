//
//  ExerciseDemoRoute.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import Foundation

enum ExerciseDemoRoute {
    static let sampleCount = 100

    static let latitudes: [Double] = (0 ..< sampleCount).map { i in
        let t = Double(i) / Double(sampleCount - 1) * 2 * .pi
        return -33.8961 + 0.0062 * sin(t) + 0.0011 * sin(3 * t) + 0.0003 * sin(7 * t)
    }

    static let longitudes: [Double] = (0 ..< sampleCount).map { i in
        let t = Double(i) / Double(sampleCount - 1) * 2 * .pi
        return 151.2340 + 0.0078 * cos(t) + 0.0014 * cos(2 * t) + 0.0004 * sin(5 * t)
    }

    static let zoneIndexes: [Int] = (0 ..< sampleCount).map { i in
        let f = Double(i) / Double(sampleCount - 1)
        if f < 0.08 { return 1 }
        if f < 0.25 { return 2 }
        if f < 0.55 { return 3 }
        if f < 0.85 { return 4 }
        return f < 0.95 ? 5 : 4
    }

    static let heartGraph = HeartWorkoutSummaryHeartGraphData(
        yTicks: [100, 120, 140, 160, 180],
        data: (0 ..< sampleCount).map { i in
            let f = Double(i) / Double(sampleCount - 1)
            let rampUp = 96 + 56 * (1 - exp(-f * 9))
            let drift = 12 * f
            let efforts = 6 * sin(f * 2 * .pi * 1.6 - 0.7) + 3 * sin(f * 2 * .pi * 4.2 + 0.4)
            let finishKick = f > 0.85 ? 45 * (f - 0.85) : 0
            let jitter = 2.5 * sin(Double(i) * 1.9) + 1.5 * sin(Double(i) * 0.47 + 1.2)
            let value = rampUp + drift + efforts + finishKick + jitter
            return HeartWorkoutSummaryHeartGraphData.WorkoutSummaryHeartData(
                heartDate: isoDate(at: i),
                value: Int(value.rounded()),
                zone: zoneIndexes[i]
            )
        }
    )

    static let altitudeGraph = HeartWorkoutSummaryAltitudeGraphData(
        yTicks: [10, 25, 40],
        xDates: (0 ..< sampleCount).map(isoDate),
        data: (0 ..< sampleCount).map { i in
            let t = Double(i) / Double(sampleCount - 1) * 2 * .pi
            return Int((24 + 14 * sin(t + 0.8) + 4 * sin(3.5 * t)).rounded())
        }
    )

    static let paceGraph = HeartWorkoutSummaryPaceGraphData(
        yTicks: [280, 300, 320],
        xDates: (0 ..< sampleCount).map(isoDate),
        data: (0 ..< sampleCount).map { i in
            let f = Double(i) / Double(sampleCount - 1)
            return Int((316 - 30 * f + 6 * sin(Double(i) * 0.5)).rounded())
        }
    )

    static let duration = TimeDuration(hour: 0, minute: 25)

    private static func isoDate(at index: Int) -> String {
        let totalSeconds = index * 15
        let minute = 40 + totalSeconds / 60
        let second = totalSeconds % 60
        let hour = 6 + minute / 60
        return String(format: "2026-07-22T%02d:%02d:%02dZ", hour, minute % 60, second)
    }
}
