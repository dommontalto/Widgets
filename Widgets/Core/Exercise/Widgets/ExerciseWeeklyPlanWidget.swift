//
//  ExerciseWeeklyPlanWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 21/7/2026.
//

import SwiftUI

struct ExerciseWeeklyPlanWidget: View {
    var onStart: () -> Void = {}

    private let bannerHeight: CGFloat = 59
    private let heroHeight: CGFloat = 196

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            banner
            hero
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }

    private var banner: some View {
        HStack(spacing: .spacing105x) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Color.defaultGreen)
                .frame(width: 2, height: 35)
            BrightText("No sessions this week", size: .body1, color: .defaultGreen)
        }
        .padding(.horizontal, .spacing105x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: bannerHeight)
        .background(
            Color.defaultGreen.opacity(.ultraLowOpacity),
            in: RoundedRectangle(cornerRadius: .cornerRadius14, style: .continuous)
        )
    }

    private var hero: some View {
        ZStack {
            Image(ImageNames.exerciseWeeklyPlanV5)
                .resizable()
                .scaledToFill()

            VStack(spacing: .spacing3x) {
                BrightPillButton("Start", textColor: .defaultMainWhite, buttonSize: .large, isClear: true, onTapCallback: onStart)

                BrightText(
                    "Start a program or plan your workouts in advance.",
                    size: .heading,
                    color: .defaultMainWhite,
                    weight: .regular
                )
                .multilineTextAlignment(.center)
                .blendMode(.overlay)
                .frame(width: 236)
            }
            .padding(.top, .spacing3x)
        }
        .frame(height: heroHeight)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius20, style: .continuous))
    }
}

#Preview {
    ExerciseWeeklyPlanWidget()
        .padding(.spacing4x)
}
