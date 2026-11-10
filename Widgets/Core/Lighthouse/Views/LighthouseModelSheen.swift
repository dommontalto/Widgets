//
//  LighthouseModelSheen.swift
//  Widgets
//

import SwiftUI

struct LighthouseModelSheen: ViewModifier {
    let tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                let turn = Angle.radians(t * Constants.turnSpeed)
                let breath = (sin(t * Constants.breathSpeed) + 1) / 2

                content
                    .overlay {
                        AngularGradient(
                            colors: [.clear, tint, .white.opacity(Constants.highlight), tint, .clear, .clear],
                            center: .center,
                            angle: turn
                        )
                        .blendMode(.overlay)
                        .opacity(Constants.minOpacity + (Constants.maxOpacity - Constants.minOpacity) * breath)
                        .clipShape(Circle())
                        .allowsHitTesting(false)
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                AngularGradient(colors: [tint, .white, tint, tint.opacity(Constants.ringFloor), tint], center: .center, angle: turn),
                                lineWidth: Constants.ringWidth
                            )
                            .opacity(Constants.ringMin + (1 - Constants.ringMin) * breath)
                            .allowsHitTesting(false)
                    }
                    .shadow(color: tint.opacity(Constants.glowMin + (Constants.glowMax - Constants.glowMin) * breath), radius: Constants.glowRadius)
            }
        }
    }

    private enum Constants {
        static let turnSpeed = 0.6
        static let breathSpeed = 1.2
        static let highlight = 0.5
        static let minOpacity = 0.25
        static let maxOpacity = 0.45
        static let ringWidth: CGFloat = 1
        static let ringMin = 0.15
        static let ringFloor = 0.1
        static let glowMin = 0.1
        static let glowMax = 0.35
        static let glowRadius: CGFloat = 6
    }
}

extension View {
    func lighthouseModelSheen(_ tint: Color) -> some View {
        modifier(LighthouseModelSheen(tint: tint))
    }
}
