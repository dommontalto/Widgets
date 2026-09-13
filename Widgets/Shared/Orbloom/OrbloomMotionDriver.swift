//
//  OrbloomMotionDriver.swift
//  Widgets
//
//  Created by Dom Montalto on 14/9/2026.
//

import Foundation

// The per-frame state the shader can't keep for itself: the orb's spin
// integrates over time and reverses direction on a slow oscillator, the audio
// level is smoothed on two time constants (a fast one for pulses, a slow one
// for brightness), and a state change fades its tint in rather than snapping.
// Stepped once per frame from the view's timeline; not observed, so stepping
// it inside `body` doesn't invalidate anything.
final class OrbloomMotionDriver {
    struct Frame {
        let time: Double
        let spin: Double
        let audioBrightness: Double
        let audioPulse: Double
        let stateBlend: Double
    }

    private let start = Date()
    // Randomised like the site so two orbs never run the same frame.
    private let timeOffset = Double.random(in: 0..<Constants.maxTimeOffset)

    private var themeID: String?
    private var state: OrbloomState?

    private var phase: Double = 0
    private var audioSmooth: Double = 0
    private var audioFast: Double = 0
    private var spinDirection: Double = 1
    private var spinVelocity: Double = 0
    private var previousFast: Double = 0
    private var flipQueued = false
    private var oscillationSign: Double = 1
    private var spin: Double = 0
    private var lastTime: Double?

    private var stateBlend: Double = 1
    private var lastStateTime: Double?

    func elapsed(at date: Date) -> Double {
        date.timeIntervalSince(start)
    }

    func frame(
        at date: Date,
        theme: OrbloomTheme,
        state: OrbloomState,
        audioLevel: Double,
        reduceMotion: Bool
    ) -> Frame {
        if themeID != theme.id {
            let isFirstTheme = themeID == nil
            themeID = theme.id
            phase = theme.phase
            if isFirstTheme { spin = phase * Constants.initialSpinTurns }
        }
        if self.state != state {
            self.state = state
            stateBlend = reduceMotion ? 1 : 0
            lastStateTime = nil
        }

        let now = elapsed(at: date)
        let time = now + timeOffset
        step(
            to: time,
            audio: min(1, audioLevel * theme.audioResponse.motion),
            speed: theme.motion.speed,
            drift: theme.motion.drift
        )

        let stateStep = lastStateTime.map { min(Constants.maxStep, max(0, now - $0)) } ?? 0
        lastStateTime = now
        stateBlend += (1 - stateBlend) * ease(stateStep, over: Constants.stateBlendSeconds)

        return Frame(
            time: time,
            spin: spin,
            audioBrightness: min(1, audioSmooth * theme.audioResponse.brightness),
            audioPulse: min(1, audioSmooth * theme.audioResponse.pulse),
            stateBlend: reduceMotion ? 1 : stateBlend
        )
    }

    private func step(to time: Double, audio: Double, speed: Double, drift: Double) {
        let dt = lastTime.map { min(Constants.maxStep, max(0, time - $0)) } ?? 0
        lastTime = time

        let level = min(1, max(0, audio))
        let speed = min(2, max(0, speed))
        let drift = min(2, max(0, drift))

        // Attack faster than release, on both smoothers.
        let smoothSeconds = level > audioSmooth ? Constants.smoothAttack : Constants.smoothRelease
        audioSmooth += (level - audioSmooth) * ease(dt, over: smoothSeconds)
        let fastSeconds = level > audioFast ? Constants.fastAttack : Constants.fastRelease
        audioFast += (level - audioFast) * ease(dt, over: fastSeconds)

        let phaseHash = (6.31 * phase).truncatingRemainder(dividingBy: 1)
        let driftWave = drift * 0.35 * sin(time * (0.11 + 0.08 * (2.17 * phase).truncatingRemainder(dividingBy: 1)) + phase)
        let oscillation = sin(time * (0.45 + 0.2 * phaseHash) + phase)
        let sign: Double = oscillation < 0 ? -1 : 1
        if sign != oscillationSign {
            oscillationSign = sign
            flipQueued = true
        }
        // Reversals wait for a quiet moment so speech never visibly stutters.
        if flipQueued && audioFast < Constants.flipQuietLevel {
            spinDirection = -spinDirection
            flipQueued = false
        }

        let targetVelocity = speed * (0.65 * (0.65 + 0.7 * phaseHash) * (1 + driftWave) + spinDirection * audioFast * 2.2)
        spinVelocity += (targetVelocity - spinVelocity) * ease(dt, over: Constants.velocitySeconds)

        let onset = max(0, audioFast - previousFast)
        previousFast = audioFast
        spinVelocity += spinDirection * min(6 * onset, 1.4) * dt * 14 * speed
        spin += spinVelocity * dt
    }

    // Fraction of the way toward a target after `dt` on an exponential
    // approach with the given time constant.
    private func ease(_ dt: Double, over seconds: Double) -> Double {
        dt > 0 ? 1 - exp(-dt / seconds) : 0
    }

    private enum Constants {
        static let maxTimeOffset: Double = 4000
        static let initialSpinTurns: Double = 3.7
        static let maxStep: Double = 0.1
        static let stateBlendSeconds: Double = 0.18
        static let smoothAttack: Double = 0.11
        static let smoothRelease: Double = 0.3
        static let fastAttack: Double = 0.04
        static let fastRelease: Double = 0.18
        static let flipQuietLevel: Double = 0.18
        static let velocitySeconds: Double = 0.35
    }
}
