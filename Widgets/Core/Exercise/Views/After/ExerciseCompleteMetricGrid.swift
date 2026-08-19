//
//  ExerciseCompleteMetricGrid.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

// The summary's headline numbers: two columns on the page itself rather than in
// cards, fenced above and below by a hairline.
struct ExerciseCompleteMetricGrid: View {
    let metrics: [ExerciseCompleteMetric]

    var body: some View {
        VStack(spacing: .spacing0x) {
            BrightDivider()

            VStack(spacing: .spacing4x) {
                ForEach(Array(stride(from: 0, to: metrics.count, by: 2)), id: \.self) { index in
                    HStack(alignment: .top, spacing: .spacing3x) {
                        cell(metrics[index])

                        if index + 1 < metrics.count {
                            cell(metrics[index + 1])
                        } else {
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.vertical, .spacing4x)

            BrightDivider()
        }
    }

    private func cell(_ metric: ExerciseCompleteMetric) -> some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            HStack(spacing: .spacing105x) {
                ExerciseCompleteIconView(icon: metric.icon)

                BrightText(metric.title, size: .body1, color: .semiLightTextColor, weight: .regular)
            }

            BrightText(metric.value, size: .standout1, weight: .regular)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// An asset icon and an SF Symbol read at the same weight only at different point
// sizes — the symbol draws inside its own padding.
struct ExerciseCompleteIconView: View {
    let icon: ExerciseCompleteIcon
    var size: CGFloat = Constants.box

    var body: some View {
        switch icon {
        case let .asset(name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        case let .system(name, tint):
            Image(systemName: name)
                .font(.system(size: size * Constants.systemScale))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
        }
    }

    enum Constants {
        static let box: CGFloat = 24
        static let systemScale: CGFloat = 20.0 / 24.0
    }
}

#Preview {
    VStack(spacing: .spacing4x) {
        ExerciseCompleteMetricGrid(metrics: ExerciseDemoComplete.strength.metrics)
        ExerciseCompleteMetricGrid(metrics: ExerciseDemoComplete.cardio.metrics)
    }
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}
