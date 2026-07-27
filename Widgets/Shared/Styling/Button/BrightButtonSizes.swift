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

    /// Label size a button of this height should use unless a call site overrides
    /// it — 19pt in a 30pt capsule leaves too little room around the text.
    var defaultFontSize: FontSizes {
        switch self {
        case .small: .body1
        case .medium, .large: .subheading1
        }
    }
}
