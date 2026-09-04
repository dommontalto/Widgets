//
//  Font+StylingExtensions.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

extension Font {
    static func standard(size: FontSizes, weight: Font.Weight) -> Font {
        Font.custom(sfCompactRoundedName(for: weight), size: size.rawValue)
    }

    static func standardUIFont(size: FontSizes, weight: Font.Weight = .regular) -> UIFont? {
        UIFont(name: sfCompactRoundedName(for: weight), size: size.rawValue)
    }

    // Matches the iOS app: the names aren't bundled there either, so both
    // apps take the same fallback and draw symbols at the same size.
    static func standardSFPro(size: FontSizes, weight: Font.Weight) -> Font {
        switch weight {
        case .light: Font.custom("SF-Pro-Text-Light", size: size.rawValue)
        case .medium: Font.custom("SF-Pro-Text-Medium", size: size.rawValue)
        default: Font.custom("SF-Pro-Text-Regular", size: size.rawValue)
        }
    }

    private static func sfCompactRoundedName(for weight: Font.Weight) -> String {
        switch weight {
        case .light: "SFCompactRounded-Light"
        case .medium: "SFCompactRounded-Medium"
        default: "SFCompactRounded-Regular"
        }
    }
}
