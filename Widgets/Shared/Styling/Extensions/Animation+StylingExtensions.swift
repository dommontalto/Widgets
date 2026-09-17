//
//  Animation+StylingExtensions.swift
//  Widgets
//
//  Created by Dom Montalto on 7/7/2026.
//

import SwiftUI

extension Animation {
    static let brightJigglePhase: Animation = .easeInOut(duration: 0.15)
    static let brightSnappy: Animation = .snappy(duration: 0.25)
    static let brightEaseInOut: Animation = .easeInOut(duration: 0.35)
    static let brightBouncy: Animation = .bouncy(duration: 0.35)
    static let brightSpring: Animation = .spring(response: 0.5, dampingFraction: 1.0, blendDuration: 1.0)
    static let brightRepeatForever: Animation = .linear(duration: 2.0).repeatForever(autoreverses: false)
    static let brightChartReveal: Animation = .easeInOut(duration: 1.1)
    static let brightSendFlight: Animation = .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)

    static func brightStaggered(_ delay: Double) -> Animation {
        .easeInOut(duration: 0.35).delay(delay)
    }
}
