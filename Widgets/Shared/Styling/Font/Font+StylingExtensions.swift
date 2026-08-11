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

    // SF Pro is the system typeface, so there is nothing to bundle.
    static func standardSFPro(size: FontSizes, weight: Font.Weight) -> Font {
        Font.system(size: size.rawValue, weight: weight)
    }

    private static func sfCompactRoundedName(for weight: Font.Weight) -> String {
        switch weight {
        case .light: "SFCompactRounded-Light"
        case .medium: "SFCompactRounded-Medium"
        default: "SFCompactRounded-Regular"
        }
    }
}
