//
//  BrightWidgetAppearanceV5.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

// What a widget is showing, as its header and reading name it.
struct BrightWidgetAppearanceV5: Hashable {
    let title: String
    let systemImage: String
    let tint: Color
    var unit: String?
}
