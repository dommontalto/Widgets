//
//  DisabledViewModifier.swift
//  Widgets
//
//  Created by Zoe Friedman on 25/7/2023.
//

import SwiftUI

struct DisabledViewModifier: ViewModifier {
    let disabled: Bool

    func body(content: Content) -> some View {
        content
            .disabled(disabled)
            .opacity(disabled ? 0.5 : 1)
    }
}
