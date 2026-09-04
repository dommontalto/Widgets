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

// The arriving view sharpens from a soft, slightly swollen blur into place.
struct BrightCondenseInTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        let arriving = phase == .willAppear
        return content
            .scaleEffect(arriving ? Constants.swell : 1, anchor: .topLeading)
            .blur(radius: arriving ? Constants.blur : 0)
            .opacity(arriving ? 0 : 1)
    }

    private enum Constants {
        static let swell: CGFloat = 1.05
        static let blur: CGFloat = 12
    }
}

extension AnyTransition {
    static let brightBurstOut = AnyTransition(BrightBurstOutTransition().animation(.brightEaseInOut))
    static let brightCondenseIn = AnyTransition(BrightCondenseInTransition().animation(.brightEaseInOut))
}
