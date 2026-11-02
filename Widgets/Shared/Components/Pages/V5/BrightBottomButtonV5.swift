//
//  BrightBottomButtonV5.swift
//  Widgets
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

private struct BrightBottomButtonV5<Label: View>: ViewModifier {
    let button: Label

    @Environment(\.brightLighthouseRestHeight) private var lighthouseRestHeight
    @State private var keyboardShown = false

    // Lifted clear of the resting Lighthouse bar; otherwise, and while the keyboard
    // covers the bar, it sits just off the bottom.
    private var isLifted: Bool {
        lighthouseRestHeight > .zero && !keyboardShown
    }

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: .spacing0x) {
                button
                    .frame(maxWidth: .infinity)
                    .padding(.top, .spacing2x)
                    .padding(.bottom, isLifted ? .spacing12x : .spacing2x)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                keyboardShown = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardShown = false
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
