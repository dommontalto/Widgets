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
    // Shown whole and in the order given, with no Randomise, for prompts already picked and ranked.
    var isFixed = false

    var id: String { title }
}

// Topic tags first; picking one grows that tag into a glass card of a few of its
// prompts, drawn at random, with Randomise to deal a fresh set and back to shrink
// it into the tags again. Each prompt sends itself through `onSelect` and folds the card away.
struct BrightSuggestionsV5: View {
    var topics: [BrightSuggestionTopic] = BrightSuggestionsDemo.topics
    var count = Constants.defaultCount
    // Opens straight into this topic's prompts; back still returns to the tags.
    var initialTopic: BrightSuggestionTopic?
    let onSelect: (String) -> Void

    @State private var topic: BrightSuggestionTopic?
    @State private var shown: [String] = []
    // Flipped once the prompts are on screen, so their rows can stagger in after the slide.
    @State private var isRevealed = false

    @Namespace private var morph

    var body: some View {
        Group {
            if let topic {
                prompts(in: topic)
                    .padding(.spacing3x)
                    .modifier(BrightGlassEffectV5(shape: .roundedRect, cornerRadius: .cardCornerRadius, interactive: false))
                    .matchedGeometryEffect(id: topic.id, in: morph)
                    .padding(.horizontal, .spacing3x)
                    .transition(.opacity)
                    .onAppear { isRevealed = true }
            } else {
                tags
                    .transition(.opacity)
            }
        }
        .onAppear {
            guard topic == nil, let initialTopic else { return }
            deal(from: initialTopic)
            topic = initialTopic
        }
    }

    private var tags: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing1x) {
                ForEach(topics) { topic in
                    BrightTagV5(title: topic.title, systemImage: topic.systemImage, isSelected: true) {
                        open(topic)
                    }
                    .matchedGeometryEffect(id: topic.id, in: morph)
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
    }

    private func prompts(in topic: BrightSuggestionTopic) -> some View {
        VStack(spacing: .spacing1x) {
            HStack(spacing: .spacing0x) {
                BrightRoundButton(systemImage: "arrow.left", size: .small, onTapCallback: close)
                .accessibilityLabel(Constants.backLabel)

                Spacer(minLength: .spacing2x)

                if !topic.isFixed {
                    BrightPillButton(Constants.randomiseTitle, systemImage: "shuffle", buttonSize: .small) {
                        withAnimation(.brightSnappy) { deal(from: topic) }
                    }
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
            close()
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

    private func close() {
        isRevealed = false
        withAnimation(.brightLiquid) { topic = nil }
    }

    private func open(_ topic: BrightSuggestionTopic) {
        shown = []
        deal(from: topic)
        withAnimation(.brightLiquid) { self.topic = topic }
    }

    // A new set each time, never repeating the one on screen while the topic allows.
    private func deal(from topic: BrightSuggestionTopic) {
        guard !topic.isFixed else {
            shown = topic.prompts
            return
        }
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
                "Predict my half marathon pace",
                "My resting heart rate in a month?",
                "Forecast my VO2 max for 12 weeks",
                "How long to lose 5 kg?",
                "Where's my HRV heading?",
                "When will I hit my step goal daily?",
                "Predict this week's sleep score",
                "When will I reach 15% body fat?",
                "How recovered will I be this weekend?",
            ]
        ),
        BrightSuggestionTopic(
            title: "Create check-in",
            systemImage: "person.badge.clock.fill",
            prompts: [
                "Ask how I slept each morning",
                "Remind me to log water each evening",
                "Weekly check-in on my training load",
                "Ask how each workout felt",
                "Check in on my stress each night",
                "Monthly review of my key trends",
                "Nudge me to walk if steps are low",
                "Track my mood against my sleep",
                "Weekly check on my nutrition plan",
            ]
        ),
        BrightSuggestionTopic(
            title: "Create a training plan",
            systemImage: "figure.run",
            prompts: [
                "12-week sub-2 half marathon plan",
                "3-day strength plan around my runs",
                "How much Zone 2 for better HRV?",
                "4 weeks to raise my VO2 max",
                "Couch to 5 km in six weeks",
                "10-minute pre-session mobility",
                "Plan a deload week for me",
                "Lift my FTP by 10% this summer",
                "Train around my cycle",
            ]
        ),
        BrightSuggestionTopic(
            title: "Impact analysis",
            systemImage: "exclamationmark.magnifyingglass",
            prompts: [
                "How does alcohol affect my sleep?",
                "Does afternoon caffeine keep me up?",
                "Do late workouts raise my heart rate?",
                "How does bad sleep hit my HRV?",
                "Is screen time hurting my deep sleep?",
                "Rest days vs active days on recovery",
                "What has extra protein done for me?",
                "How long does jet lag affect my sleep?",
                "How does work stress show up in me?",
            ]
        ),
    ]
}

#Preview {
    BrightSuggestionsV5 { _ in }
        .padding(.vertical, .spacing3x)
        .background(Color.defaultBackground)
}
