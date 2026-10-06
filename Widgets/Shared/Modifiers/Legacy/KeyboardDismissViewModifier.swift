//
//  KeyboardDismissViewModifier.swift
//  Widgets
//
//  Created by Zoe Friedman on 22/7/2023.
//

import SwiftUI

struct KeyboardDismissViewModifier: ViewModifier {
    class Constant {
        static let swipeThreshold: CGFloat = 50
    }

    func body(content: Content) -> some View {
        content
            .dismissKeyboardOnSwipeDown()
            .dismissKeyboardOnTap()
            .scrollDismissesKeyboard(.interactively)
    }
}
