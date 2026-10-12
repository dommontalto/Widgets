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
        Double(mealHours.count)
    }

    static var mealDetails: [BrightLeadingNumberWidgetV5.Detail] {
        let midnight = Calendar.current.startOfDay(for: anchor)
        return zip(["Breakfast", "Lunch", "Dinner", "Snack"], mealHours).map { name, hour in
            .init(label: name, value: midnight.addingTimeInterval((Double(hour) + 0.5) * 60 * 60).formatted(.brightTime))
        }
    }

    private static var mealHours: [Int] {
        (0 ... currentHour).filter { intake.hourly[$0] >= 300 }
    }
}
