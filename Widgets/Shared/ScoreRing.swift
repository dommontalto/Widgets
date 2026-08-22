//
//  ScoreRing.swift
//  Widgets
//
//  Created by Dom Montalto on 22/8/2026.
//

import SwiftUI

struct ScoreRing: View {
    let score: Int?
    let icon: String
    let color: Color
    var diameter: CGFloat = 74
    var lineWidth: CGFloat = .spacing2x
    var iconSize: CGFloat = .spacing5x

    @State private var animatedProgress: CGFloat = 0

    // Starts the fill at the top (12 o'clock) and sweeps clockwise.
    private static let startRotation: Double = -90

    private var progress: CGFloat {
        CGFloat(min(max(score ?? 0, 0), 100)) / 100
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(.ultraLowOpacity))
                .overlay {
                    Image(icon)
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                }
                .padding(lineWidth)

            Circle()
                .stroke(
                    color.opacity(.veryMinimalOpacity),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
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
        ScoreRing(score: 77, icon: ImageNames.recoveryV5, color: .defaultGreen)
        ScoreRing(score: 34, icon: ImageNames.stressV5, color: .defaultPurple)
        ScoreRing(score: 84, icon: ImageNames.strainV5, color: .defaultRed)
    }
    .padding(.spacing4x)
}
