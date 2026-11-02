//
//  BrightJiggleV5.swift
//  Widgets
//

import SwiftUI

// Each tile rocks with its own amplitude and direction, seeded by its index,
// so a grid doesn't sway in unison. Drive `phase` from a timer
// (see `HealthWidgetGridV5`) and animate it with `.brightJigglePhase`.
struct BrightJiggleV5: ViewModifier {
    let isEnabled: Bool
    let phase: Bool
    let seed: Int

    private var rotation: Double {
        Constants.baseRotation + Double(seed % 5) * Constants.rotationStep
    }

    private var offset: CGFloat {
        Constants.baseOffset + CGFloat((seed * 7) % 5) * Constants.offsetStep
    }

    func body(content: Content) -> some View {
        let isLeaning = seed.isMultiple(of: 2) ? !phase : phase
        content
            .rotationEffect(.degrees(isEnabled ? (isLeaning ? rotation : -rotation) : 0))
            .offset(x: isEnabled ? (isLeaning ? offset : -offset) : 0)
    }

    private enum Constants {
        static let baseRotation: Double = 0.4
        static let rotationStep: Double = 0.15
        static let baseOffset: CGFloat = 0.8
        static let offsetStep: CGFloat = 0.2
    }
}
