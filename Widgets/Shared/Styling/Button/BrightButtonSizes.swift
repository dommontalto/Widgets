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
    // Round button size 48pt — the primary control on live/workout screens.
    case extraLarge = 48
    // Round button size 62pt — the largest, for a screen's single hero control.
    case finalBossLarge = 62

    var defaultFontSize: FontSizes {
        switch self {
        case .small: .body1
        case .medium, .large: .subheading1
        case .extraLarge, .finalBossLarge: .standout2
        }
    }

    // The sizes that carry a screen's main action: they tint a passed colour
    // rather than filling with it, and give haptic feedback by default.
    var isPrimary: Bool {
        self == .extraLarge || self == .finalBossLarge
    }
}
