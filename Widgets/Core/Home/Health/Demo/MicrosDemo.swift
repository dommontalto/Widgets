//
//  MicrosDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 16/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    static let microColors: [Color] = [.defaultCyan, .defaultYellow, .defaultPink, .defaultGreen]

    static func microRings(_ nutrients: [HealthNutrientV5]) -> [BrightRingGroupWidgetV5.Ring] {
        nutrients.enumerated().map { index, nutrient in
            let reading = microReading(nutrient)
            return .init(
                label: nutrient.title,
                shortLabel: nutrient.shortLabel,
                value: reading.current,
                goal: reading.target,
                color: microColors[index % microColors.count],
                decimals: reading.target < 10 ? 1 : 0,
                warnsWhenOver: nutrient.isLimit
            )
        }
    }

    static func microReading(_ nutrient: HealthNutrientV5) -> (current: Double, target: Double) {
        switch nutrient {
        case .sodium: (1_640, 2_300)
        case .sugar: (42, 50)
        case .saturatedFat: (14, 20)
        case .cholesterol: (210, 300)
        case .caffeine: (280, 400)
        case .alcohol: (1.5, 2)
        case .fibre: (21, 30)
        case .calcium: (760, 1_000)
        case .iron: (11, 18)
        case .magnesium: (290, 420)
        case .potassium: (2_600, 3_400)
        case .zinc: (9, 11)
        case .vitaminB12: (1.8, 2.4)
        case .vitaminC: (70, 90)
        case .vitaminD: (6, 15)
        }
    }
}
