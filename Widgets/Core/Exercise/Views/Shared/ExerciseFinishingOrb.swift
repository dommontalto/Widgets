//
//  ExerciseFinishingOrb.swift
//  Widgets
//
//  Created by Dom Montalto on 9/9/2026.
//

import SwiftUI

struct ExerciseFinishingOrb: View {
    var diameter: CGFloat = Constants.diameter
    var glassed = true

    var body: some View {
        if glassed {
            BrightSolvingOrb(size: diameter * Constants.glassedScale, speed: Constants.speed)
                .frame(width: diameter, height: diameter)
                .modifier(GlassEffect(shape: .circle, interactive: false))
                .transition(.opacity)
        } else {
            BrightSolvingOrb(size: diameter, speed: Constants.speed)
                .transition(.opacity)
        }
    }

    enum Constants {
        static let diameter: CGFloat = 62
        static let glassedScale: CGFloat = 0.7
        static let speed: Double = 1.2
    }
}

#Preview {
    ZStack {
        Color.defaultBackground.ignoresSafeArea()

        VStack(spacing: .spacing4x) {
            ExerciseFinishingOrb()
            ExerciseFinishingOrb(diameter: BrightButtonSizes.large.rawValue)
            ExerciseFinishingOrb(glassed: false)
        }
    }
}
