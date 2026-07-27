//
//  HeartDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import Foundation

// MARK: - Shared value types

struct TimeDuration {
    var hour: Int?
    var minute: Int?
    var second: Int?

    var asString: String {
        var string = ""
        if let hour, hour != 0 {
            string = "\(hour) H"
        }
        if let minute, minute != 0 {
            string += !string.isEmpty ? " " : ""
            string += "\(minute) MIN"
        }
        return string
    }

    var clockString: String {
        String(format: "%02d:%02d:%02d", hour ?? 0, minute ?? 0, second ?? 0)
    }
}

struct Amount {
    var unit: String?
    var value: Double?

    /// Trims trailing zeroes: 1.0 renders as "1", 1.5 stays "1.5".
    var displayValue: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: value ?? 0)) ?? ""
    }
}

// MARK: - Workout summary

struct HeartWorkoutSummaryData {
    var title: String?
    var duration: TimeDuration?
    var energyOut: Amount?
    var startTime: String?
    var endTime: String?
    /// Where the workout came from, e.g. "Logged with Apple Watch".
    var source: String?

    var heartGraph: HeartWorkoutSummaryHeartGraphData?

    var hrAvg: Double?
    var zoneAvg: Int?

    var postWorkoutHeartGraph: HeartWorkoutSummaryPostWorkoutHeartGraphData?
    var breakdown: HeartWorkoutSummaryBreakdownData?

    var distance: Amount?
    var altitudeGain: Amount?
    var avgPaceSecondsPerKm: Int?

    var altitudeGraph: HeartWorkoutSummaryAltitudeGraphData?
    var paceGraph: HeartWorkoutSummaryPaceGraphData?
    var cadenceGraph: HeartWorkoutSummaryCadenceGraphData?
    var splits: [HeartWorkoutSummarySplit]?

    var cardioFitness: HeartSummaryCardioFitnessData?

    var routeLatitudes: [Double]?
    var routeLongitudes: [Double]?
    var routeZoneIndexes: [Int]?
}

struct HeartGraphDataStats {
    var min: Double?
    var max: Double?
    var avg: Double?
}

struct HeartWorkoutSummaryPostWorkoutHeartGraphData {
    var bpmDrop: Int?
    var xDates: [String]?
    var xDatesDisplay: [String]?
    var xBpm: [Int?]?
    var yTicks: [Int]?
    var data: [HeartGraphDataStats]?
}

struct HeartWorkoutSummaryBreakdownData {
    var zones: [HeartWorkoutSummaryBreakdownZones]?

    struct HeartWorkoutSummaryBreakdownZones {
        var title: String?
        var rangeStr: String?
        var duration: TimeDuration?
        var scaleValue: Int?
    }
}

struct HeartWorkoutSummaryHeartGraphData {
    var yTicks: [Int]?
    var data: [WorkoutSummaryHeartData]?

    struct WorkoutSummaryHeartData {
        var heartDate: String?
        var value: Int?
        var zone: Int?
    }
}

struct HeartWorkoutSummaryAltitudeGraphData {
    var yTicks: [Int]?
    var xDates: [String]?
    var data: [Int]?
}

struct HeartWorkoutSummaryPaceGraphData {
    var yTicks: [Int]?
    var xDates: [String]?
    var data: [Int]?
}

struct HeartWorkoutSummaryCadenceGraphData {
    var yTicks: [Int]?
    var xDates: [String]?
    var data: [Int]?
}

struct HeartWorkoutSummarySplit {
    var splitIndex: Int?
    var duration: TimeDuration?
    var paceSecondsPerKm: Int?
    var avgHeartRate: Int?
}

struct HeartSummaryCardioFitnessData {
    var title: String?
    var value: Double?
    var label: String?
    var xTicks: [Int]?
}

// MARK: - Demo data

