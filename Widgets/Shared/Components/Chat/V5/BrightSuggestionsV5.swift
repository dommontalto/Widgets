//
//  BrightSuggestionsV5.swift
//  Widgets
//

import SwiftUI

// A few prompts to ask, drawn at random from a pool, with Randomise to deal a
// fresh set. Each row sends itself through `onSelect`.
struct BrightSuggestionsV5: View {
    var pool: [String] = BrightSuggestionsDemo.prompts
    var count = Constants.defaultCount
    let onSelect: (String) -> Void

    @State private var shown: [String] = []

    var body: some View {
        VStack(alignment: .trailing, spacing: .spacing1x) {
            BrightPillButton("Randomise", systemImage: "shuffle", buttonSize: .small) {
                withAnimation(.brightSnappy) { deal() }
            }

            VStack(spacing: .spacing0x) {
                ForEach(Array(shown.enumerated()), id: \.element) { index, prompt in
                    row(prompt, isLast: index == shown.count - 1)
                        .transition(.blurReplace)
                }
            }
        }
        .padding(.horizontal, .spacing3x)
        .onAppear {
            if shown.isEmpty { deal() }
        }
    }

    private func row(_ prompt: String, isLast: Bool) -> some View {
        Button {
            onSelect(prompt)
        } label: {
            HStack(spacing: .spacing2x) {
                BrightText(prompt, size: .body1, color: .semiLightTextColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.turn.down.right")
                    .font(.standard(size: .body1, weight: .regular))
                    .foregroundStyle(Color.semiLightTextColor)
            }
            .padding(.vertical, .spacing3x)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                BrightDividerV5()
            }
        }
    }

    // A new set each time, never repeating the one on screen while the pool allows.
    private func deal() {
        let fresh = pool.filter { !shown.contains($0) }
        let source = fresh.count >= count ? fresh : pool
        shown = Array(source.shuffled().prefix(count))
    }

    private enum Constants {
        static let defaultCount = 3
    }
}

// Generic health prompts, until each screen brings its own.
enum BrightSuggestionsDemo {
    static let prompts = [
        "How many Zone 2 minutes do I need to improve my HRV?",
        "Predict my race pace for my upcoming half marathon",
        "At my current activity level, how long will it take me to lose 5 kgs?",
        "What's the best time for me to go to bed tonight?",
        "Why was my resting heart rate higher this week?",
        "How much protein should I be eating each day?",
        "Am I recovered enough to train hard today?",
        "What's been affecting my sleep quality lately?",
        "How does my caffeine intake affect my sleep?",
        "Build me a 4-week plan to improve my VO2 max",
        "Which of my lab markers should I keep an eye on?",
        "How much water should I drink on training days?",
    ]
}

#Preview {
    BrightSuggestionsV5 { _ in }
        .padding(.vertical, .spacing3x)
        .background(Color.defaultBackground)
}
