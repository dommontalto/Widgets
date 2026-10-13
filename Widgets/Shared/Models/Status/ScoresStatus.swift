//
//  ScoresStatus.swift
//  Widgets
//

import SwiftUI

enum ScoresStatus: String, TabDisplayable {
    case optimal
    case borderline
    case low
    case high

    init?(label: String?) {
        guard let label, let status = ScoresStatus(rawValue: label.lowercased()) else { return nil }
        self = status
    }

    var displayTitle: String {
        switch self {
        case .optimal:
            "OPTIMAL"
        case .borderline:
            "BORDERLINE"
        case .low:
            "LOW"
        case .high:
            "HIGH"
        }
    }

    var color: Color {
        switch self {
        case .optimal:
            Color.defaultBrightGreen
        case .borderline:
            Color.defaultYellow
        case .low, .high:
            Color.defaultRed
        }
    }

    static func forHeartPercent(_ percent: Int) -> ScoresStatus {
        switch percent {
        case 70 ... 100: .optimal
        case 40 ... 69: .borderline
        default: .low
        }
    }
}
