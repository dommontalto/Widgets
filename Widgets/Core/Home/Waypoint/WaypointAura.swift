//
//  WaypointAura.swift
//  Widgets
//
//  Created by Dom Montalto on 25/9/2026.
//

import SwiftUI

struct WaypointAura: View {
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate

            ZStack {
                bloom(time: time)

                swirl(time: time)
            }
        }
        .frame(width: Constants.size, height: Constants.size)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func bloom(time: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(.minimalOpacity), color.opacity(.finalBossLowOpacity), .clear],
                    center: .center,
                    startRadius: .spacing0x,
                    endRadius: Constants.size / 2
                )
            )
            .scaleEffect(1 + Constants.breathDepth * sin(time * Constants.breathSpeed))
    }

    private func swirl(time: Double) -> some View {
        Circle()
            .fill(
                AngularGradient(
                    colors: [
                        color,
                        color.opacity(.finalBossLowOpacity),
                        color.opacity(.lowOpacity),
                        color.opacity(.finalBossLowOpacity),
                        color,
                    ],
                    center: .center
                )
            )
            .frame(width: Constants.swirlSize, height: Constants.swirlSize)
            .rotationEffect(.degrees(time * Constants.swirlSpeed))
            .blur(radius: Constants.swirlBlur)
            .opacity(.veryMinimalOpacity)
    }

    private enum Constants {
        static let size: CGFloat = 260
        static let swirlSize: CGFloat = 170
        static let swirlBlur: CGFloat = 32
        static let swirlSpeed: Double = 14
        static let breathDepth: Double = 0.06
        static let breathSpeed: Double = 0.9
    }
}

#Preview {
    WaypointAura(color: .defaultCyan)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.defaultBackground)
}
