//
//  BrightButtonSizes.swift
//  Bright
//
//  Created by Zoe Friedman on 17/8/2023.
//  Copyright © 2023 Bryan Jordan. All rights reserved.
//

import Foundation

enum BrightButtonSizes: CGFloat {
    // Round button size 30pt.
    case small = 30
    // Round button size 36pt.
    case medium = 36
    // Forced by iOS to use for toolbars
    case large = 44
    // Round button size 62pt — the largest, for a screen's single hero control.
    case finalBossLarge = 62

    var defaultFontSize: FontSizes {
        switch self {
        case .small: .body1
        case .medium, .large: .subheading1
        case .finalBossLarge: .standout2
        }
    }

    // The size that carries a screen's hero action: it tints a passed colour
    // rather than filling with it, and gives haptic feedback by default.
    var isPrimary: Bool {
        self == .finalBossLarge
    }

    var glyphSize: CGFloat {
        self == .large ? FontSizes.subheading2.rawValue : rawValue * 0.5
    }
}