enum HeartDemoData {
    static let workout = HeartWorkoutSummaryData(
        title: "Outdoor Run",
        duration: TimeDuration(hour: 0, minute: 45, second: 54),
        energyOut: Amount(unit: "kcal", value: 512),
        startTime: "2026-07-25T06:12:00Z",
        endTime: "2026-07-25T06:57:00Z",
        source: "Logged with Apple Watch",
        heartGraph: HeartWorkoutSummaryHeartGraphData(
            yTicks: [110, 185],
            data: heartSamples
        ),
        hrAvg: 152,
        zoneAvg: 3,
        postWorkoutHeartGraph: postWorkout,
        breakdown: breakdown,
        distance: Amount(unit: "M", value: 8_640),
        altitudeGain: Amount(unit: "M", value: 96),
        avgPaceSecondsPerKm: 313,
        altitudeGraph: HeartWorkoutSummaryAltitudeGraphData(
            yTicks: [12, 78],
            data: altitudeSamples
        ),
        paceGraph: HeartWorkoutSummaryPaceGraphData(
            yTicks: [275, 360],
            data: paceSamples
        ),
        cadenceGraph: HeartWorkoutSummaryCadenceGraphData(
            yTicks: [150, 190],
            data: cadenceSamples
        ),
        splits: splits,
        cardioFitness: HeartSummaryCardioFitnessData(
            title: "2026-07-25T06:57:00Z",
            value: 51.4,
            label: "Excellent",
            xTicks: [45, 50, 55]
        ),
        routeLatitudes: route.map(\.latitude),
        routeLongitudes: route.map(\.longitude),
        routeZoneIndexes: route.map(\.zone)
    )

    // MARK: Graph samples

    private static let sampleCount = 60
    private static let durationSeconds: Double = 45 * 60

    private static var heartSamples: [HeartWorkoutSummaryHeartGraphData.WorkoutSummaryHeartData] {
        let base = "2026-07-25T06:12:00Z".isoStringToDate()
        let formatter = ISO8601DateFormatter()

        return (0 ..< sampleCount).map { index in
            let t = Double(index) / Double(sampleCount - 1)
            let bpm = heartRate(atFraction: t)
            let date = base.addingTimeInterval(t * durationSeconds)

            return .init(
                heartDate: formatter.string(from: date),
                value: Int(bpm.rounded()),
                zone: zone(forBpm: bpm)
            )
        }
    }

    private static var altitudeSamples: [Int] {
        (0 ..< sampleCount).map { index in
            let t = Double(index) / Double(sampleCount - 1)
            // Two hills: a long climb through the middle, a short kick near the end.
            let climb = 30 * sin(t * .pi)
            let kick = 14 * max(0, sin((t - 0.72) * 6 * .pi))
            return Int((22 + climb + kick).rounded())
        }
    }

    private static var paceSamples: [Int] {
        (0 ..< sampleCount).map { index in
            let t = Double(index) / Double(sampleCount - 1)
            // Slower (higher seconds/km) on the climb, quicker on the descent and finish.
            let drift = 26 * sin(t * .pi)
            let surge = 18 * max(0, t - 0.85) / 0.15
            let ripple = 6 * sin(t * 9 * .pi)
            return Int((310 + drift - surge + ripple).rounded())
        }
    }

    private static var cadenceSamples: [Int] {
        (0 ..< sampleCount).map { index in
            let t = Double(index) / Double(sampleCount - 1)
            // Settles into a steady turnover after the warm-up, shortens slightly
            // on the climb, then lifts for the finish.
            let settle = 158 + (14 * min(1, t / 0.15))
            let climb = -5 * sin(t * .pi)
            let ripple = 3 * sin(t * 7 * .pi)
            let finishKick = 8 * max(0, t - 0.85) / 0.15
            return Int((settle + climb + ripple + finishKick).rounded())
        }
    }

    private static func heartRate(atFraction t: Double) -> Double {
        let warmUp = 128 + (34 * min(1, t / 0.18))
        let effort = 12 * sin(t * .pi)
        let ripple = 4 * sin(t * 11 * .pi)
        let finishKick = 10 * max(0, t - 0.88) / 0.12
        return warmUp + effort + ripple + finishKick
    }

    private static func zone(forBpm bpm: Double) -> Int {
        switch bpm {
        case ..<130: 1
        case ..<145: 2
        case ..<160: 3
        case ..<175: 4
        default: 5
        }
    }

