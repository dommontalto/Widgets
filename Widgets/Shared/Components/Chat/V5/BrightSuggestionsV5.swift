//
//  BrightSuggestionsV5.swift
//  Widgets
//

import SwiftUI

struct BrightSuggestionTopic: Identifiable, Hashable {
    let title: String
    let systemImage: String
    let prompts: [String]

    var id: String { title }
}

// Topic pills a chat shows above its own input instead of its suggestion chips.
struct BrightChatTopics {
    let topics: [BrightSuggestionTopic]
    var opensOnAppear: BrightSuggestionTopic.ID?
    let onSelect: (String) -> Void
}

extension EnvironmentValues {
    @Entry var brightChatTopics: BrightChatTopics?
}

struct BrightSuggestionsV5: View {
    var topics: [BrightSuggestionTopic] = BrightSuggestionsDemo.topics
    var opensOnAppear: BrightSuggestionTopic.ID?
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing1x) {
                ForEach(topics) { topic in
                    BrightTagV5(title: topic.title, systemImage: topic.systemImage, isSelected: true) {}
                        .allowsHitTesting(false)
                        .overlay {
                            BrightSuggestionMenuButton(
                                prompts: Array(topic.prompts.prefix(Constants.promptCount)),
                                opensOnAppear: topic.id == opensOnAppear,
                                onSelect: onSelect
                            )
                        }
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
    }

    private enum Constants {
        static let promptCount = 3
    }
}

// SwiftUI's Menu can't be opened from code; a UIButton's menu can, through performPrimaryAction.
private struct BrightSuggestionMenuButton: UIViewRepresentable {
    let prompts: [String]
    let opensOnAppear: Bool
    let onSelect: (String) -> Void

    func makeUIView(context: Context) -> MenuButton {
        let button = MenuButton()
        button.showsMenuAsPrimaryAction = true
        button.opensOnAppear = opensOnAppear
        button.menu = menu
        return button
    }

    func updateUIView(_ button: MenuButton, context: Context) {
        button.menu = menu
    }

    private var menu: UIMenu {
        UIMenu(children: prompts.map { prompt in
            UIAction(title: prompt, image: UIImage(systemName: Constants.promptSymbol)) { _ in onSelect(prompt) }
        })
    }

    final class MenuButton: UIButton {
        var opensOnAppear = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil, opensOnAppear else { return }
            opensOnAppear = false
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(Constants.openDelay))
                guard let self, self.window != nil else { return }
                self.performPrimaryAction()
            }
        }
    }

    private enum Constants {
        static let openDelay: TimeInterval = 0.5
        static let promptSymbol = "arrow.turn.down.right"
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
