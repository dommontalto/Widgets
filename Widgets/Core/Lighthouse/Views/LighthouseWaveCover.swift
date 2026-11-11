//
//  LighthouseWaveCover.swift
//  Widgets
//
//  Created by Dom Montalto on 11/11/2026.
//

import SwiftUI

// Lighthouse opens on a distortion wave rising from the dock's plus, and folds back into it on close.
// The wave carries plain backgrounds rather than Lighthouse itself: it keeps three copies of each
// side mounted and can't pass the chat's text field or glass through its shader, so Lighthouse
// fades in over the background the wave leaves behind.
struct LighthouseWaveCover<Content: View>: View {
    // The plus, in the screen's coordinates.
    let source: CGRect
    // Once the wave has folded back, so the cover can go without an animation of its own.
    let onClosed: () -> Void
    @ViewBuilder let content: (_ close: @escaping () -> Void) -> Content

    @State private var isRevealed = false
    @State private var isContentShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            wave(Self.sweepStyle, revealed: .defaultBackground)

            content(close)
                .opacity(isContentShown ? .opaque : .zero)
                .allowsHitTesting(isContentShown)

            // The wave's colour and sparks, over Lighthouse, so they stay on its edges after it has shown.
            wave(Self.glowStyle, revealed: .clear, onFinish: finished)
        }
        .task {
            isRevealed = true
            try? await Task.sleep(for: reduceMotion ? Constants.reducedContentDelay : Constants.contentDelay)
            withAnimation(.brightEaseInOut) { isContentShown = true }
        }
    }

    private func close() {
        withAnimation(.brightEaseInOut) { isContentShown = false }
        isRevealed = false
    }

    private func finished() {
        if !isRevealed {
            onClosed()
        }
    }

    // Both waves share one timing, worked out from all of it, so their fronts stay together.
    private func wave(_ style: DistortionWaveStyle, revealed: Color, onFinish: (() -> Void)? = nil) -> some View {
        DistortionWave(
            isRevealed: isRevealed,
            source: source,
            focus: CGPoint(x: source.midX, y: source.midY),
            style: style,
            onFinish: onFinish
        ) {
            Color.clear
        } revealed: {
            revealed
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private static var timing: DistortionWaveStyle {
        var style = DistortionWaveStyle(type: .vertical)
        style.travel = Constants.travel
        style.linger = Constants.linger
        style.rimFade = Constants.rimFade
        style.hairlineFade = Constants.rimFade
        style.returnSpeed = Constants.returnSpeed
        style.cornerRadius = Double(CGFloat.screenCornerRadius)
        return style
    }

    // Carries the background up behind Lighthouse, with no colour of its own.
    private static var sweepStyle: DistortionWaveStyle {
        var style = timing
        style.strength = .zero
        style.rimStrength = .zero
        style.hairlineOpacity = .zero
        style.particleCount = 0
        return style
    }

    private static var glowStyle: DistortionWaveStyle {
        timing
    }
}

// Outside the struct: a generic type cannot hold static stored properties.
private enum Constants {
    static let travel = 1.4
    // The colour on the screen's edges waits longer behind the front and fades out slower, so it
    // lingers around Lighthouse once it has shown.
    static let linger = 0.6
    static let rimFade = 4.0
    // The wave lasts longer with it, so the close runs quicker to answer at once.
    static let returnSpeed = 2.6
    // Lighthouse shows once the front has passed the middle of the screen.
    static let contentDelay: Duration = .milliseconds(1_300)
    static let reducedContentDelay: Duration = .milliseconds(300)
}
