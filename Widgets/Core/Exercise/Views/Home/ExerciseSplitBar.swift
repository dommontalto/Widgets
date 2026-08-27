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
            let trackWidth = proxy.size.width - inset * 2 - Constants.notchWidth - inset * 2
            HStack(spacing: inset) {
                segment("Strength", color: .defaultPurple, width: trackWidth * fraction(strengthPercent))
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(Color.textColor)
                    .frame(width: Constants.notchWidth, height: 21)
                segment("Cardio", color: .defaultSkyBlue, width: trackWidth * fraction(cardioPercent))
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

    private func fraction(_ percent: Int) -> CGFloat {
        CGFloat(percent) / 100
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
                // The pair sits together; a period lighter than the peak leaves
                // its missing volume as trailing air, not a hole in the middle.
                let track = proxy.size.width - .spacing05x
                HStack(spacing: .spacing05x) {
                    Capsule()
                        .fill(Color.defaultPurple.opacity(.veryMinimalOpacity))
                        .frame(width: track * split.strengthFraction)
                    Capsule()
                        .fill(Color.defaultSkyBlue.opacity(.veryMinimalOpacity))
                        .frame(width: track * split.cardioFraction)
                    Spacer(minLength: .spacing0x)
                }
            }
            .frame(height: Constants.rowBarHeight)

            BrightText(split.ratio, size: .body3, color: .lightTextColor)
        }
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
