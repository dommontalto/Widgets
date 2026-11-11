//
//  BrightSuggestionsV5.swift
//  Widgets
//

import SwiftUI

struct BrightSuggestionTopic: Identifiable, Hashable {
    let title: String
    let systemImage: String
    let prompts: [String]
    var isFixed = false

    var id: String { title }
}

struct BrightChatTopics {
    let topics: [BrightSuggestionTopic]
    let onSelect: (String) -> Void
}

extension EnvironmentValues {
    @Entry var brightChatTopics: BrightChatTopics?
}

struct BrightSuggestionsV5: View {
    var topics: [BrightSuggestionTopic] = BrightSuggestionsDemo.topics
    var count = Constants.defaultCount
    let onSelect: (String) -> Void

    @State private var shown: [BrightSuggestionTopic.ID: [String]] = [:]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing1x) {
                ForEach(topics) { topic in
                    menu(for: topic)
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
        .brightHorizontalBlurV5()
        .onAppear {
            for topic in topics where shown[topic.id] == nil {
                deal(from: topic)
            }
        }
    }

    private func menu(for topic: BrightSuggestionTopic) -> some View {
        Menu {
            ForEach(prompts(in: topic), id: \.self) { prompt in
                Button(prompt, systemImage: Constants.promptSymbol) {
                    onSelect(prompt)
                }
            }

            if !topic.isFixed {
                Divider()

                Button(Constants.randomiseTitle, systemImage: Constants.randomiseSymbol) {
                    deal(from: topic)
                }
                .menuActionDismissBehavior(.disabled)
            }
        } label: {
            BrightTagV5(title: topic.title, systemImage: topic.systemImage, isSelected: true) {}
                .allowsHitTesting(false)
        }
        .menuOrder(.fixed)
    }

    private func prompts(in topic: BrightSuggestionTopic) -> [String] {
        topic.isFixed ? Array(topic.prompts.prefix(count)) : shown[topic.id] ?? Array(topic.prompts.prefix(count))
    }

    private func deal(from topic: BrightSuggestionTopic) {
        guard !topic.isFixed else { return }
        let current = shown[topic.id] ?? []
        let fresh = topic.prompts.filter { !current.contains($0) }
        let source = fresh.count >= count ? fresh : topic.prompts
        shown[topic.id] = Array(source.shuffled().prefix(count))
    }

    private enum Constants {
        static let defaultCount = 3
        static let promptSymbol = "arrow.turn.down.right"
        static let randomiseTitle = "Randomise"
        static let randomiseSymbol = "shuffle"
    }
}

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
