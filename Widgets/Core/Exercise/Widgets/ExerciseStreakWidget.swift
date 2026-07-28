//
//  ExerciseStreakWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

struct ExerciseStreakWidget: View {
    private let streakWeeks = 7
    private let weekTarget = 4
    private let recentWeeks = [4, 5, 4, 6, 4, 5, 4]

    var body: some View {
        HStack(spacing: .spacing3x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                HStack(spacing: .spacing1x) {
                    Image(systemName: "flame")
                        .font(.standardSFPro(size: .standout3, weight: .light))
                        .foregroundStyle(Color.defaultOrange)
                    BrightText("\(streakWeeks)", size: .huge)
                        .monospacedDigit()
                }
                BrightText("week streak", size: .body3, color: .semiLightTextColor)
                BrightText("\(weekTarget)+ sessions / week", size: .body4, color: .lightTextColor)
            }

            Spacer(minLength: .spacing2x)

            HStack(alignment: .bottom, spacing: .spacing05x) {
                ForEach(recentWeeks.indices, id: \.self) { i in
                    Capsule()
                        .fill(
                            recentWeeks[i] >= weekTarget
                                ? Color.defaultOrange
                                : Color.defaultOrange.opacity(.veryMinimalOpacity)
                        )
                        .frame(width: Constants.barWidth, height: Constants.barUnit * CGFloat(recentWeeks[i]))
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }

    private class Constants {
        static let barWidth: CGFloat = 9
        static let barUnit: CGFloat = 9
    }
}

#Preview {
    ExerciseStreakWidget()
        .padding(.spacing4x)
}
