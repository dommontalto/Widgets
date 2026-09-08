//
//  ExerciseScoresWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 23/7/2026.
//

import SwiftUI

// The three score rings, bare (no card): the icon sits above the ring, the
// score inside it and the name beneath.
struct ExerciseScoresWidget: View {
    @State private var scores = ExerciseDemoData.scores

    // In the app a tapped ring presents the wellbeing stats sheet for that
    // score; the sheet has no prototype counterpart, so the tap surfaces here.
    var onSelectScore: ((String) -> Void)?

    var body: some View {
        HStack(spacing: .spacing2x) {
            tile(title: "Recovery", score: scores.recovery, icon: ImageNames.recoveryV5, color: .defaultGreen)
            tile(title: "Fatigue", score: scores.fatigue, icon: ImageNames.stressV5, color: .defaultRed)
            tile(title: "Readiness", score: scores.readiness, icon: ImageNames.strainV5, color: .defaultSkyBlue)
        }
        .frame(maxWidth: .infinity)
    }

    private func tile(title: String, score: Int, icon: String, color: Color) -> some View {
        Button {
            onSelectScore?(title)
        } label: {
            VStack(spacing: .spacing3x) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundStyle(Color.textColor)

                ScoreDial(score: score, color: color)

                BrightText(title.uppercased(), size: .body1, color: .semiLightTextColor)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private enum Constants {
        static let iconSize: CGFloat = .spacing4x
    }
}

private struct ScoreDial: View {
    let score: Int
    let color: Color

    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat {
        CGFloat(min(max(score, 0), 100)) / 100
    }

    var body: some View {
        ZStack {
            BrightText(String(score), size: .standout2)
                .monospacedDigit()

            Circle()
                .stroke(color.opacity(.minimalOpacity), lineWidth: Constants.trackWidth)
                .padding(Constants.trackWidth / 2)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: Constants.progressWidth, lineCap: .round)
                )
                .padding(Constants.trackWidth / 2)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: Constants.diameter, height: Constants.diameter)
        .onAppear {
            withAnimation(.brightBouncy) { animatedProgress = progress }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.brightBouncy) { animatedProgress = newValue }
        }
    }

    private enum Constants {
        static let diameter: CGFloat = 108
        static let trackWidth: CGFloat = 27
        static let progressWidth: CGFloat = trackWidth / 2
    }
}

#Preview {
    ExerciseScoresWidget()
        .padding(.spacing4x)
}
