//
//  ExerciseDemoComplete.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

enum ExerciseDemoComplete {
    // Every logged session opens the same demo data for its kind, wearing the
    // name of the row that was tapped.
    // One part per icon in the sheet's picker: every gym and bodyweight exercise
    // sits under a single section, while each cardio and each sport gets its
    // own — two runs are two sections, not one.
    static func sessions(for session: ExerciseLoggedSession) -> [ExerciseCompleteSession] {
        let parts = session.parts.isEmpty ? defaultParts(for: session.type) : session.parts
        return parts.map { Self.session(for: $0, titled: session.name) }
    }

    private static func defaultParts(for type: ExerciseDayType) -> [ExerciseCategory] {
        switch type {
        case .cardio: [.cardio]
        case .both: [.gym, .cardio]
        case .strength, .rest: [.gym]
        }
    }

    private static func session(
        for category: ExerciseCategory,
        titled title: String
    ) -> ExerciseCompleteSession {
        switch category {
        case .cardio: session(cardio, titled: title)
        case .sports: session(sports, titled: title)
        case .gym, .bodyweight: session(strength, titled: title)
        }
    }

    private static func session(
        _ session: ExerciseCompleteSession,
        titled title: String
    ) -> ExerciseCompleteSession {
        var copy = session
        copy.summary.title = title
        return copy
    }

    static let cardio = ExerciseCompleteSession(
        summary: cardioSummary,
        metrics: cardioMetrics,
        strain: strain,
        records: cardioRecords,
        intervals: intervalStrip,
        category: .cardio
    )

    static let strength = ExerciseCompleteSession(
        summary: strengthSummary,
        metrics: strengthMetrics,
        strain: strain,
        exertion: exertion,
        records: strengthRecords,
        progressions: progressions
    )

    static let sports = ExerciseCompleteSession(
        summary: sportsSummary,
        metrics: sportsMetrics,
        strain: strain,
        records: cardioRecords,
        category: .sports
    )

    // MARK: Summaries

    // A match is timed and tracked but not run to a route, so it carries no map
    // and no splits.
    private static let sportsSummary: HeartWorkoutSummaryResponseData = {
        var session = cardioSummary
        session.title = "Football"
        session.duration = TimeDuration(hour: 1, minute: 5, second: 0)
        session.distance = nil
        session.altitudeGain = nil
        session.avgPaceSecondsPerKm = nil
        session.splits = nil
        session.intervals = nil
        session.routeLatitudes = nil
        session.routeLongitudes = nil
        session.routeZoneIndexes = nil
        return session
    }()

    private static let strengthSummary: HeartWorkoutSummaryResponseData = {
        var session = cardioSummary
        session.title = "Quick Push"
        session.duration = TimeDuration(hour: 0, minute: 45, second: 43)
        session.source = "Logged with iPhone"
        // A gym session has no route, splits or intervals to show.
        session.distance = nil
        session.altitudeGain = nil
        session.avgPaceSecondsPerKm = nil
        session.splits = nil
        session.intervals = nil
        session.routeLatitudes = nil
        session.routeLongitudes = nil
        session.routeZoneIndexes = nil
        return session
    }()

    private static let cardioSummary = HeartWorkoutSummaryResponseData(
        title: "Outdoor Run",
        duration: TimeDuration(hour: 0, minute: 45, second: 54),
        energyOut: Amount(unit: "kcal", value: 512),
        startTime: "2026-07-25T06:12:00Z",
        endTime: "2026-07-25T06:57:00Z",
        source: "Logged with Apple Watch",
        temperature: "14°",
        heartGraph: HeartWorkoutSummaryHeartGraphData(
            yTicks: [65, 152],
            data: heartSamples
        ),
        hrAvg: 98,
        hrPeak: 154,
        zoneAvg: 3,
        postWorkoutHeartGraph: recoveryDrop,
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
        intervals: intervals,
        routeLatitudes: route.map(\.latitude),
        routeLongitudes: route.map(\.longitude),
        routeZoneIndexes: route.map(\.zone)
    )

    // MARK: Graph samples

