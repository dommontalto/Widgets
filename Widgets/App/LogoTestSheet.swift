//
//  LogoTestSheet.swift
//  Widgets
//

import SwiftUI

// A test bench for the opening logo; play rebuilds it so the animation runs from the start.
struct LogoTestSheet: View {
    @State private var replay = 0

    var body: some View {
        BrightLiquidGlassLogoV5()
            .id(replay)
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                BrightRoundButton(systemImage: "play.fill", size: .finalBossLarge) {
                    replay += 1
                }
                .padding(.bottom, .spacing6x)
            }
    }
}

#Preview {
    LogoTestSheet()
}
