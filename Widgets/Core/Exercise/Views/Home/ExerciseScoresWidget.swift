//
//  ExerciseScoresWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 23/7/2026.
//

import SwiftUI

// The three score rings from the iOS app's 2x1 combined-scores widget, bare
// (no card) and with each score named beneath its ring.
struct ExerciseScoresWidget: View {
    @State private var scores = ExerciseDemoData.scores

    var body: some View {
        HStack(spacing: .spacing3x) {
            tile(title: "Recovery", score: scores.recovery, icon: ImageNames.recoveryV5, color: .defaultGreen)
            tile(title: "Stress", score: scores.stress, icon: ImageNames.stressV5, color: .defaultPurple)
            tile(title: "Strain", score: scores.strain, icon: ImageNames.strainV5, color: .defaultRed)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .spacing3x)
    }

    private func tile(title: String, score: Int, icon: String, color: Color) -> some View {
        VStack(spacing: .spacing3x) {
            ScoreRing(score: score, icon: icon, color: color)

            BrightText(title, size: .body2)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ExerciseScoresWidget()
        .padding(.spacing4x)
}
