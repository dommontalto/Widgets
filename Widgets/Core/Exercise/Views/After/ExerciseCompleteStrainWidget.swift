//
//  ExerciseCompleteStrainWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

struct ExerciseCompleteStrainWidget: View {
    let strain: ExerciseCompleteStrain

    var body: some View {
        HStack(spacing: .spacing2x) {
            BrightText(String(strain.value), size: .huge2)
                .monospacedDigit()

            BrightText(strain.label.uppercased(), size: .body1, color: .defaultRed)
                .padding(.horizontal, .spacing1x)
                .frame(height: Constants.tagHeight)
                .background(Capsule().fill(Color.defaultRed.opacity(.minimalOpacity)))

            Spacer(minLength: .spacing2x)

            ring
        }
        .padding(.horizontal, .spacing3x)
        .frame(height: Constants.cardHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.defaultRed.opacity(.minimalOpacity), lineWidth: Constants.ringWidth)

            Circle()
                .trim(from: 0, to: strain.fraction)
                .stroke(
                    Color.defaultRed,
                    style: StrokeStyle(lineWidth: Constants.ringWidth, lineCap: .round)
                )
                // Zero at the top rather than at three o'clock.
                .rotationEffect(.degrees(-90))
        }
        .frame(width: Constants.ringSize, height: Constants.ringSize)
    }

    private enum Constants {
        static let cardHeight: CGFloat = 72
        static let tagHeight: CGFloat = 30
        static let ringSize: CGFloat = 48
        static let ringWidth: CGFloat = 7
    }
}

#Preview {
    ExerciseWidgetSection(icon: .symbol("arrow.left.and.right"), title: "Session Strain") {
        ExerciseCompleteStrainWidget(strain: ExerciseDemoComplete.strength.strain!)
    }
        .padding(.spacing3x)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.defaultSheetBackground.ignoresSafeArea())
}
