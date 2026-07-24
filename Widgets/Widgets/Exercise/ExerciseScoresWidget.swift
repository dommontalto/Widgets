//
//  ExerciseScoresWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 23/7/2026.
//

import SwiftUI

struct ExerciseScoresWidget: View {
    @State private var scores = ExerciseDemoData.scores

    var body: some View {
        HStack(spacing: .spacing105x) {
            tile(title: "Recovery", value: scores.recovery, imageName: ImageNames.exerciseRecoveryV5) {
                Image(systemName: "arrow.trianglehead.2.clockwise")
            }
            tile(title: "Fatigue", value: scores.fatigue, imageName: ImageNames.exerciseFatigueV5) {
                HStack(spacing: -.spacing05x) {
                    Image(systemName: "chevron.right")
                    Image(systemName: "chevron.left")
                }
            }
            tile(title: "Readiness", value: scores.readiness, imageName: ImageNames.exerciseReadinessV5) {
                Image(systemName: "arrow.left.and.line.vertical.and.arrow.right")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func tile(
        title: String,
        value: Int,
        imageName: String,
        @ViewBuilder icon: () -> some View
    ) -> some View {
        VStack(spacing: .spacing105x) {
            ZStack {
                Image(imageName)
                    .resizable()
                    .scaledToFit()

                VStack(spacing: .spacing1x) {
                    Text("\(value)")
                        .font(.standardSFPro(size: .huge, weight: .light))
                        .monospacedDigit()
                    icon()
                        .font(.standardSFPro(size: .subheading, weight: .medium))
                }
                .foregroundStyle(Color.black)
                .blendMode(.overlay)
            }
            .aspectRatio(1, contentMode: .fit)

            BrightText(title, size: .body2)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ExerciseScoresWidget()
        .padding(.spacing4x)
}
