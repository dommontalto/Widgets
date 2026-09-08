//
//  ExerciseProgressRing.swift
//  Widgets
//
//  Created by Dom Montalto on 7/9/2026.
//

import SwiftUI

// Starting, restarting or ending a period sweeps the ring rather than
// snapping it.
struct ExerciseProgressRing: View {
    static let diameter: CGFloat = 58

    let fraction: CGFloat

    private var percent: Int {
        Int((fraction * 100).rounded())
    }

    var body: some View {
        ZStack {
            BrightText("\(percent)%", size: .subheading1)
                .monospacedDigit()
                .contentTransition(.numericText())

            Circle()
                .stroke(Color.defaultGreen.opacity(.minimalOpacity), lineWidth: Constants.ringWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    Color.defaultGreen,
                    style: StrokeStyle(lineWidth: Constants.ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: Self.diameter, height: Self.diameter)
        .animation(.brightSnappy, value: fraction)
    }

    private enum Constants {
        static let ringWidth: CGFloat = 10
    }
}

#Preview {
    HStack(spacing: .spacing4x) {
        ExerciseProgressRing(fraction: 0)
        ExerciseProgressRing(fraction: 0.12)
        ExerciseProgressRing(fraction: 1)
    }
    .padding(.spacing4x)
}
