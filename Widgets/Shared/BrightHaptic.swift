//
//  BrightHaptic.swift
//  Bright
//
//  Created by Dom Montalto on 30/7/2026.
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

public enum BrightHaptic {
    case light
    case medium
    case success

    public var feedback: SensoryFeedback {
        switch self {
        case .light: .impact(weight: .light)
        case .medium: .impact(weight: .medium)
        case .success: .success
        }
    }

    @MainActor
    public func play() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

extension View {
    func brightHaptic<T: Equatable>(_ haptic: BrightHaptic, trigger: T) -> some View {
        sensoryFeedback(haptic.feedback, trigger: trigger)
    }

    func brightHaptic<T: Equatable>(
        _ haptic: BrightHaptic,
        trigger: T,
        condition: @escaping (T, T) -> Bool
    ) -> some View {
        sensoryFeedback(haptic.feedback, trigger: trigger, condition: condition)
    }

    func brightHaptic<T: Equatable>(
        trigger: T,
        _ haptic: @escaping (T, T) -> BrightHaptic?
    ) -> some View {
        sensoryFeedback(trigger: trigger) { haptic($0, $1)?.feedback }
    }
}
