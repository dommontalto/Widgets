//
//  LighthouseModelSelectorBackground.swift
//  Widgets
//
//  Created by Dom Montalto on 10/9/2026.
//

import SwiftUI

struct LighthouseModelSelectorBackground: View {
    var useThinMaterial: Bool = false

    var body: some View {
        Group {
            if useThinMaterial {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(Color(light: .clear, dark: .black.opacity(.lowOpacity)))
            } else {
                Rectangle()
                    .fill(Color.defaultBackground)
            }
        }
        .ignoresSafeArea()
    }
}
