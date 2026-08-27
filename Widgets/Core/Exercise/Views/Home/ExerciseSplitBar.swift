//
//  ExerciseSplitBar.swift
//  Widgets
//
//  Created by Dom Montalto on 27/8/2026.
//

import SwiftUI

struct ExerciseSplitBar: View {
    let strengthPercent: Int
    let cardioPercent: Int

    var body: some View {
        VStack(spacing: .spacing105x) {
            HStack(spacing: .spacing0x) {
                percentLabel(strengthPercent, color: .defaultPurple)
                    .frame(maxWidth: .infinity)
                percentLabel(cardioPercent, color: .defaultSkyBlue)
                    .frame(maxWidth: .infinity)
            }
            bar
        }
    }

    private func percentLabel(_ value: Int, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            BrightText("\(value)", size: .standout1, color: color)
            BrightText("%", size: .body3, color: color)
        }
    }

    private var bar: some View {
        GeometryReader { proxy in
            let inset: CGFloat = .spacing05x
            let trackWidth = max(0, proxy.size.width - inset * 2 - Constants.notchWidth - inset * 2)
            HStack(spacing: inset) {
                segment("Strength", color: .defaultPurple, width: width(of: strengthPercent, in: trackWidth))
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(Color.textColor)
                    .frame(width: Constants.notchWidth, height: 21)
                segment("Cardio", color: .defaultSkyBlue, width: width(of: cardioPercent, in: trackWidth))
            }
            .padding(inset)
        }
        .frame(height: Constants.barHeight)
        .overlay {
            RoundedRectangle(cornerRadius: Constants.barCornerRadius, style: .continuous)
                .strokeBorder(Color.textColor.opacity(.minimalOpacity), lineWidth: 0.5)
        }
    }

    private func segment(_ title: String, color: Color, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Constants.barCornerRadius - .spacing05x, style: .continuous)
            .fill(color.opacity(.veryMinimalOpacity))
            .frame(width: width)
            .overlay {
                BrightText(title, size: .body3, color: color)
            }
    }

    private func width(of percent: Int, in track: CGFloat) -> CGFloat {
        max(0, track * CGFloat(percent) / 100)
    }

    private enum Constants {
        static let barHeight: CGFloat = 35
        static let barCornerRadius: CGFloat = 13
        static let notchWidth: CGFloat = 2
    }
}

struct ExerciseSplitRow: View {
    let split: ExerciseWeekLoad

    var body: some View {
        HStack(spacing: .spacing2x) {
            BrightText(split.name, size: .body3, color: .lightTextColor)

            GeometryReader { proxy in
                let track = max(0, proxy.size.width - .spacing05x)
                HStack(spacing: .spacing05x) {
                    Capsule()
                        .fill(Color.defaultPurple.opacity(.veryMinimalOpacity))
                        .frame(width: width(of: split.strengthFraction, in: track))
                    Capsule()
                        .fill(Color.defaultSkyBlue.opacity(.veryMinimalOpacity))
                        .frame(width: width(of: split.cardioFraction, in: track))
                }
            }
            .frame(height: Constants.rowBarHeight)

            BrightText(split.ratio, size: .body3, color: .lightTextColor)
        }
    }

    // The first layout pass reports no width, and a fraction can arrive as a
    // zero-over-zero NaN, either of which is an invalid frame.
    private func width(of fraction: CGFloat, in track: CGFloat) -> CGFloat {
        guard fraction.isFinite else { return 0 }
        return max(0, track * fraction)
    }

    private enum Constants {
        static let rowBarHeight: CGFloat = 15
    }
}

#Preview {
    VStack(spacing: .spacing4x) {
        ExerciseSplitBar(strengthPercent: 45, cardioPercent: 55)
        ExerciseSplitRow(split: ExerciseDemoData.trainingLoad.weeks[0])
    }
    .padding(.spacing4x)
}
