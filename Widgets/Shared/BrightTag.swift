//
//  BrightTag.swift
//  Widgets
//
//  Created by Dom Montalto on 25/3/2026.
//

import SwiftUI

/// A filter tag, and the page pill in `BrightSwipePageView`: a small
/// `BrightPillButton` that selects, with a haptic on the tap, a pop when the
/// selection arrives from elsewhere, and room to hit above and below.
struct BrightTag: View {
    let title: String
    let image: String?
    let systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        image: String? = nil,
        systemImage: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.image = image
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    @State private var tapTick = 0
    @State private var popTrigger = 0
    @State private var suppressNextPop = false

    var body: some View {
        BrightPillButton(
            title,
            image: image,
            systemImage: systemImage,
            size: .body1,
            buttonSize: .small,
            isSelected: isSelected
        ) {
            tapTick += 1
            // A tap carries its own haptic; the pop is for a selection that
            // arrives from elsewhere — a swipe, a reset — not one you made.
            suppressNextPop = true
            action()
        }
        .keyframeAnimator(initialValue: 1.0, trigger: popTrigger) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(1.15, duration: 0.12)
                CubicKeyframe(1.0, duration: 0.22)
            }
        }
        // Room to hit above and below the capsule.
        .padding(.vertical, .spacing1x)
        .contentShape(.rect)
        .zIndex(isSelected ? 1 : 0)
        .brightHaptic(.light, trigger: tapTick)
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                if suppressNextPop {
                    suppressNextPop = false
                } else {
                    popTrigger += 1
                }
            } else {
                suppressNextPop = false
            }
        }
    }
}
