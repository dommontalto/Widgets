//
//  NutritionDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 13/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    static var nutritionAppearance: BrightWidgetAppearanceV5 {
        BrightWidgetAppearanceV5(
            title: "Nutrition",
            systemImage: "fork.knife",
            tint: .defaultGreen,
            unit: mealsLoggedToday == 1 ? "meal logged" : "meals logged"
        )
    }

    static var mealsLoggedToday: Double {
        Double(intake.bars(for: .today).compactMap(\.value).filter { $0 >= 300 }.count)
    }
}
