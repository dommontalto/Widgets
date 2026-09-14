import SwiftUI

extension Animation {
    static let brightJigglePhase: Animation = .easeInOut(duration: 0.15)
    static let brightSnappy: Animation = .snappy(duration: 0.25)
    static let brightEaseInOut: Animation = .easeInOut(duration: 0.35)
    static let brightBouncy: Animation = .bouncy(duration: 0.35)
    static let brightSpring: Animation = .spring(response: 0.5, dampingFraction: 1.0, blendDuration: 1.0)
    static let brightRepeatForever: Animation = .linear(duration: 2.0).repeatForever(autoreverses: false)
    static let brightChartReveal: Animation = .easeInOut(duration: 1.1)

    static func brightStaggered(_ delay: Double) -> Animation {
        .easeInOut(duration: 0.35).delay(delay)
    }
}
