//
//  ScoreRing.swift
//  Widgets
//
//  Created by Dom Montalto on 22/8/2026.
//

import SwiftUI

struct ScoreRing: View {
    let score: Int?
    let color: Color
    var diameter: CGFloat = 74
    var lineWidth: CGFloat = .spacing2x
    var valueSize: FontSizes = .standout3
    // Drawn in the ring's tint in place of the score.
    var icon: String?

    @State private var animatedProgress: CGFloat = 0

    // Starts the fill at the top (12 o'clock) and sweeps clockwise.
    private static let startRotation: Double = -90

    private var iconSize: CGFloat {
        diameter - lineWidth * 2 - .spacing2x
    }

    // Full tint at both ends of the sweep: the round cap at the top overlaps
    // the gradient's own seam, and any step across it draws as a hard line.
    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: [color, color.opacity(.lowOpacity), color],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }

    private var progress: CGFloat {
        CGFloat(min(max(score ?? 0, 0), 100)) / 100
    }

    var body: some View {
        ZStack {
            if let icon {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(color)
            } else {
                BrightText(String(score ?? 0), size: valueSize)
                    .monospacedDigit()
            }

            Circle()
                .stroke(
                    color.opacity(.veryMinimalOpacity),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(Self.startRotation))
        }
        .frame(width: diameter, height: diameter)
        .onAppear {
            animatedProgress = 0
            Task { @MainActor in
                withAnimation(.brightBouncy) { animatedProgress = progress }
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.brightBouncy) { animatedProgress = newValue }
        }
    }
}

#Preview {
    HStack(spacing: .spacing3x) {
        ScoreRing(score: 77, color: .defaultGreen)
        ScoreRing(score: 66, color: .defaultBlue)
        ScoreRing(score: 84, color: .defaultRed)
    }
    .padding(.spacing4x)
}
