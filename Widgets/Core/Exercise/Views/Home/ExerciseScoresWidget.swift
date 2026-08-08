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
            tile(title: "Stress", value: scores.stress, imageName: ImageNames.exerciseStressV5) {
                HStack(spacing: -.spacing05x) {
                    Image(systemName: "chevron.right")
                    Image(systemName: "chevron.left")
                }
            }
            tile(title: "Strain", value: scores.strain, imageName: ImageNames.exerciseStrainV5) {
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
                    BrightText("\(value)", size: .huge, color: .black)
                    icon()
                        .font(.standard(size: .subheading, weight: .medium))
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
