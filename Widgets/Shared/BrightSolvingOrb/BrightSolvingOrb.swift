//
//  BrightSolvingOrb.swift
//  Widgets
//
//  Created by Dom Montalto on 21/8/2026.
//

import SwiftUI

// SwiftUI port of the "solving" state of Jakub Antalík's Thinking Orbs
// (https://orbs.jakubantalik.com): a sphere of ink dots arranged as a Rubik's
// cube that twists itself scrambled one move at a time, then unwinds. The
// maths and constants are lifted from the site's renderer, resolved for its
// small-chip preset; `speed` multiplies the preset rate exactly like the
// component's speed prop does there.
struct BrightSolvingOrb: View {
    var size: CGFloat = 20
    var speed: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var start = Date()

    var body: some View {
        if reduceMotion {
            orb(at: Constants.staticTime)
        } else {
            TimelineView(.animation) { context in
                orb(at: context.date.timeIntervalSince(start) * preset.speed * speed)
            }
        }
    }

    // The site tunes the orb separately for its 20px and 64px chips; pick
    // whichever resolved preset the requested size is closer to.
    private var preset: Preset {
        size < Preset.cutover ? .small : .large
    }

    private func orb(at t: Double) -> some View {
        Canvas { context, _ in
            var dots = Self.dots(at: t, size: size, preset: preset)
            // Painter's order: far dots first so near, darker dots sit on top.
            dots.sort { $0.z < $1.z }

            for dot in dots {
                let level = min(1, max(0, dot.white))
                let rect = CGRect(
                    x: dot.x - dot.r,
                    y: dot.y - dot.r,
                    width: dot.r * 2,
                    height: dot.r * 2
                )
                let ink = Color(light: Color(white: level), dark: Color(white: 1 - level))
                context.fill(Path(ellipseIn: rect), with: .color(ink))
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Dot lattice

    private struct Dot {
        let x: CGFloat
        let y: CGFloat
        let z: Double
        let r: CGFloat
        let white: Double
    }

    private static func dots(at t: Double, size: CGFloat, preset: Preset) -> [Dot] {
        let half = Double(size) / 2
        let radius = half * Constants.sphereScale
        let yaw = t * Constants.yawRate
        let pitch = Constants.pitchBase + Constants.pitchSwing * sin(t * Constants.pitchRate)
        let sinYaw = sin(yaw), cosYaw = cos(yaw)
        let sinPitch = sin(pitch), cosPitch = cos(pitch)
        // The site scales dot radii by (canvasSize / 300)^0.6.
        let dotScale = pow(Double(size) / 300, Constants.radiusSizePower)
        let twist = twistProgress(at: t)

        var dots = [Dot]()
        for ring in 0...preset.latRings {
            let lat = -.pi / 2 + Double(ring) / Double(preset.latRings) * .pi
            let cosLat = cos(lat), sinLat = sin(lat)
            let count = max(1, Int((abs(cosLat) * Double(preset.lonDensity)).rounded()))

            for step in 0..<count {
                let lon = Double(step) / Double(count) * 2 * .pi
                var point = SIMD3(cosLat * cos(lon), sinLat, cosLat * sin(lon))
                let isActive = apply(twist: twist, to: &point)

                let spunX = point.x * cosYaw + point.z * sinYaw
                let spunZ = -point.x * sinYaw + point.z * cosYaw
                let tiltY = point.y * cosPitch - spunZ * sinPitch
                let depth = point.y * sinPitch + spunZ * cosPitch
                let nearness = (depth + 1) / 2

                let r = (preset.rBase + preset.rDepth * nearness
                    + (isActive ? preset.rActive : 0)) * dotScale
                dots.append(Dot(
                    x: half + spunX * radius,
                    y: half - tiltY * radius,
                    z: depth,
                    r: max(Constants.rMin, r),
                    white: Constants.inkFar - Constants.inkSpan * nearness
                        - (isActive ? Constants.activeInkBoost : 0)
                ))
            }
        }
        return dots
    }

    // MARK: - Rubik moves

    private struct Move {
        let axis: Int
        let lo: Double
        let hi: Double
        let angle: Double
    }

    // The site seeds its move list with a fract(sin) hash, so every orb plays
    // the same deterministic scramble.
    private static let moves: [Move] = (0..<Constants.moveCount).map { index in
        let axis = min(2, Int(hash(index, 2.3) * 3))
        let lo = -1 + 0.5 * Double(min(3, Int(hash(index, 5.9) * 4)))
        return Move(
            axis: axis,
            lo: lo,
            hi: lo + 0.5,
            angle: (hash(index, 7.7) < 0.5 ? 1.0 : -1.0) * .pi / 2
        )
    }

    private static func hash(_ index: Int, _ salt: Double) -> Double {
        let value = sin(Double(index) * 12.9898 + salt * 78.233) * 43758.5453
        return value - value.rounded(.down)
    }

    // How far through the scramble-then-unwind cycle each move is: completed
    // moves hold at 1, the active move eases out, the rest wait at 0.
    private static func twistProgress(at t: Double) -> (amounts: [Double], active: Int) {
        let moveCount = Constants.moveCount
        let step = Constants.moveDuration
        let cycle = 2 * Double(moveCount) * step + Constants.restDuration
        let phase = t.truncatingRemainder(dividingBy: cycle)

        var amounts = [Double](repeating: 0, count: moveCount)
        var active = -1
        if phase < 2 * Double(moveCount) * step {
            let index = Int(phase / step)
            let fraction = (phase - Double(index) * step) / step
            let eased = 1 - pow(1 - min(1, fraction / Constants.easePortion), 3)
            if index < moveCount {
                for i in 0..<index { amounts[i] = 1 }
                amounts[index] = eased
                active = index
            } else {
                let unwind = 2 * moveCount - 1 - index
                for i in 0..<unwind { amounts[i] = 1 }
                amounts[unwind] = 1 - eased
                active = unwind
            }
        }
        return (amounts, active)
    }

    // Rotates the point through every in-progress move whose slab contains it,
    // reporting whether the currently twisting move touched it.
    private static func apply(
        twist: (amounts: [Double], active: Int),
        to point: inout SIMD3<Double>
    ) -> Bool {
        var isActive = false
        for (index, move) in moves.enumerated() {
            let amount = twist.amounts[index]
            guard amount > 0 else { continue }

            let coordinate = move.axis == 0 ? point.x : move.axis == 1 ? point.y : point.z
            guard coordinate >= move.lo, coordinate < move.hi else { continue }

            if index == twist.active {
                isActive = true
            }

            let angle = move.angle * amount
            let c = cos(angle), s = sin(angle)
            switch move.axis {
            case 0:
                let y = point.y * c - point.z * s
                point.z = point.y * s + point.z * c
                point.y = y
            case 1:
                let x = point.x * c + point.z * s
                point.z = -point.x * s + point.z * c
                point.x = x
            default:
                let x = point.x * c - point.y * s
                point.y = point.x * s + point.y * c
                point.x = x
            }
        }
        return isActive
    }

    // The site's rubik config resolved for its two chip sizes: lattice density
    // scaled by sqrt(count), radii by the chip's size multiplier.
    private struct Preset {
        let speed: Double
        let latRings: Int
        let lonDensity: Int
        let rBase: Double
        let rDepth: Double
        let rActive: Double

        // 20px chip: count 0.088, size 1.9.
        static let small = Preset(
            speed: 1.95, latRings: 4, lonDensity: 12,
            rBase: 1.14, rDepth: 3.23, rActive: 0.57
        )

        // 64px chip: count 0.35, size 1.05.
        static let large = Preset(
            speed: 1.82, latRings: 9, lonDensity: 24,
            rBase: 0.63, rDepth: 1.785, rActive: 0.315
        )

        // Midpoint between the two chip sizes the site tunes for.
        static let cutover: CGFloat = 42
    }

    private enum Constants {
        static let moveCount = 14
        static let moveDuration: Double = 0.42
        static let restDuration: Double = 1.2
        static let easePortion: Double = 0.7
        static let sphereScale: Double = 0.82
        static let yawRate: Double = 0.55
        static let pitchBase: Double = 0.35
        static let pitchSwing: Double = 0.1
        static let pitchRate: Double = 0.9
        static let radiusSizePower: Double = 0.6
        static let rMin: CGFloat = 0.3
        static let inkFar: Double = 0.62
        static let inkSpan: Double = 0.54
        static let activeInkBoost: Double = 0.14
        // The frame the site freezes on when Reduce Motion is set.
        static let staticTime: Double = 0.6
    }
}

#Preview {
    BrightSolvingOrb(size: 64, speed: 1.2)
        .padding(.spacing4x)
}
