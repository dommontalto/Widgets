//
//  BrightRingV5.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

// A thick progress ring at one of three sizes: a dim track in its colour, and a sweep
// that brightens from where it starts to where it's reached. Going past the goal carries
// on round in the solid colour over the full lap, and laps the extra again as a thin
// outer arc.
struct BrightRingV5: View {
    enum Size {
        case extraSmall
        case small
        case medium
        case large

        var diameter: CGFloat {
            switch self {
            case .extraSmall: .spacing9x
            case .small: .spacing10x
            case .medium: .spacing11x
            case .large: 84
            }
        }

        // The ring's thickness as a share of its width; the smaller ones are thinner so
        // their holes still fit a label.
        var thicknessRatio: CGFloat {
            switch self {
            case .extraSmall: 0.2
            case .small: 0.23
            case .medium, .large: 0.28
            }
        }
    }

    let progress: Double
    let color: Color
    // Drawn in the hole, e.g. "C".
    var label: String?
    var size: Size = .small
    // The outer arc's colour once past the goal; the ring's own when going over is fine.
    var overColor: Color?

    var body: some View {
        let lineWidth = size.diameter * size.thicknessRatio
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

            // The second lap, started a sliver before 12 so it covers the seam where the
            // first lap's ends meet; at exactly the goal it's only that sliver.
            if filled >= 1 {
                Circle()
                    .trim(from: 0, to: overflow + Constants.seamOverlap)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth))
                    .rotationEffect(.degrees(-90 - 360 * Constants.seamOverlap))
            }

            if overflow > 0 {
                Circle()
                    .trim(from: 0, to: overflow)
                    .stroke(overColor ?? color, style: StrokeStyle(lineWidth: lineWidth * Constants.lapRatio, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(-(lineWidth / 2 + lineWidth * Constants.lapGapRatio))
            }

            if let label {
                BrightText(label, size: .body5, color: .semiLightTextColor)
            }
        }
        .padding(lineWidth / 2)
        .frame(width: size.diameter, height: size.diameter)
        .animation(.brightEaseInOut, value: progress)
    }

    private enum Constants {
        static let lapRatio: CGFloat = 0.25
        static let lapGapRatio: CGFloat = 0.25
        static let seamOverlap = 0.004
    }
}

#Preview {
    HStack(spacing: .spacing4x) {
        BrightRingV5(progress: 0.37, color: .defaultGreen)
        BrightRingV5(progress: 1.17, color: .defaultYellow, label: "F", overColor: .defaultOrange)
        BrightRingV5(progress: 0.73, color: .defaultPink)
    }
    .padding(.spacing3x)
    .background(Color.defaultHomeCards)
}
