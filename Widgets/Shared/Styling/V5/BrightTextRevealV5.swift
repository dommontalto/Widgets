//
//  BrightTextRevealV5.swift
//  Widgets
//
//  Created by Dom Montalto on 25/9/2026.
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

private struct BrightTextRevealV5: ViewModifier {
    var delay: TimeInterval = 0
    var isActive = true
    var onComplete: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var elapsed: TimeInterval = 0
    @State private var layout = BrightTextRevealLayout()

    func body(content: Content) -> some View {
        content
            .textRenderer(BrightTextRevealRenderer(elapsed: reduceMotion ? .infinity : elapsed, layout: layout))
            .task {
                guard isActive, !reduceMotion else {
                    elapsed = .infinity
                    onComplete?()
                    return
                }
                elapsed = 0
                var letters = layout.letterCount
                for _ in 0 ..< BrightTextRevealConstants.layoutPolls where letters == 0 {
                    try? await Task.sleep(for: .milliseconds(16))
                    letters = layout.letterCount
                }
                let duration = BrightTextRevealConstants.duration(forLetters: letters)
                withAnimation(.linear(duration: duration).delay(delay)) {
                    elapsed = duration
                }
                try? await Task.sleep(for: .seconds(delay + duration))
                guard !Task.isCancelled else { return }
                onComplete?()
            }
    }
}

nonisolated private final class BrightTextRevealLayout: @unchecked Sendable {
    var letterCount = 0
}

private struct BrightTextRevealRenderer: TextRenderer, Animatable {
    var elapsed: TimeInterval
    let layout: BrightTextRevealLayout

    var animatableData: TimeInterval {
        get { elapsed }
        set { elapsed = newValue }
    }

    func draw(layout textLayout: Text.Layout, in context: inout GraphicsContext) {
        let slices = textLayout.flatMap { $0 }.flatMap { $0 }
        layout.letterCount = slices.count
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
    static let layoutPolls = 10

    static func duration(forLetters letters: Int) -> TimeInterval {
        Double(max(letters - 1, 0)) * letterStagger + letterDuration
    }
}

extension View {
    func brightTextRevealV5(
        delay: TimeInterval = 0,
        isActive: Bool = true,
        onComplete: (() -> Void)? = nil
    ) -> some View {
        modifier(BrightTextRevealV5(delay: delay, isActive: isActive, onComplete: onComplete))
    }
}
