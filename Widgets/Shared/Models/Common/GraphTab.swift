//
//  GraphTab.swift
//  Widgets
//
//  Created by Zoe Friedman on 30/10/2023.
//

import Foundation

public enum GraphTab: String, CaseIterable, TabDisplayable {
    case daily = "D"
    case weekly = "W"
    case monthly = "M"
    case threeMonth = "3M"
    case yearly = "1Y"

    var displayTitle: String {
        rawValue
    }

    var apiValue: String {
        switch self {
        case .daily:
            "day"
        case .weekly:
            "week"
        case .monthly:
            "month"
        case .threeMonth:
            "three_month"
        case .yearly:
            "year"
        }
    }

    var period: GraphPeriod {
        switch self {
        case .daily:
            .day
        case .weekly:
            .week
        case .monthly:
            .month
        case .threeMonth:
            .threeMonth
        case .yearly:
            .year
        }
    }

    var annotationTitle: String {
        switch self {
        case .daily:
            "Total"
        case .weekly, .monthly:
            "Daily Total"
        case .threeMonth:
            "Weekly Average"
        case .yearly:
            "Monthly Average"
        }
    }
}
