//
//  Font+StylingExtensions.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

extension Font {
    static func standard(size: FontSizes, weight: Font.Weight) -> Font {
        .system(size: size.rawValue, weight: standardWeight(weight), design: .rounded)
    }

    static func standardUIFont(size: FontSizes, weight: Font.Weight = .regular) -> UIFont? {
        let font = UIFont.systemFont(ofSize: size.rawValue, weight: standardUIWeight(weight))
        guard let rounded = font.fontDescriptor.withDesign(.rounded) else { return font }
        return UIFont(descriptor: rounded, size: size.rawValue)
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

    private static func standardWeight(_ weight: Font.Weight) -> Font.Weight {
        switch weight {
        case .light, .medium: weight
        default: .regular
        }
    }

    private static func standardUIWeight(_ weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .light: .light
        case .medium: .medium
        default: .regular
        }
    }
}
