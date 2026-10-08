//
//  BrightDebugBackgroundV5.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

enum BrightDebugLayoutV5 {
    // Flip on to tint each marked section and see exactly where its edges fall.
    static let isEnabled = false
}

extension View {
    @ViewBuilder
    func brightDebugBackgroundV5(_ color: Color) -> some View {
        if BrightDebugLayoutV5.isEnabled {
            background(color.opacity(.veryLowOpacity))
        } else {
            self
        }
    }
}
