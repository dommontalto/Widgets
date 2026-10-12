//
//  Animation+Extensions.swift
//  Widgets
//
//  Created by Dom Montalto on 7/7/2026.
//

import SwiftUI

extension Animation {
    static let brightJigglePhase: Animation = .easeInOut(duration: 0.15)
    static let brightSnappy: Animation = .snappy(duration: 0.2)
    static let brightEaseInOut: Animation = .easeInOut(duration: 0.3)
    static let brightBouncy: Animation = .bouncy(duration: 0.3)
    // Eases in, then overshoots and settles back, so a reveal lands with a bounce.
    static let brightReveal: Animation = .timingCurve(0.65, 0, 0.35, 1.5, duration: 0.5)
    // A line drawing across: an even pace that eases into its end, given longer than a
    // reveal since it travels the whole width.
    static let brightDraw: Animation = .timingCurve(0.33, 0.33, 0.4, 1, duration: 0.9)
    static let brightSpring: Animation = .spring(response: 0.3, dampingFraction: 1.0, blendDuration: 1.0)
    static let brightRepeatForever: Animation = .linear(duration: 2.0).repeatForever(autoreverses: false)
    static let brightChartReveal: Animation = .easeInOut(duration: 0.5)
    static let brightSendFlight: Animation = .interpolatingSpring(duration: 0.2, bounce: 0, initialVelocity: 0)

    static func brightStaggered(_ delay: Double) -> Animation {
        .easeInOut(duration: 0.3).delay(delay)
    }
}
