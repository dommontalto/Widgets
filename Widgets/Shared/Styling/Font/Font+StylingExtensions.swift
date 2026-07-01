//
//  Font+StylingExtensions.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

extension Font {
    static func standard(size: FontSizes, weight: Font.Weight) -> Font {
        Font(sfCompactRounded(size: size.rawValue, weight: weight))
    }

    static func standardUIFont(size: FontSizes, weight: Font.Weight = .regular) -> UIFont? {
        sfCompactRounded(size: size.rawValue, weight: weight)
    }

    static func standardSFPro(size: FontSizes, weight: Font.Weight) -> Font {
        Font.system(size: size.rawValue, weight: weight)
    }

    private static func sfCompactRounded(size: CGFloat, weight: Font.Weight) -> UIFont {
        let uiWeight: UIFont.Weight = switch weight {
            case .light:  .light
            case .medium: .medium
            default:      .regular
        }
        let base = UIFont.systemFont(ofSize: size, weight: uiWeight)
        guard let rounded = base.fontDescriptor.withDesign(.rounded),
              let compact = rounded.withSymbolicTraits(rounded.symbolicTraits.union(.traitCondensed))
        else { return base }
        return UIFont(descriptor: compact, size: size)
    }
}
