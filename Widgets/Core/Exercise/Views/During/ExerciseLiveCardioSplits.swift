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
        VStack(alignment: .leading, spacing: .spacing4x) {
            BrightText("KM SPLITS", size: .standout4, color: .semiLightTextColor)
                .padding(.horizontal, .spacing4x)

            list
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: .spacing0x) {
                ForEach(Array(splits.enumerated()), id: \.element.id) { index, split in
                    row(split, isLast: index == splits.count - 1)
                }
            }
        }
        // The last rows run out under the controls rather than stopping short
        // of them.
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

    private var fade: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: Constants.fadeStart),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private enum Constants {
        static let rowHeight: CGFloat = .spacing12x + .spacing2x
        static let paceWidth: CGFloat = .spacing12x + .spacing8x
        static let fadeStart: CGFloat = 0.85
    }
}

#Preview {
    ExerciseLiveCardioSplits()
        .background(Color.defaultBackground.ignoresSafeArea())
}
