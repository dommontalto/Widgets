//
//  ExerciseTrainingLoadWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 21/7/2026.
//

import SwiftUI

struct ExerciseTrainingLoadWidget: View {
    private let splitBarHeight: CGFloat = 35
    private let splitBarCornerRadius: CGFloat = 13
    private let weekBarHeight: CGFloat = 15

    @State private var load = ExerciseDemoData.trainingLoad

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText("Split", size: .body1, color: .textColor,)
                BrightText("Monthly AVG", size: .body2, color: .lightTextColor)
            }

            VStack(spacing: .spacing105x) {
                HStack(spacing: .spacing0x) {
                    percentLabel(load.strengthPercent, color: .defaultPurple)
                        .frame(maxWidth: .infinity)
                    percentLabel(load.cardioPercent, color: .defaultSkyBlue)
                        .frame(maxWidth: .infinity)
                }
                splitBar
            }

            Rectangle()
                .fill(Color.textColor.opacity(.ultraLowOpacity))
                .frame(height: 1)

            VStack(spacing: .spacing2x) {
                ForEach(load.weeks.indices, id: \.self) { i in
                    weekRow(load.weeks[i])
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }

    private func percentLabel(_ value: Int, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            BrightText("\(value)", size: .standout1, color: color)
            BrightText("%", size: .body3, color: color)
        }
    }

    private var splitBar: some View {
        GeometryReader { proxy in
            let inset: CGFloat = .spacing05x
            let trackWidth = proxy.size.width - inset * 2 - notchWidth - inset * 2
            HStack(spacing: inset) {
                splitSegment("Strength", color: .defaultPurple, width: trackWidth * fraction(load.strengthPercent))
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(Color.textColor)
                    .frame(width: notchWidth, height: 21)
                splitSegment("Cardio", color: .defaultSkyBlue, width: trackWidth * fraction(load.cardioPercent))
            }
            .padding(inset)
        }
        .frame(height: splitBarHeight)
        .overlay {
            RoundedRectangle(cornerRadius: splitBarCornerRadius, style: .continuous)
                .strokeBorder(Color.textColor.opacity(.minimalOpacity), lineWidth: 0.5)
        }
    }

    private func splitSegment(_ title: String, color: Color, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: splitBarCornerRadius - .spacing05x, style: .continuous)
            .fill(color.opacity(.veryMinimalOpacity))
            .frame(width: width)
            .overlay {
                BrightText(title, size: .body3, color: color)
            }
    }

    private func weekRow(_ week: ExerciseWeekLoad) -> some View {
        HStack(spacing: .spacing2x) {
            BrightText(week.name, size: .body3, color: .lightTextColor)

            GeometryReader { proxy in
                HStack(spacing: .spacing0x) {
                    Capsule()
                        .fill(Color.defaultPurple.opacity(.veryMinimalOpacity))
                        .frame(width: proxy.size.width * week.strengthFraction)
                    Spacer(minLength: .spacing05x)
                    Capsule()
                        .fill(Color.defaultSkyBlue.opacity(.veryMinimalOpacity))
                        .frame(width: proxy.size.width * week.cardioFraction)
                }
            }
            .frame(height: weekBarHeight)

            BrightText(week.ratio, size: .body3, color: .lightTextColor)
        }
    }

    private func fraction(_ percent: Int) -> CGFloat {
        CGFloat(percent) / 100
    }

    private var notchWidth: CGFloat { 2 }
}

#Preview {
    ExerciseTrainingLoadWidget()
        .padding(.spacing4x)
}
