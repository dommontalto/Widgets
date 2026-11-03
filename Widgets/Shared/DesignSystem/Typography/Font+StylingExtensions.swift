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

    static func standardSFPro(size: FontSizes, weight: Font.Weight) -> Font {
        if weight == .regular {
            Font.custom("SF-Pro-Text-Regular", size: size.rawValue)
        } else if weight == .medium {
            Font.custom("SF-Pro-Text-Medium", size: size.rawValue)
        } else {
            Font.custom("SF-Pro-Text-Regular", size: size.rawValue)
        }
    }

    private static func standardWeight(_ weight: Font.Weight) -> Font.Weight {
        weight == .medium ? .medium : .regular
    }

    private static func standardUIWeight(_ weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .medium: .medium
        default: .regular
        }
    }
}
