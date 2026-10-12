//
//  MindDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 12/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    static let mindAppearance = BrightWidgetAppearanceV5(
        title: "Mind",
        systemImage: "brain.head.profile",
        tint: .defaultBrightPink,
        unit: "min"
    )

    static let mindMinutesToday: Double = 24

    static var mindLatest: Date {
        minutesAgo(45)
    }
}
