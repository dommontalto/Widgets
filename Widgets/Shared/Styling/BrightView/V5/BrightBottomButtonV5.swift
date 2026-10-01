//
//  BrightBottomButtonV5.swift
//  Widgets
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

private struct BrightBottomButtonV5<Label: View>: ViewModifier {
    let button: Label

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: .spacing0x) {
                button
                    .frame(maxWidth: .infinity)
                    .padding(.top, .spacing2x)
                    .padding(.bottom, .spacing2x)
            }
    }
}

extension View {
    func brightBottomButtonV5(@ViewBuilder _ button: () -> some View) -> some View {
        modifier(BrightBottomButtonV5(button: button()))
    }
}

#Preview {
    NavigationStack {
        BrightPageViewV5(title: "Personal Details") {
            Text("Content")
        }
        .brightBottomButtonV5 {
            BrightPillButton("Save", buttonSize: .large) {}
        }
    }
}
