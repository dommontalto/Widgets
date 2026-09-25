//
//  LighthouseBeacon.swift
//  Widgets
//
//  Created by Dom Montalto on 9/9/2026.
//

import SwiftUI

// The Lighthouse mark: a dim lens ring with the lamp banked on one side and
// the glow it throws across the inside. Lit, the lamp opens out left to
// right like a book, its beam widening with it.
struct LighthouseBeacon: View {
    var size: CGFloat = Constants.size
    var isLit = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var openness: CGFloat = 1

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(.ultraLowOpacity), lineWidth: band)
                .frame(width: ringDiameter, height: ringDiameter)

            lamp
        }
        .frame(width: size, height: size)
        .onAppear(perform: light)
        .onChange(of: isLit) { _, _ in light() }
    }

    private func light() {
        guard isLit, !reduceMotion else { return }
        var closed = Transaction()
        closed.disablesAnimations = true
        withTransaction(closed) { openness = 0 }
        Task { @MainActor in
            withAnimation(.easeOut(duration: Constants.openDuration)) { openness = 1 }
        }
    }

    private var lampFrom: CGFloat {
        Constants.lampStart
    }

    private var lampTo: CGFloat {
        Constants.lampStart + (Constants.lampEnd - Constants.lampStart) * openness
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
                    Sector(from: lampFrom - capFraction, to: lampTo + capFraction)
                        .frame(width: glowDiameter, height: glowDiameter)
                }

            Circle()
                .trim(from: lampFrom, to: lampTo)
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
        static let openDuration: TimeInterval = 1.2
    }
}

// The pie slice between two circle-trim fractions, matching the trim's own
// clockwise sweep from 3 o'clock.
private struct Sector: Shape {
    var from: CGFloat
    var to: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(from, to) }
        set {
            from = newValue.first
            to = newValue.second
        }
    }

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
