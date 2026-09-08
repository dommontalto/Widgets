//
//  HealthModels.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

enum HealthWidgetSize {
    case oneByOne
    case twoByOne
    case twoByTwo

    var columns: Int {
        switch self {
        case .oneByOne: 1
        case .twoByOne, .twoByTwo: 2
        }
    }

    var rows: Int {
        switch self {
        case .oneByOne, .twoByOne: 1
        case .twoByTwo: 2
        }
    }
}

// MARK: - Sleep

struct HealthDashboardSleepData {
    var sleepStart: Date
    var sleepEnd: Date
    var score: Int
    var durationHours: Int
    var durationMinutes: Int
    var values: [SleepGraphResponseValues]
    var heartRate: Int?
}

struct SleepGraphResponseValues {
    var start: Date
    var end: Date
    var sleepState: SleepState

    enum SleepState: Int {
        case inBed = 0
        case aSleep = 1
        case awake = 2
        case light = 3
        case deep = 4
        case rem = 5

        var color: Color {
            switch self {
            case .inBed: ThemeColor.inBed
            case .aSleep: ThemeColor.asleep
            case .awake: ThemeColor.awake
            case .light: ThemeColor.light
            case .deep: ThemeColor.deep
            case .rem: ThemeColor.rem
            }
        }
    }
}

// MARK: - Heart

struct HealthDashboardHeartData {
    var hrAvg: Int?
    var hrData: [Int]?
    var hrTime: [String]?
    var hrHigh: Int?
    var hrLow: Int?
    var hasData: Bool?
}

// MARK: - Activity

struct ActivityGraphData {
    var barValues: [BarValue]
    var unit: String
    var highestValue: Double

    struct BarValue: Identifiable {
        let id = UUID()
        var date: Date
        var activeValue: Double
        var restingValue: Double
    }

    enum BarValueType {
        case active
        case resting

        var barColor: Color {
            switch self {
            case .active: .defaultBrightPink
            case .resting: .defaultPurple
            }
        }
    }
}

struct ActivityTdeeBreakdownResponseData {
    var bmr: Int?
    var neat: Int?
    var tef: Int?
    var eat: Int?
    var unit: String?

    var displayUnit: String {
        guard let unit, !unit.isEmpty else { return "Cal" }
        return unit.lowercased() == "kcal" ? "Cal" : unit
    }
}

// MARK: - Graph helpers

enum GraphHelpers {
    // Y-axis marks stepped to the nearest 25 so the labels land on round numbers.
    static func calculatedYAxisMarks(calculatedMaxValue: Double, desiredCount: Int = 4) -> [Double] {
        let rawStep = calculatedMaxValue / Double(desiredCount - 1)
        let roundedStep = (rawStep / 25).rounded() * 25
        return (0 ..< desiredCount).map { Double($0) * roundedStep }
    }
}
