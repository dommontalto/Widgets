//
//  BrightSuggestionsV5.swift
//  Widgets
//

import SwiftUI

// A topic to start from, holding the prompts it deals.
struct BrightSuggestionTopic: Identifiable, Hashable {
    let title: String
    let systemImage: String
    let prompts: [String]

    var id: String { title }
}

// Topic tags first; picking one swaps them for a few of its prompts, drawn at
// random, with Randomise to deal a fresh set and back to return to the tags.
// Each prompt sends itself through `onSelect`.
struct BrightSuggestionsV5: View {
    var topics: [BrightSuggestionTopic] = BrightSuggestionsDemo.topics
    var count = Constants.defaultCount
    let onSelect: (String) -> Void

    @State private var topic: BrightSuggestionTopic?
    @State private var shown: [String] = []
    // Flipped once the prompts are on screen, so their rows can stagger in after the slide.
    @State private var isRevealed = false

    var body: some View {
        Group {
            if let topic {
                prompts(in: topic)
                    .padding(.horizontal, .spacing3x)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .onAppear { isRevealed = true }
            } else {
                tags
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
    }

    private var tags: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing1x) {
                ForEach(topics) { topic in
                    BrightTagV5(title: topic.title, systemImage: topic.systemImage, isSelected: true) {
                        open(topic)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
    }

    private func prompts(in topic: BrightSuggestionTopic) -> some View {
        VStack(spacing: .spacing1x) {
            HStack(spacing: .spacing0x) {
                BrightRoundButton(systemImage: "arrow.left", size: .small) {
                    isRevealed = false
                    withAnimation(.brightLiquid) { self.topic = nil }
                }
                .accessibilityLabel(Constants.backLabel)

                Spacer(minLength: .spacing2x)

                BrightPillButton(Constants.randomiseTitle, systemImage: "shuffle", buttonSize: .small) {
                    withAnimation(.brightSnappy) { deal(from: topic) }
                }
            }

            VStack(spacing: .spacing0x) {
                ForEach(Array(shown.enumerated()), id: \.element) { index, prompt in
                    row(prompt, isLast: index == shown.count - 1)
                        .opacity(isRevealed ? .opaque : .zero)
                        .offset(y: isRevealed ? .zero : .spacing2x)
                        .animation(.brightStaggered(Double(index) * Constants.staggerStep), value: isRevealed)
                        .transition(.blurReplace)
                }
            }
        }
    }

    private func row(_ prompt: String, isLast: Bool) -> some View {
        Button {
            onSelect(prompt)
        } label: {
            HStack(spacing: .spacing2x) {
                BrightText(prompt, size: .body1, color: .semiLightTextColor)
                    .lineLimit(Constants.lineLimit)
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

    private func open(_ topic: BrightSuggestionTopic) {
        shown = []
        deal(from: topic)
        withAnimation(.brightLiquid) { self.topic = topic }
    }

    // A new set each time, never repeating the one on screen while the topic allows.
    private func deal(from topic: BrightSuggestionTopic) {
        let fresh = topic.prompts.filter { !shown.contains($0) }
        let source = fresh.count >= count ? fresh : topic.prompts
        shown = Array(source.shuffled().prefix(count))
    }

    private enum Constants {
        static let defaultCount = 3
        static let lineLimit = 2
        static let staggerStep = 0.06
        static let randomiseTitle = "Randomise"
        static let backLabel = "Back to topics"
    }
}

// Generic health topics, until each screen brings its own.
enum BrightSuggestionsDemo {
    static let topics = [
        BrightSuggestionTopic(
            title: "Forecast metrics",
            systemImage: "graph.2d",
            prompts: [
                "Predict my race pace for my upcoming half marathon based on my recent runs",
                "Where will my resting heart rate be in a month if I keep training like this?",
                "Forecast my VO2 max over the next twelve weeks at my current training load",
                "At my current activity level, how long will it take me to lose 5 kgs?",
                "How will my HRV trend over the next fortnight if my sleep stays the same?",
                "When am I likely to hit my step goal every day at this current rate?",
                "Predict my sleep score this week based on my last month of bedtimes",
                "How long until my body fat reaches 15% if I keep my current calories?",
                "Forecast my recovery for this weekend given this week's training load",
            ]
        ),
        BrightSuggestionTopic(
            title: "Create check-in",
            systemImage: "person.badge.clock.fill",
            prompts: [
                "Check in with me every morning about how well I slept the night before",
                "Remind me each evening to log my water intake and how I'm feeling today",
                "Set up a weekly check-in on my training load and how recovered I feel",
                "Ask me after every workout how hard it felt and whether anything hurt",
                "Check in each night about my stress levels and what caused them today",
                "Create a monthly review of my weight, sleep and resting heart rate trends",
                "Remind me mid-afternoon to get up and walk if my steps are running low",
                "Check in on my mood each morning and spot patterns with my sleep data",
                "Ask me weekly whether I'm sticking to my nutrition plan and what's hard",
            ]
        ),
        BrightSuggestionTopic(
            title: "Create a training plan",
            systemImage: "figure.run",
            prompts: [
                "Build me a twelve week plan to run a half marathon in under two hours",
                "Create a strength plan for three days a week that fits around my runs",
                "How many Zone 2 minutes do I need each week to improve my HRV?",
                "Plan a four week block to raise my VO2 max without overtraining myself",
                "Make me a beginner's plan to run 5 km without stopping in six weeks",
                "Design a mobility routine I can do in ten minutes before every session",
                "Create a deload week based on my current training load and recovery",
                "Build a cycling plan to lift my FTP by 10% before the end of summer",
                "Plan my training around my cycle so harder sessions land on better days",
            ]
        ),
        BrightSuggestionTopic(
            title: "Impact analysis",
            systemImage: "exclamationmark.magnifyingglass",
            prompts: [
                "How does drinking alcohol in the evening affect my sleep and recovery?",
                "Does caffeine after midday change how long it takes me to fall asleep?",
                "What impact do late workouts have on my resting heart rate overnight?",
                "How much does a bad night's sleep affect my HRV the following day?",
                "Is my screen time before bed hurting my deep sleep? Show me the data",
                "How do my rest days change my recovery score compared with active ones?",
                "What effect has my higher protein intake had on my body composition?",
                "Does travelling across time zones still show up in my sleep a week later?",
                "How do stressful days at work show up in my heart rate and my sleep?",
            ]
        ),
    ]
}

#Preview {
    BrightSuggestionsV5 { _ in }
        .padding(.vertical, .spacing3x)
        .background(Color.defaultBackground)
}
