//
//  LighthouseChatBackground.swift
//  Widgets
//
//  Created by Dom Montalto on 10/9/2026.
//

import SwiftUI

struct LighthouseChatBackground: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Color(light: .clear, dark: .black.opacity(.mediumOpacity)))
            .ignoresSafeArea()
    }
}
