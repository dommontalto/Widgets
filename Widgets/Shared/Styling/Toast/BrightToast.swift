//
//  BrightToast.swift
//  Widgets
//
//  Created by Zoe Friedman on 21/9/2023.
//

import SwiftUI

enum BrightToast {
    case singleLineWithLogo(text: String)

    case singleLine(text: String)

    case error(text: String)

    case statusPill(text: String, icon: String, color: Color)
}
