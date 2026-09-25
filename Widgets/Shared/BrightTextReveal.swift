//
//  BrightTextReveal.swift
//  Widgets
//
//  Created by Dom Montalto on 25/9/2026.
//

import SwiftUI

// A staggered blur-in: each letter rises and sharpens out of a blur, a beat
// after the one before it, wrapped lines and all.
struct BrightTextReveal: ViewModifier {
    var delay: TimeInterval = 0
    var isActive = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var elapsed: TimeInterval = 0

    func body(content: Content) -> some View {
        content
            .textRenderer(BrightTextRevealRenderer(elapsed: reduceMotion ? .infinity : elapsed))
            .onAppear {
                guard isActive else {
                    elapsed = BrightTextRevealConstants.totalDuration
                    return
                }
                elapsed = 0
                withAnimation(.linear(duration: BrightTextRevealConstants.totalDuration).delay(delay)) {
                    elapsed = BrightTextRevealConstants.totalDuration
                }
            }
    }
}

private struct BrightTextRevealRenderer: TextRenderer, Animatable {
    var elapsed: TimeInterval

    var animatableData: TimeInterval {
        get { elapsed }
        set { elapsed = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let slices = layout.flatMap { $0 }.flatMap { $0 }
        for (index, slice) in slices.enumerated() {
            let start = Double(index) * BrightTextRevealConstants.letterStagger
            let linear = min(max((elapsed - start) / BrightTextRevealConstants.letterDuration, 0), 1)
            let progress = 1 - pow(1 - linear, 3)

            var letter = context
            letter.opacity = progress
            letter.addFilter(.blur(radius: BrightTextRevealConstants.letterBlur * (1 - progress)))
            letter.translateBy(x: 0, y: BrightTextRevealConstants.letterRise * (1 - progress))
            letter.draw(slice)
        }
    }
}

private enum BrightTextRevealConstants {
    static let letterBlur: CGFloat = 8
    static let letterRise: CGFloat = .spacing2x
    static let letterDuration: TimeInterval = 0.4
    static let letterStagger: TimeInterval = 0.03
    // Long enough for a sentence's last letter to land.
    static let totalDuration: TimeInterval = 2
}

extension View {
    func brightTextReveal(delay: TimeInterval = 0, isActive: Bool = true) -> some View {
        modifier(BrightTextReveal(delay: delay, isActive: isActive))
    }
}
