//
//  CheckInWidgetModels.swift
//  Widgets
//
//  Created by Dom Montalto on 24/9/2026.
//

import SwiftUI
 
struct ExerciseWeekLoad {
    let name: String
    let strengthFraction: CGFloat
    let cardioFraction: CGFloat
    let ratio: String
}

struct ExerciseTrainingLoad {
    let strengthPercent: Int
    let cardioPercent: Int
    let weeks: [ExerciseWeekLoad]
}

extension String {
    var energyDisplayUnit: String {
        isEmpty ? "Cal" : (lowercased() == "kcal" ? "Cal" : self)
    }
}

extension String? {
    var energyDisplayUnit: String {
        (self ?? "").energyDisplayUnit
    }
}

struct Amount: Codable {
    var unit: String?
    var value: Double?
}

class IntakeBreakdownResponseData: Codable {
    var breakfast: Int?
    var lunch: Int?
    var dinner: Int?
    var snack: Int?
    var drink: Int?
    var unit: String?
    var displayUnit: String {
        unit.energyDisplayUnit
    }
}

enum IntakeGraphData {
    enum BarValueType: String {
        case cumulative = "Intake.Cumulative"
        case breakfast = "Intake.Breakfast"
        case lunch = "Intake.Lunch"
        case dinner = "Intake.Dinner"
        case snack = "Intake.Snack"
        case drink = "Intake.Drink"

        var barColor: Color {
            switch self {
            case .cumulative:
                .textColor
            case .breakfast:
                .defaultBrightGreen
            case .lunch:
                .defaultBrightPink
            case .dinner:
                .defaultBrightViolet
            case .snack:
                .defaultYellow
            case .drink:
                .defaultBlue
            }
        }
    }
}

struct SleepSummaryDataPoint: Codable {
    var date: String?
    var value: Double?
}

struct WeeklyAverage: Codable {
    var week: Int?
    var value: Double?
    var label: String?
}
