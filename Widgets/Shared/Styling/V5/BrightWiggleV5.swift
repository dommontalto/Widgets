//
//  BrightWiggleV5.swift
//  Bright
//
//  Created by Dom Montalto on 30/7/2026.
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

extension View {
    func brightWiggleV5(trigger: Int, haptic: BrightHaptic = .medium) -> some View {
        keyframeAnimator(initialValue: CGFloat.zero, trigger: trigger) { view, offset in
            view.offset(x: offset)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-Constants.distance, duration: Constants.step)
                CubicKeyframe(Constants.distance, duration: Constants.step)
                CubicKeyframe(-Constants.distance / 2, duration: Constants.step)
                CubicKeyframe(Constants.distance / 2, duration: Constants.step)
                CubicKeyframe(0, duration: Constants.step)
            }
        }
        .brightHapticV5(haptic, trigger: trigger)
    }
}

private enum Constants {
    static let distance: CGFloat = 8
    static let step: Double = 0.06
}

#Preview {
    @Previewable @State var trigger = 0

    VStack(spacing: .spacing4x) {
        BrightText("Session name", size: .standout2)
            .brightWiggleV5(trigger: trigger)

        Button("Wiggle") { trigger += 1 }
    }
    .padding()
}
