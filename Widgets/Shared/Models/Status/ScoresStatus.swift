//
//  ScoresStatus.swift
//  Widgets
//

import SwiftUI

enum ScoresStatus: String, TabDisplayable {
    case excellent
    case good
    case average
    case subOptimal
    case poor
    case low
    case high
    case noData

    var displayTitle: String {
        switch self {
        case .excellent:
            "EXCELLENT"
        case .good:
            "GOOD"
        case .average:
            "AVERAGE"
        case .subOptimal:
            "SUB-OPTIMAL"
        case .poor:
            "POOR"
        case .low:
            "LOW"
        case .high:
            "HIGH"
        case .noData:
            "NO DATA"
        }
    }

    var color: Color {
        switch self {
        case .excellent, .low:
            Color.defaultBrightGreen
        case .good:
            Color.defaultBlue
        case .average:
            Color.defaultBrightPink
        case .subOptimal:
            Color.defaultOrange
        case .poor, .high:
            Color.defaultRed
        case .noData:
            Color.textColor
        }
    }

    // Maps a 0-100 heart-score percentage onto the qualitative status buckets.
    static func forHeartPercent(_ percent: Int) -> ScoresStatus {
        switch percent {
        case 85 ... 100: .excellent
        case 70 ... 84: .good
        case 55 ... 69: .average
        case 40 ... 54: .subOptimal
        default: .poor
        }
    }
}
