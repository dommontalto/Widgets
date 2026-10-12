//
//  WellbeingDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 9/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    static func wellbeingRings(size: BrightWidgetSizeV5) -> [BrightRingGroupWidgetV5.Ring] {
        let names = size == .small
        return [
            .init(label: "Recovery", shortLabel: "R", value: 15, goal: 100, color: .defaultGreen, caption: names ? "Recovery" : nil, warnsWhenOver: false, image: ImageNames.recoveryV5),
            .init(label: "Fatigue", shortLabel: "F", value: 28, goal: 100, color: .defaultRed, caption: names ? "Fatigue" : nil, warnsWhenOver: false, image: ImageNames.strainV5),
            .init(label: "Readiness", shortLabel: "R", value: 45, goal: 100, color: .defaultCyan, caption: names ? "Readiness" : nil, warnsWhenOver: false, image: ImageNames.stressV5),
        ]
    }

    static func scoreRing(_ score: HealthScoreV5) -> BrightRingGroupWidgetV5.Ring {
        var ring = wellbeingRings(size: .medium)[HealthScoreV5.allCases.firstIndex(of: score) ?? 0]
        ring.heldText = scoreStatus(score)
        return ring
    }

    static func scoreBar(_ score: HealthScoreV5) -> BrightHorizontalBarChartWidgetV5.Bar {
        var scoreBar = bar(scoreRing(score), unit: "%", goalReading: "100%")
        scoreBar.heldReading = scoreStatus(score)
        scoreBar.heldUnit = ""
        return scoreBar
    }

    static func scoreStatus(_ score: HealthScoreV5) -> String {
        switch score {
        case .recovery: "Poor"
        case .fatigue: "Low"
        case .readiness: "Sub-optimal"
        }
    }

    static var scoreBars: [BrightHorizontalBarChartWidgetV5.Bar] {
        wellbeingRings(size: .medium).map { bar($0, unit: "%") }
    }
}
