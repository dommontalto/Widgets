//
//  BrightWidgetSizeV5.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

// The footprint a widget takes on the two-column home grid.
enum BrightWidgetSizeV5: String, CaseIterable, Codable, Hashable {
    case small
    case medium
    case large

    var columns: Int {
        self == .small ? 1 : 2
    }

    var rows: Int {
        self == .large ? 2 : 1
    }

    var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        }
    }
}
