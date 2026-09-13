//
//  LighthouseBeacon.swift
//  Widgets
//
//  Created by Dom Montalto on 9/9/2026.
//

import SwiftUI

// The Lighthouse mark: a dim lens ring with the lamp banked on one side and
// the glow it throws across the inside. The lamp turns without stopping, like
// a lighthouse lens.
struct LighthouseBeacon: View {
    var size: CGFloat = Constants.size

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isSweeping = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(.ultraLowOpacity), lineWidth: band)
                .frame(width: ringDiameter, height: ringDiameter)

            lamp
                .rotationEffect(.degrees(isSweeping ? 360 : 0))
                // 360° back to 0° is the same frame, so a linear repeat reads
                // as one unbroken turn.
                .animation(
                    .linear(duration: Constants.sweepDuration).repeatForever(autoreverses: false),
                    value: isSweeping
                )
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !reduceMotion else { return }
            isSweeping = true
        }
    }

    private var lamp: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(.zero), .white.opacity(.lowOpacity)],
                        center: .center,
                        startRadius: glowDiameter / 2 * Constants.glowInnerFraction,
                        endRadius: glowDiameter / 2
                    )
                )
                .frame(width: glowDiameter, height: glowDiameter)
                // The beam is cut to the lamp's own arc, so its edges run out
                // through the ends of the lit ring rather than squaring off at
                // 3 and 9 o'clock.
                .mask {
                    Sector(from: Constants.lampStart - capFraction, to: Constants.lampEnd + capFraction)
                        .frame(width: glowDiameter, height: glowDiameter)
                }

            Circle()
                .trim(from: Constants.lampStart, to: Constants.lampEnd)
                .stroke(Color.white, style: StrokeStyle(lineWidth: band, lineCap: .round))
                .frame(width: ringDiameter - band, height: ringDiameter - band)
        }
    }

    private var ringDiameter: CGFloat {
        size * Constants.ringFraction
    }

    private var band: CGFloat {
        size * Constants.bandFraction
    }

    private var glowDiameter: CGFloat {
        size * Constants.glowFraction
    }

    // A round cap reaches half a band past the trim, so the beam's edges take
    // the same overhang and still meet the lamp's tips.
    private var capFraction: CGFloat {
        (band / 2) / (.pi * (ringDiameter - band))
    }

    private enum Constants {
        static let size: CGFloat = 117
        static let ringFraction: CGFloat = 0.732
        static let bandFraction: CGFloat = 0.073
        static let glowFraction: CGFloat = 0.575
        static let glowInnerFraction: CGFloat = 0.336
        // A trim runs clockwise from 3 o'clock, so the lamp's 118° sits either
        // side of 0.75.
        static let lampStart: CGFloat = 0.586
        static let lampEnd: CGFloat = 0.914
        static let sweepDuration: TimeInterval = 4
    }
}

// The pie slice between two circle-trim fractions, matching the trim's own
// clockwise sweep from 3 o'clock.
private struct Sector: Shape {
    let from: CGFloat
    let to: CGFloat

    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.move(to: centre)
        path.addArc(
            center: centre,
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(Double(from) * 360),
            endAngle: .degrees(Double(to) * 360),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    LighthouseBeacon()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
}
