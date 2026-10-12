//
//  BrightRevealV5.swift
//  Widgets
//
//  Created by Dom Montalto on 12/10/2026.
//

import SwiftUI

extension EnvironmentValues {
    // Bumping it plays every widget's reveal again.
    @Entry var brightRevealReplay = 0
}

// Turns `isRevealed` on with a bounce the first time a widget appears, so it can grow its
// readings from nothing: rings fill from empty, bars rise, lines draw. With reduce motion
// it's simply on.
private struct BrightRevealV5: ViewModifier {
    @Binding var isRevealed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.brightRevealReplay) private var replay

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !isRevealed else { return }
                reveal()
            }
            .onChange(of: replay) {
                // Emptied without animating, then revealed on the next pass so it grows
                // from nothing rather than from where it was.
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    isRevealed = false
                }
                Task { @MainActor in
                    reveal()
                }
            }
    }

    private func reveal() {
        guard !reduceMotion else {
            isRevealed = true
            return
        }
        withAnimation(.brightReveal) {
            isRevealed = true
        }
    }
}

// Wipes the content in from the leading edge, so a line or a strip draws across. The mask
// runs past the edges so marks that sit on them, like the latest reading's dot, aren't cut.
private struct BrightDrawRevealV5: ViewModifier {
    let isRevealed: Bool

    func body(content: Content) -> some View {
        content
            .mask(alignment: .leading) {
                Rectangle()
                    .padding(-.spacing2x)
                    .scaleEffect(x: isRevealed ? 1 : 0, anchor: .leading)
            }
    }
}

extension View {
    func brightRevealV5(_ isRevealed: Binding<Bool>) -> some View {
        modifier(BrightRevealV5(isRevealed: isRevealed))
    }

    func brightDrawRevealV5(_ isRevealed: Bool) -> some View {
        modifier(BrightDrawRevealV5(isRevealed: isRevealed))
    }
}