    // MARK: Post-workout drop

    private static let postWorkout = HeartWorkoutSummaryPostWorkoutHeartGraphData(
        bpmDrop: 42,
        xDates: [
            "2026-07-25T06:57:00Z",
            "2026-07-25T06:58:00Z",
            "2026-07-25T06:59:00Z",
        ],
        xDatesDisplay: ["6:57 AM", "1 MIN", "2 MIN"],
        xBpm: [168, 141, 126],
        yTicks: [110, 175],
        data: (0 ..< 18).map { index in
            let t = Double(index) / 17
            let centre = 168 - (46 * (1 - exp(-3.1 * t)))
            let spread = 4.5 - (1.6 * t)
            return HeartGraphDataStats(
                min: centre - spread,
                max: centre + spread,
                avg: centre
            )
        }
    )

    // MARK: Zone breakdown

    private static let breakdown = HeartWorkoutSummaryBreakdownData(zones: [
        .init(title: "Zone 1", rangeStr: "93-111", duration: TimeDuration(hour: 0, minute: 3), scaleValue: 7),
        .init(title: "Zone 2", rangeStr: "112-130", duration: TimeDuration(hour: 0, minute: 6), scaleValue: 14),
        .init(title: "Zone 3", rangeStr: "131-148", duration: TimeDuration(hour: 0, minute: 19), scaleValue: 42),
        .init(title: "Zone 4", rangeStr: "149-167", duration: TimeDuration(hour: 0, minute: 14), scaleValue: 31),
        .init(title: "Zone 5", rangeStr: "168-186", duration: TimeDuration(hour: 0, minute: 3), scaleValue: 6),
    ])

    // MARK: Splits

    private static let splits: [HeartWorkoutSummarySplit] = [
        .init(splitIndex: 1, duration: TimeDuration(hour: 0, minute: 5), paceSecondsPerKm: 322, avgHeartRate: 138),
        .init(splitIndex: 2, duration: TimeDuration(hour: 0, minute: 5), paceSecondsPerKm: 316, avgHeartRate: 147),
        .init(splitIndex: 3, duration: TimeDuration(hour: 0, minute: 5), paceSecondsPerKm: 328, avgHeartRate: 155),
        .init(splitIndex: 4, duration: TimeDuration(hour: 0, minute: 5), paceSecondsPerKm: 331, avgHeartRate: 159),
        .init(splitIndex: 5, duration: TimeDuration(hour: 0, minute: 5), paceSecondsPerKm: 319, avgHeartRate: 161),
        .init(splitIndex: 6, duration: TimeDuration(hour: 0, minute: 5), paceSecondsPerKm: 308, avgHeartRate: 158),
        .init(splitIndex: 7, duration: TimeDuration(hour: 0, minute: 5), paceSecondsPerKm: 301, avgHeartRate: 163),
        .init(splitIndex: 8, duration: TimeDuration(hour: 0, minute: 5), paceSecondsPerKm: 294, avgHeartRate: 171),
    ]

    // MARK: Route

    struct DemoRoutePoint {
        let latitude: Double
        let longitude: Double
        let zone: Int
    }

    /// A wobbly loop around Centennial Park, Sydney — enough points that the
    /// widget's smoothing and zone-gradient segmenting both have something to do.
    private static let route: [DemoRoutePoint] = {
        let centre = (latitude: -33.8996, longitude: 151.2345)
        let pointCount = 320

        return (0 ..< pointCount).map { index in
            let t = Double(index) / Double(pointCount - 1)
            let angle = t * 2 * .pi

            let radiusLat = 0.0092 * (1 + (0.22 * sin(angle * 3)))
            let radiusLon = 0.0115 * (1 + (0.18 * cos(angle * 2)))

            return DemoRoutePoint(
                latitude: centre.latitude + (radiusLat * sin(angle)),
                longitude: centre.longitude + (radiusLon * cos(angle)),
                zone: zone(forBpm: heartRate(atFraction: t))
            )
        }
    }()
}
