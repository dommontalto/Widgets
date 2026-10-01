//
//  BrightBurstTransition.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

// The leaving view blows outward and dissolves into blur, so what replaces
// it reads as condensing out of the burst.
struct BrightBurstOutTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        let leaving = phase == .didDisappear
        return content
            .scaleEffect(leaving ? Constants.burstScale : 1, anchor: .leading)
            .blur(radius: leaving ? Constants.burstBlur : 0)
            .opacity(leaving ? 0 : 1)
    }

    private enum Constants {
        static let burstScale: CGFloat = 3
        static let burstBlur: CGFloat = 24
    }
}

extension AnyTransition {
    static let brightBurstOutV5 = AnyTransition(BrightBurstOutTransition().animation(.brightEaseInOut))
}
