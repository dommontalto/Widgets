//
//  LighthouseThinkingStatus.swift
//  Widgets
//
//  Created by Dom Montalto on 15/9/2026.
//

import SwiftUI

// What the island is doing, under the orb. Thinking shows a fixed
// "Generating" with the thought process's glyphs swapping through beside it,
// so the row never changes width; listening shows the mic.
struct LighthouseThinkingStatus: View {
    var isListening = false

    @State private var stepIndex = 0

    private var step: LighthouseThoughtStep {
        LighthouseDemo.thoughtSteps[stepIndex % LighthouseDemo.thoughtSteps.count]
    }

    var body: some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: isListening ? "mic.fill" : step.symbol)
                .font(.standard(size: .body1, weight: .light))
                .foregroundStyle(Color.semiLightTextColor)
                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))

            BrightText(isListening ? Constants.listeningTitle : Constants.generatingTitle, size: .body1, color: .semiLightTextColor)
                .contentTransition(.opacity)

            if !isListening {
                Image(systemName: "chevron.forward")
                    .font(.standard(size: .body4, weight: .regular))
                    .foregroundStyle(Color.semiLightTextColor)
                    .transition(.opacity)
            }
        }
        .animation(.brightEaseInOut, value: stepIndex)
        .animation(.brightEaseInOut, value: isListening)
        .task(id: isListening) {
            guard !isListening else { return }
            while true {
                do {
                    try await Task.sleep(for: .seconds(Constants.stepEvery))
                } catch {
                    return
                }
                stepIndex += 1
            }
        }
    }

    private enum Constants {
        static let generatingTitle = "Generating"
        static let listeningTitle = "Listening"
        static let stepEvery: TimeInterval = 1.4
    }
}

#Preview {
    Color.defaultBackground
        .ignoresSafeArea()
        .overlay {
            BrightIslandIndicator {
                BrightSolvingStars(state: .thinking, ambientMotion: .off)
                    .aspectRatio(1, contentMode: .fit)
                    .containerRelativeFrame(.horizontal) { width, _ in width * 0.3 }
            } footer: {
                LighthouseThinkingStatus()
            }
        }
}
