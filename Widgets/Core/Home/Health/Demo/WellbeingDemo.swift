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
}
