//
//  ExerciseLiveCardioSplits.swift
//  Widgets
//
//  Created by Dom Montalto on 27/8/2026.
//

import SwiftUI

// The page that sits left of the live cardio stats: every kilometre logged so
// far, and how each one ran against the average.
struct ExerciseLiveCardioSplits: View {
    var splits: [ExerciseCardioSplit] = ExerciseDemoData.liveCardioStats.splits

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            BrightText("KM SPLITS", size: .standout4, color: .semiLightTextColor)
                .padding(.horizontal, .spacing4x)

            if splits.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.brightSnappy, value: splits.count)
    }

    private var emptyState: some View {
        BrightPlaceholderView(
            systemImage: "point.bottomleft.forward.to.point.topright.scurvepath",
            title: "No splits yet",
            subtitle: "Your first split lands at the 1 KM mark.",
            imageColor: .lightTextColor
        )
        .padding(.bottom, Constants.bottomFade)
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: .spacing0x) {
                ForEach(Array(splits.enumerated()), id: \.element.id) { index, split in
                    row(split, isLast: index == splits.count - 1)
                }
            }
            // Room to pull the first and last splits clear of the fades.
            .padding(.top, Constants.listTopPadding)
            .padding(.bottom, Constants.bottomFade)
        }
        // The rows dissolve into the header and the controls rather than
        // stopping short of them.
        .mask(fade)
    }

    private func row(_ split: ExerciseCardioSplit, isLast: Bool) -> some View {
        VStack(spacing: .spacing0x) {
            HStack(spacing: .spacing2x) {
                BrightText("\(split.index)", size: .standout1)
                    .monospacedDigit()

                Spacer(minLength: .spacing2x)

                if let delta = split.delta {
                    BrightText(deltaText(delta), size: .giant, color: deltaColor(delta))
                        .monospacedDigit()
                }

                BrightText(split.pace, size: .giant)
                    .monospacedDigit()
                    .frame(width: Constants.paceWidth, alignment: .trailing)
            }
            .frame(height: Constants.rowHeight)

            if !isLast {
                BrightDivider()
            }
        }
        .padding(.horizontal, .spacing4x)
    }

    // A split slower than the average reads orange, a faster one green.
    private func deltaColor(_ delta: Int) -> Color {
        delta > 0 ? .defaultOrange : .defaultGreen
    }

    private func deltaText(_ delta: Int) -> String {
        delta > 0 ? "+\(delta)" : "\u{2212}\(abs(delta))"
    }

    // Measured in points rather than fractions: the bottom fade has to clear
    // the page dots and the controls, whatever the screen's height.
    private var fade: some View {
        VStack(spacing: .spacing0x) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: Constants.topFade)

            Rectangle()

            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black.opacity(.mediumOpacity), location: Constants.bottomFadeKnee),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Constants.bottomFade)
        }
    }

    private enum Constants {
        static let rowHeight: CGFloat = .spacing12x + .spacing2x
        static let paceWidth: CGFloat = .spacing12x + .spacing8x
        static let topFade: CGFloat = .spacing6x
        static let listTopPadding: CGFloat = .spacing2x
        static let bottomFade: CGFloat = .spacing12x + .spacing12x + .spacing2x
        // Most of the fade is spent in the first third, so a row dissolves
        // sharply rather than trailing off over the whole stretch.
        static let bottomFadeKnee: CGFloat = 0.3
    }
}

#Preview {
    ExerciseLiveCardioSplits()
        .background(Color.defaultBackground.ignoresSafeArea())
}

#Preview("Empty") {
    ExerciseLiveCardioSplits(splits: [])
        .background(Color.defaultBackground.ignoresSafeArea())
}
