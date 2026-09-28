//
//  BrightHomeGradient.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI

// A slowly turning pink and sky-blue wash, blurred right down, to sit behind a home page.
struct BrightHomeGradient: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            AngularGradient(colors: Constants.colors, center: .center, angle: .degrees(time * Constants.turnSpeed))
                .scaleEffect(Constants.overscan)
                .blur(radius: Constants.blur)
                .opacity(.ultraLowOpacity)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private enum Constants {
        static let colors: [Color] = [.defaultPink, .defaultSkyBlue, .defaultSkyBlue, .defaultSkyBlue, .defaultPink]
        static let turnSpeed: Double = 40
        static let overscan: CGFloat = 1.6
        static let blur: CGFloat = 90
    }
}

#Preview {
    BrightHomeGradient()
        .background(Color.defaultBackground)
}
