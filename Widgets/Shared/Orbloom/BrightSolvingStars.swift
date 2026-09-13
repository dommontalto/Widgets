//
//  BrightSolvingStars.swift
//  Widgets
//
//  Created by Dom Montalto on 14/9/2026.
//

import SwiftUI

// SwiftUI port of Orbloom, the voice-reactive orb from Ricky Bharti's component
// vault (https://vault.rickybharti.com/orbloom). The sphere itself is the
// site's WebGL fragment shader rewritten in Metal (`OrbloomShaders.metal`) and
// drawn through `colorEffect`; the spin, audio smoothing and state fade that
// the site keeps in JavaScript live in `OrbloomMotionDriver`; the glass
// chrome and the slow ambient bob are its CSS, rebuilt as views.
//
// `audioLevel` is a normalised 0…1 loudness. Feed it from whatever is
// speaking and the orb brightens, pulses and spins with it.
struct BrightSolvingStars: View {
    var theme: OrbloomTheme = .default
    var state: OrbloomState = .idle
    // nil fills whatever space the orb is given, as the largest square that
    // fits, so it scales with the screen.
    var size: CGFloat? = nil
    var quality: OrbloomQuality = .high
    var audioLevel: Double = 0
    // nil follows the theme's own float; pass `.off` to pin the orb in place.
    var ambientMotion: OrbloomAmbientMotion? = nil
    var shellBlur: CGFloat = Chrome.defaultShellBlur

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale

    @State private var driver = OrbloomMotionDriver()

    var body: some View {
        if let size {
            orb(side: size)
        } else {
            GeometryReader { proxy in
                orb(side: min(proxy.size.width, proxy.size.height))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func orb(side: CGFloat) -> some View {
        if reduceMotion {
            sphere(driver.frame(at: .now, theme: theme, state: state, audioLevel: audioLevel, reduceMotion: true), side: side)
        } else {
            TimelineView(.animation(minimumInterval: 1 / quality.frameRate)) { context in
                let frame = driver.frame(
                    at: context.date,
                    theme: theme,
                    state: state,
                    audioLevel: audioLevel,
                    reduceMotion: false
                )
                let bob = ambientOffset(at: driver.elapsed(at: context.date))
                sphere(frame, side: side)
                    .scaleEffect(bob.scale)
                    .offset(y: bob.y)
            }
        }
    }

    private func sphere(_ frame: OrbloomMotionDriver.Frame, side: CGFloat) -> some View {
        Rectangle()
            .fill(Color.black)
            .colorEffect(shader(for: frame, side: side))
            .overlay(chrome)
            .frame(width: side, height: side)
            .accessibilityLabel("Animated voice-reactive orb")
    }

    private func shader(for frame: OrbloomMotionDriver.Frame, side: CGFloat) -> Shader {
        ShaderLibrary.default.orbloom(
            .float2(CGSize(width: side, height: side)),
            .float(renderResolution(side: side)),
            .float(frame.time),
            .float(theme.phase),
            .float(Double(theme.archetype.rawValue)),
            .float(theme.lensStrength),
            .float(theme.appearance.intensity),
            .float(theme.appearance.detail),
            .float(theme.appearance.glow),
            .float(frame.spin),
            .float(frame.audioBrightness),
            .float(frame.audioPulse),
            .float(Double(state.rawValue)),
            .float(frame.stateBlend),
            rgb(theme.interiorColor),
            rgb(theme.baseColor),
            rgb(theme.accentPrimary),
            rgb(theme.accentSecondary),
            rgb(theme.accentHighlight)
        )
    }

    private func rgb(_ color: SIMD3<Float>) -> Shader.Argument {
        .float3(color.x, color.y, color.z)
    }

    // The pixel diameter the site would have rendered at: device pixels, capped
    // by the quality profile. The shader scales its grain and star sharpness
    // off this so small orbs don't fill with noise.
    private func renderResolution(side: CGFloat) -> CGFloat {
        min(quality.maxResolution, side * min(quality.maxPixelRatio, displayScale))
    }

    // MARK: - Ambient motion

    // The CSS `orb-ambient-motion` keyframe: rest → lifted and scaled at the
    // midpoint → rest, eased in and out, repeating after an initial delay.
    private func ambientOffset(at elapsed: Double) -> (y: CGFloat, scale: CGFloat) {
        let motion = ambientMotion ?? theme.ambientMotion
        guard motion.isEnabled, motion.duration > 0 else { return (0, 1) }
        let local = elapsed - motion.delay
        guard local >= 0 else { return (0, 1) }
        let progress = (local / motion.duration).truncatingRemainder(dividingBy: 1)
        let wave = CGFloat(0.5 - 0.5 * cos(2 * .pi * progress))
        return (-motion.verticalTravel * wave, 1 + (motion.scale - 1) * wave)
    }

    // MARK: - Chrome

    // The site's `.orb-chrome`: four inset white shadows — a 1px top lip, a
    // softer bottom lip, a hairline ring and an inner glow `shellBlur` wide —
    // over the whole orb at reduced opacity.
    private var chrome: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(Chrome.glowAlpha), lineWidth: shellBlur)
                .blur(radius: shellBlur / 2)
            Circle()
                .strokeBorder(Color.white.opacity(Chrome.ringAlpha), lineWidth: Chrome.hairline)
            lip(offsetY: Chrome.hairline, alpha: Chrome.topLipAlpha)
            lip(offsetY: -Chrome.hairline, alpha: Chrome.bottomLipAlpha)
        }
        .clipShape(Circle())
        .opacity(Chrome.opacity)
        .allowsHitTesting(false)
    }

    // An inset shadow offset by one hairline: the sliver of the circle left
    // uncovered when a copy of it slides down (or up) by that much.
    private func lip(offsetY: CGFloat, alpha: Double) -> some View {
        Circle()
            .fill(Color.white.opacity(alpha))
            .overlay {
                Circle()
                    .offset(y: offsetY)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .blur(radius: Chrome.hairline / 2)
    }

    // Lifted verbatim from the site's stylesheet.
    private enum Chrome {
        static let defaultShellBlur: CGFloat = 15.8
        static let hairline: CGFloat = 1
        static let opacity: Double = 0.35
        static let topLipAlpha: Double = 0.7
        static let bottomLipAlpha: Double = 0.45
        static let ringAlpha: Double = 0.22
        static let glowAlpha: Double = 0.18
    }
}
