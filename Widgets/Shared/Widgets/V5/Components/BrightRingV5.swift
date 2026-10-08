//
//  BrightRingV5.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

// A thick progress ring at one of three sizes: a dim track in its colour, and a sweep
// that brightens from where it starts to where it's reached. Going past the goal laps
// a thin outer arc for the extra and marks the goal at the top.
struct BrightRingV5: View {
    enum Size {
        case small
        case medium
        case large

        var diameter: CGFloat {
            switch self {
            case .small: .spacing9x
            case .medium: .spacing11x
            case .large: 80
            }
        }
    }

    let progress: Double
    let color: Color
    // Drawn in the hole, e.g. "C".
    var label: String?
    var size: Size = .medium

    var body: some View {
        let lineWidth = size.diameter * Constants.thicknessRatio
        let filled = min(max(progress, 0), 1)
        let overflow = min(max(progress - 1, 0), 1)

        return ZStack {
            Circle()
                .stroke(color.opacity(.veryLowOpacity), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: filled)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(.lowOpacity), color],
                        center: .center,
                        startAngle: .zero,
                        endAngle: .degrees(360 * filled)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth)
                )
                .rotationEffect(.degrees(-90))

            if overflow > 0 {
                goalMark(lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: overflow)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth * Constants.lapRatio, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(-(lineWidth / 2 + lineWidth * Constants.lapGapRatio))
            }

            if let label {
                BrightText(label, size: .body3, color: color)
            }
        }
        .padding(lineWidth / 2)
        .frame(width: size.diameter, height: size.diameter)
        .animation(.brightEaseInOut, value: progress)
    }

    // A short card-coloured cut across the ring at the top, where the goal was reached.
    private func goalMark(lineWidth: CGFloat) -> some View {
        Capsule()
            .fill(Color.defaultHomeCards)
            .frame(width: Constants.goalMarkWidth, height: lineWidth)
            .frame(maxHeight: .infinity, alignment: .top)
            .offset(y: -lineWidth / 2)
    }

    private enum Constants {
        static let thicknessRatio: CGFloat = 0.28
        static let lapRatio: CGFloat = 0.25
        static let lapGapRatio: CGFloat = 0.25
        static let goalMarkWidth: CGFloat = 2
    }
}

#Preview {
    HStack(spacing: .spacing4x) {
        BrightRingV5(progress: 0.37, color: .defaultGreen)
        BrightRingV5(progress: 1.26, color: .defaultYellow, label: "F")
        BrightRingV5(progress: 0.73, color: .defaultPink, size: .large)
    }
    .padding(.spacing3x)
    .background(Color.defaultHomeCards)
}
