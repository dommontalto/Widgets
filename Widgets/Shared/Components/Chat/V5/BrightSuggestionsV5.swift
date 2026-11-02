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
        "How do I improve my HRV?",
        "Predict my half marathon pace",
        "How long to lose 5 kg?",
        "When should I sleep tonight?",
        "Why is my resting HR up?",
        "How much protein do I need?",
        "Am I recovered to train hard?",
        "What's affecting my sleep?",
        "Does caffeine hurt my sleep?",
        "Plan to raise my VO2 max",
        "Which lab markers to watch?",
        "How much water on training days?",
    ]
}

#Preview {
    BrightSuggestionsV5 { _ in }
        .padding(.vertical, .spacing3x)
        .background(Color.defaultBackground)
}
