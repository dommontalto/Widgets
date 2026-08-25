//
//  ExerciseCompleteModels.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

// Names match the Bright app's Exercise cardio payload so the widgets port back
// unchanged; here they're only ever filled from ExerciseDemoComplete.

struct TimeDuration {
    var hour: Int?
    var minute: Int?
    var second: Int?

    var asString: String {
        var string = ""
        if let hour, hour != 0 {
            string = "\(hour)" + " H"
        }
        if let minute, minute != 0 {
            string += !string.isEmpty ? " " : ""
            string += "\(minute)" + " MIN"
        }
        return string
    }

    var clockString: String {
        String(format: "%02d:%02d:%02d", hour ?? 0, minute ?? 0, second ?? 0)
    }

    var totalSeconds: Double {
        (Double(hour ?? 0) * 3600) + (Double(minute ?? 0) * 60) + Double(second ?? 0)
    }
}

struct Amount {
    var unit: String?
    var value: Double?

    // 1.0 reads as "1", 1.5 as "1.5".
    var displayValue: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: value ?? 0)) ?? ""
    }
}

struct ExerciseCardioSummary {
    var title: String?
    var duration: TimeDuration?
    var energyOut: Amount?
    var startTime: String?
    var endTime: String?
    // Where the session came from, e.g. "Logged with Apple Watch".
    var source: String?
    // Conditions during the session, e.g. "14°".
    var temperature: String?

    var heartGraph: ExerciseCardioHeartGraph?

    var hrAvg: Double?
    var hrPeak: Double?
    var zoneAvg: Int?

    var postSessionHeartGraph: ExerciseCardioPostHeartGraph?
    var breakdown: ExerciseCardioBreakdown?

    var distance: Amount?
    var altitudeGain: Amount?
    var avgPaceSecondsPerKm: Int?

    var altitudeGraph: ExerciseCardioAltitudeGraph?
    var paceGraph: ExerciseCardioPaceGraph?
    var cadenceGraph: ExerciseCardioCadenceGraph?
    var splits: [ExerciseCardioSummarySplit]?
    var intervals: [ExerciseCardioSummaryInterval]?

    var routeLatitudes: [Double]?
    var routeLongitudes: [Double]?
    var routeZoneIndexes: [Int]?

    var hasRoute: Bool {
        !(routeLatitudes ?? []).isEmpty && !(routeLongitudes ?? []).isEmpty
    }
}

// MARK: - Post session heart graph

struct ExerciseCardioPostHeartGraph {
    var bpmDrop: Int?
    var xDates: [String]?
    var xDatesDisplay: [String]?
    var xBpm: [Int?]?
    var yTicks: [Int]?
    var data: [ExerciseCardioMinMax]?
}

struct ExerciseCardioMinMax {
    var min: Double?
    var max: Double?
    var avg: Double?
}

// MARK: - Breakdown

struct ExerciseCardioBreakdown {
    var zones: [Zone]?

    struct Zone {
        var title: String?
        var rangeStr: String?
        var duration: TimeDuration?
        var scaleValue: Int?
    }
}

// MARK: - Performance graph

struct ExerciseCardioHeartGraph {
    var yTicks: [Int]?
    var data: [WorkoutSummaryHeartData]?

    struct WorkoutSummaryHeartData {
        var heartDate: String?
        var value: Int?
        var zone: Int?
    }
}

struct ExerciseCardioAltitudeGraph {
    var yTicks: [Int]?
    var xDates: [String]?
    var data: [Int]?
}

struct ExerciseCardioPaceGraph {
    var yTicks: [Int]?
    var xDates: [String]?
    var data: [Int]?
}

struct ExerciseCardioCadenceGraph {
    var yTicks: [Int]?
    var xDates: [String]?
    var data: [Int]?
}

// MARK: - Split

struct ExerciseCardioSummarySplit {
    var splitIndex: Int?
    var duration: TimeDuration?
    var paceSecondsPerKm: Int?
    var avgHeartRate: Int?
    var zoneIndex: Int?
}

// MARK: - Interval

struct ExerciseCardioSummaryInterval {
    var index: Int?
    var name: String?
    var kind: ExerciseCardioIntervalKind?
    var startTime: String?
    var endTime: String?
    var duration: TimeDuration?
    var distance: Amount?
    var avgHeartRate: Int?
    var maxHeartRate: Int?
    var avgPaceSecondsPerKm: Int?
    var energyOut: Amount?
}

enum ExerciseCardioIntervalKind: String {
    case warmup
    case work
    case rest
    case recovery
    case cooldown
    case other
}
