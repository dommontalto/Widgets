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

    // In the app a tapped ring presents the wellbeing stats sheet for that
    // score; the sheet has no prototype counterpart, so the tap surfaces here.
    var onSelectScore: ((String) -> Void)?

    var body: some View {
        HStack(spacing: .spacing2x) {
            tile(title: "Recovery", score: scores.recovery, color: .defaultGreen)
            tile(title: "Fatigue", score: scores.fatigue, color: .defaultRed)
            tile(title: "Readiness", score: scores.readiness, color: .defaultSkyBlue)
        }
        .frame(maxWidth: .infinity)
    }

    private func tile(title: String, score: Int, color: Color) -> some View {
        Button {
            onSelectScore?(title)
        } label: {
            VStack(spacing: .spacing105x) {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        ScoreRing(score: score, color: color, valueSize: .standout1)
                    }
                    .modifier(GlassCardModifier())

                BrightText(title, size: .body1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExerciseScoresWidget()
        .padding(.spacing4x)
}
