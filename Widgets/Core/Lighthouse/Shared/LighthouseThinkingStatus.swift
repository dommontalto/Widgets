//
//  LighthouseThinkingStatus.swift
//  Widgets
//
//  Created by Dom Montalto on 15/9/2026.
//

import SwiftUI

// What the island is doing, under the orb. Thinking walks through the
// thought process's steps, the glyph morphing and the title rolling over
// like a counter as each one arrives; listening shows the mic. The island
// is black in both modes, so the row is always white.
struct LighthouseThinkingStatus: View {
    var isListening = false

    @State private var stepIndex = 0

    private var step: LighthouseThoughtStep {
        LighthouseDemo.thoughtSteps[stepIndex % LighthouseDemo.thoughtSteps.count]
    }

    private var title: String {
        isListening ? Constants.listeningTitle : step.title
    }

    private var shortTitle: String {
        let first = title.split(separator: " ").first.map(String.init) ?? title
        return first == title ? title : first + Constants.ellipsis
    }

    var body: some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: isListening ? "mic.fill" : step.symbol)
                .font(.standard(size: .body2, weight: .light))
                .foregroundStyle(Color.white.opacity(.mediumOpacity))
                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))

            // The whole title when it fits; otherwise the first word and an
            // ellipsis, rather than a word chopped mid-way.
            ViewThatFits(in: .horizontal) {
                statusTitle(title)
                statusTitle(shortTitle)
            }

            if !isListening {
                Image(systemName: "chevron.forward")
                    .font(.standard(size: .body2, weight: .regular))
                    .foregroundStyle(Color.white.opacity(.mediumOpacity))
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

    private func statusTitle(_ text: String) -> some View {
        BrightText(text, size: .body2, color: .white.opacity(.mediumOpacity))
            .lineLimit(1)
            .fixedSize()
            .contentTransition(.numericText())
    }

    private enum Constants {
        static let ellipsis = "…"
        static let listeningTitle = "Listening"
        static let stepEvery: TimeInterval = 2
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
