//
//  BrightButtonSizes.swift
//  Bright
//
//  Created by Zoe Friedman on 17/8/2023.
//  Copyright © 2023 Bryan Jordan. All rights reserved.
//

import Foundation

enum BrightButtonSizes: CGFloat {
    /// Round button size 30pt.
    case small = 30
    /// Round button size 36pt.
    case medium = 36
    /// Forced by iOS to use for toolbars
    case large = 44
    /// Round button size 62pt — the primary control on live/session screens.
    case extraLarge = 62

    var defaultFontSize: FontSizes {
        switch self {
        case .small: .body1
        case .medium, .large: .subheading1
        case .extraLarge: .standout2
        }
    }
}