    private static let sampleCount = 140
    private static let durationSeconds: Double = 45 * 60

    private enum Constants {
        static let lowestBpm: Double = 72
        static let peakBpm: Double = 145
    }

    private static var heartSamples: [HeartWorkoutSummaryHeartGraphData.WorkoutSummaryHeartData] {
        let base = "2026-07-25T06:12:00Z".isoStringToDate()
        let raw = (0 ..< sampleCount).map { heartRate(atFraction: Double($0) / Double(sampleCount - 1)) }

        // Fitted to the range the card draws its axis against, so the trace
        // fills the plot and its high point lands on the peak rule.
        let lowest = raw.min() ?? 0
        let span = max((raw.max() ?? 1) - lowest, 1)

        return raw.indices.map { index in
            let t = Double(index) / Double(sampleCount - 1)
            let bpm = Constants.lowestBpm
                + ((raw[index] - lowest) / span) * (Constants.peakBpm - Constants.lowestBpm)
            let date = base.addingTimeInterval(t * durationSeconds)

            return .init(
                heartDate: date.isoString,
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

    // Hard early efforts that settle into a long decline, with the beat-to-beat
    // scatter dying away as it does.
    private static func heartRate(atFraction t: Double) -> Double {
        let decline = 112 - (30 * pow(t, 0.8))
        let hump = 18 * exp(-pow((t - 0.26) / 0.13, 2))
        let scatter = noise(t) * ((22 * (1 - t)) + 3)
        return decline + hump + scatter
    }

    // A hash rather than a random draw, so the trace is the same every render.
    private static func noise(_ t: Double) -> Double {
        let x = sin(t * 1_271.13) * 43_758.5453
        return ((x - x.rounded(.down)) * 2) - 1
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

    // MARK: Post-session drop

    private static let recoveryDrop = HeartWorkoutSummaryPostWorkoutHeartGraphData(
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
            return HeartGraphResponseDataStats(
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
        .init(splitIndex: 1, duration: TimeDuration(minute: 5, second: 8), paceSecondsPerKm: 308, avgHeartRate: 138, zoneIndex: 2),
        .init(splitIndex: 2, duration: TimeDuration(minute: 3, second: 20), paceSecondsPerKm: 200, avgHeartRate: 159, zoneIndex: 4),
        .init(splitIndex: 3, duration: TimeDuration(minute: 5, second: 13), paceSecondsPerKm: 313, avgHeartRate: 159, zoneIndex: 3),
        .init(splitIndex: 4, duration: TimeDuration(minute: 4, second: 48), paceSecondsPerKm: 288, avgHeartRate: 151, zoneIndex: 3),
        .init(splitIndex: 5, duration: TimeDuration(minute: 5, second: 28), paceSecondsPerKm: 328, avgHeartRate: 157, zoneIndex: 3),
        .init(splitIndex: 6, duration: TimeDuration(minute: 5, second: 2), paceSecondsPerKm: 302, avgHeartRate: 158, zoneIndex: 3),
        .init(splitIndex: 7, duration: TimeDuration(minute: 4, second: 55), paceSecondsPerKm: 295, avgHeartRate: 163, zoneIndex: 4),
        .init(splitIndex: 8, duration: TimeDuration(minute: 4, second: 40), paceSecondsPerKm: 280, avgHeartRate: 171, zoneIndex: 5),
    ]

    // MARK: Intervals

    private static let intervals: [HeartWorkoutSummaryInterval] = [
        .init(
            index: 1,
            kind: .warmup,
            duration: TimeDuration(hour: 0, minute: 6, second: 0),
            distance: Amount(unit: "M", value: 1_020),
            avgHeartRate: 128,
            maxHeartRate: 141,
            avgPaceSecondsPerKm: 353
        ),
        .init(
            index: 1,
            kind: .work,
            duration: TimeDuration(hour: 0, minute: 4, second: 0),
            distance: Amount(unit: "M", value: 890),
            avgHeartRate: 164,
            maxHeartRate: 172,
            avgPaceSecondsPerKm: 270
        ),
        .init(
            index: 1,
            kind: .rest,
            duration: TimeDuration(hour: 0, minute: 2, second: 0),
            distance: Amount(unit: "M", value: 300),
            avgHeartRate: 141,
            maxHeartRate: 158,
            avgPaceSecondsPerKm: 400
        ),
        .init(
            index: 2,
            kind: .work,
            duration: TimeDuration(hour: 0, minute: 4, second: 0),
            distance: Amount(unit: "M", value: 905),
            avgHeartRate: 168,
            maxHeartRate: 176,
            avgPaceSecondsPerKm: 265
        ),
        .init(
            index: 2,
            kind: .rest,
            duration: TimeDuration(hour: 0, minute: 2, second: 0),
            distance: Amount(unit: "M", value: 295),
            avgHeartRate: 144,
            maxHeartRate: 160,
            avgPaceSecondsPerKm: 407
        ),
        .init(
            index: 3,
            kind: .work,
            duration: TimeDuration(hour: 0, minute: 4, second: 0),
            distance: Amount(unit: "M", value: 920),
            avgHeartRate: 172,
            maxHeartRate: 181,
            avgPaceSecondsPerKm: 261
        ),
        .init(
            index: 3,
            kind: .rest,
            duration: TimeDuration(hour: 0, minute: 2, second: 0),
            distance: Amount(unit: "M", value: 290),
            avgHeartRate: 146,
            maxHeartRate: 162,
            avgPaceSecondsPerKm: 414
        ),
        .init(
            index: 4,
            kind: .work,
            duration: TimeDuration(hour: 0, minute: 4, second: 0),
            distance: Amount(unit: "M", value: 935),
            avgHeartRate: 175,
            maxHeartRate: 184,
            avgPaceSecondsPerKm: 257
        ),
        .init(
            index: 1,
            kind: .cooldown,
            duration: TimeDuration(hour: 0, minute: 5, second: 54),
            distance: Amount(unit: "M", value: 1_085),
            avgHeartRate: 132,
            maxHeartRate: 149,
            avgPaceSecondsPerKm: 326
        ),
    ]

    // MARK: Route

    struct DemoRoutePoint {
        let latitude: Double
        let longitude: Double
        let zone: Int
    }

    // A wobbly loop around Centennial Park, Sydney — enough points that the
    // widget's smoothing and zone-gradient segmenting both have something to do.
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

// MARK: - Summary

extension ExerciseDemoComplete {
    // The six a run can report. Against the backend this is built from whatever
    // the payload actually carries: a metric with nothing to say — nil or zero —
    // is left out of the list rather than shown empty, so its icon, label and
    // unit go with it and the grid closes up around the gap.
    fileprivate static let cardioMetrics: [ExerciseCompleteMetric] = [
        .init(icon: .asset(ImageNames.durationV5), title: "Duration", value: "00:32:43"),
        .init(icon: .asset(ImageNames.energyBurntV5), title: "Energy used", value: "329 Cal"),
        .init(
            icon: .system("lines.measurement.horizontal.aligned.bottom", tint: .defaultGreen),
            title: "Distance",
            value: "5.5 KM"
        ),
        .init(icon: .system("timer", tint: .defaultPurple), title: "Pace", value: "5\u{2019}23"),
        .init(icon: .asset(ImageNames.heartPulseRedV5), title: "AVG HR", value: "154 BPM"),
        .init(icon: .asset(ImageNames.altitudeGainV5), title: "Altitude gain", value: "96 M"),
    ]

    fileprivate static let sportsMetrics: [ExerciseCompleteMetric] = [
        .init(icon: .asset(ImageNames.durationV5), title: "Duration", value: "01:05:00"),
        .init(icon: .asset(ImageNames.energyBurntV5), title: "Energy used", value: "612 Cal"),
        .init(icon: .asset(ImageNames.heartPulseRedV5), title: "AVG HR", value: "146 BPM"),
        .init(
            icon: .system("figure.rugby", tint: .defaultOrange),
            title: "Sport",
            value: "Football"
        ),
    ]

    fileprivate static let strengthMetrics: [ExerciseCompleteMetric] = [
        .init(icon: .asset(ImageNames.durationV5), title: "Duration", value: "00:45:43"),
        .init(icon: .asset(ImageNames.energyBurntV5), title: "Energy used", value: "329 Cal"),
        .init(
            icon: .system("text.line.3.summary", tint: .defaultGreen),
            title: "Total Reps",
            value: "24"
        ),
        .init(
            icon: .system("scalemass.fill", tint: .defaultBrightViolet),
            title: "Total weight",
            value: "400 KG"
        ),
    ]

    fileprivate static let strain = ExerciseCompleteStrain(value: 43, label: "High")

    fileprivate static let intervalStrip = ExerciseCompleteIntervalStrip(
        steps: [
            .init(
                symbol: "figure.cooldown",
                title: "Warmup",
                metrics: intervalMetrics(duration: "00:05:12", energy: "48 Cal", distance: "0.8 KM", pace: "6\u{2019}30"),
                route: 0 ... 0.18,
                tint: .defaultOrange
            ),
            .init(
                symbol: "figure.run",
                title: "Run",
                metrics: intervalMetrics(duration: "00:08:40", energy: "104 Cal", distance: "1.7 KM", pace: "5\u{2019}06"),
                route: 0.18 ... 0.42,
                tint: .defaultRed
            ),
            .init(
                symbol: "figure.walk",
                title: "Walk",
                metrics: intervalMetrics(duration: "00:03:25", energy: "22 Cal", distance: "0.3 KM", pace: "11\u{2019}23"),
                route: 0.42 ... 0.52,
                tint: .defaultSkyBlue
            ),
            .init(
                symbol: "figure.run",
                title: "Run",
                metrics: intervalMetrics(duration: "00:10:14", energy: "128 Cal", distance: "2.1 KM", pace: "4\u{2019}52"),
                route: 0.52 ... 0.85,
                tint: .defaultRed
            ),
            .init(
                symbol: "snowflake",
                title: "Cooldown",
                metrics: intervalMetrics(duration: "00:05:12", energy: "27 Cal", distance: "0.6 KM", pace: "8\u{2019}40"),
                route: 0.85 ... 1,
                tint: .defaultBlue
            ),
            .init(symbol: "flag.pattern.checkered", title: "Finish"),
        ],
        // The run is over, so it opens on the finish.
        selectedIndex: 5
    )

    private static func intervalMetrics(
        duration: String,
        energy: String,
        distance: String,
        pace: String
    ) -> [ExerciseCompleteMetric] {
        [
            .init(icon: .asset(ImageNames.durationV5), title: "Duration", value: duration),
            .init(icon: .asset(ImageNames.energyBurntV5), title: "Energy used", value: energy),
            .init(
                icon: .system("lines.measurement.horizontal.aligned.bottom", tint: .defaultGreen),
                title: "Distance",
                value: distance
            ),
            .init(icon: .system("timer", tint: .defaultPurple), title: "Pace", value: pace),
        ]
    }
}

// MARK: - Exertion

extension ExerciseDemoComplete {
    fileprivate static let exertion = ExerciseCompleteExertion(
        average: 8,
        label: "High",
        peaks: [
            .init(name: "Bench Press", detail: "4th Set", rpe: 9),
            .init(name: "Squat", detail: "6th Set", rpe: 10),
        ]
    )
}

// MARK: - Personal records

extension ExerciseDemoComplete {
    fileprivate static let strengthRecords: [ExerciseCompleteRecord] = [
        .init(
            badge: ImageNames.exerciseRecordHexagonGoldV5,
            glyph: .symbol("trophy.fill"),
            title: "Bench Press",
            detail: "Heaviest",
            value: "100 KG",
            exercise: "Bench Press"
        ),
        .init(
            badge: ImageNames.exerciseRecordHexagonGoldV5,
            glyph: .symbol("trophy.fill"),
            title: "Barbell Squat",
            detail: "Most reps",
            value: "23 reps",
            exercise: "Squat"
        ),
    ]

    fileprivate static let cardioRecords: [ExerciseCompleteRecord] = [
        .init(
            badge: ImageNames.exerciseRecordHexagonV5,
            glyph: .captioned("1K", symbol: "hare.fill"),
            title: "Fastest Mile",
            detail: "",
            value: "5\u{2019}12"
        ),
        .init(
            badge: ImageNames.exerciseRecordHexagonV5,
            glyph: .symbol("lines.measurement.horizontal.aligned.bottom"),
            title: "Longest Distance",
            detail: "",
            value: "32 KM"
        ),
    ]
}

// MARK: - Progression

extension ExerciseDemoComplete {
    fileprivate static let progressions: [ExerciseCompleteProgression] = [
        .init(
            exercise: "Bench Press",
            direction: .increased,
            change: "2.5 KG",
            sets: [
                .init(label: "Warmup", detail: "12 x 40 KG", rpe: 9),
                .init(label: "Set 1", detail: "12 x 40 KG", rpe: 9),
                .init(label: "Set 2", detail: "12 x 40 KG", rpe: 9),
                .init(label: "Set 3", detail: "3 x 40 KG", failedRep: "Rep 3", rpe: 9),
                .init(label: "Dropset", detail: "12 x 40 KG", rpe: 9),
            ]
        ),
        .init(
            exercise: "Barbell Squat",
            direction: .unchanged,
            change: "2.5 KG",
            sets: [
                .init(label: "Warmup", detail: "12 x 40 KG"),
                .init(label: "Set 1", detail: "12 x 40 KG"),
                .init(label: "Set 2", detail: "12 x 40 KG", failedRep: "Rep 3"),
                .init(label: "Set 3", detail: "3 x 40 KG", isSkipped: true),
                .init(label: "Dropset", detail: "12 x 40 KG", isSkipped: true),
            ]
        ),
        .init(
            exercise: "Barbell Squat",
            direction: .decreased,
            change: "2.5 KG",
            sets: [
                .init(label: "Warmup", detail: "12 x 40 KG", rpe: 9),
                .init(label: "Set 1", detail: "12 x 40 KG", rpe: 9),
                .init(label: "Set 2", detail: "12 x 40 KG", rpe: 9),
                .init(label: "Set 3", detail: "3 x 40 KG", failedRep: "Rep 3", rpe: 9),
                .init(label: "Dropset", detail: "12 x 40 KG", rpe: 9),
            ]
        ),
    ]
}

// MARK: - One exercise's history

extension ExerciseDemoComplete {
    // The same card the complete sheet shows on Performance, one per session the
    // exercise appears in.
    static let exerciseHistory: [ExerciseCompleteProgression] = [
        .init(
            exercise: "Bench Press",
            direction: .increased,
            change: "2.5 KG",
            sets: [
                .init(label: "Warmup", detail: "12 x 40 KG", rpe: 7),
                .init(label: "Set 1", detail: "10 x 60 KG", rpe: 8),
                .init(label: "Set 2", detail: "10 x 60 KG", rpe: 9),
                .init(label: "Set 3", detail: "8 x 60 KG", failedRep: "Rep 9", rpe: 9),
            ],
            date: "23 Jul"
        ),
        .init(
            exercise: "Bench Press",
            direction: .unchanged,
            change: "0 KG",
            sets: [
                .init(label: "Warmup", detail: "12 x 40 KG", rpe: 7),
                .init(label: "Set 1", detail: "10 x 57.5 KG", rpe: 8),
                .init(label: "Set 2", detail: "10 x 57.5 KG", rpe: 8),
                .init(label: "Set 3", detail: "10 x 57.5 KG", isSkipped: true),
            ],
            date: "16 Jul"
        ),
        .init(
            exercise: "Bench Press",
            direction: .decreased,
            change: "2.5 KG",
            sets: [
                .init(label: "Warmup", detail: "12 x 40 KG", rpe: 6),
                .init(label: "Set 1", detail: "10 x 55 KG", rpe: 8),
                .init(label: "Set 2", detail: "9 x 55 KG", failedRep: "Rep 10", rpe: 10),
                .init(label: "Dropset", detail: "8 x 40 KG", rpe: 9),
            ],
            date: "9 Jul"
        ),
    ]
}
