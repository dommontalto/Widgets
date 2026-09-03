//
//  ExerciseChatView.swift
//  Widgets
//
//  Created by Dom Montalto on 21/8/2026.
//

import SwiftUI

nonisolated enum ExerciseChatPayload: Equatable {
    // A clarifying question with quick-reply chips; tapping one answers for
    // the user, and typing works just the same.
    case questions([String])
    // The canned program reply: the week cards under the intro text.
    case program([ExerciseChatProgramWeek])
}

typealias ExerciseChatMessage = BrightChatMessage<ExerciseChatPayload>

nonisolated struct ExerciseChatProgramWeek: Identifiable, Equatable {
    nonisolated struct Entry: Identifiable, Equatable {
        let id = UUID()
        let count: String
        let detail: String
    }

    let id = UUID()
    let name: String
    let entries: [Entry]
}

// A demo chat with the AI coach: `BrightChat` supplies the thread, the empty
// state and the input bar; this view adds the quick-reply chips and the week
// cards as the reply designs. The first reply asks a clarifying question, the
// second proposes the program. Embedded as the guided step of the program
// builder, which supplies the wash behind it.
struct ExerciseChatView: View {
    var isTyping: FocusState<Bool>.Binding

    // Raised once a program has been proposed, so the builder can offer its
    // create action in the toolbar.
    @Binding var hasPlan: Bool

    @State private var messages = [ExerciseChatMessage]()
    @State private var isThinking = false
    @State private var replyIndex = 0
    @State private var replyTask: Task<Void, Never>?

    var body: some View {
        BrightChat(
            messages: messages,
            isThinking: isThinking,
            isBusy: isThinking,
            isTyping: isTyping,
            emptyState: BrightChatEmptyState(title: "Guided Program", examples: Constants.examples),
            onSend: deliver,
            onStop: stopThinking
        ) { message in
            response(message)
        }
        .onDisappear { replyTask?.cancel() }
    }

    @ViewBuilder
    private func response(_ message: ExerciseChatMessage) -> some View {
        switch message.payload {
        case let .questions(options):
            questionResponse(message, options: options)
        case let .program(weeks):
            programResponse(message, weeks: weeks)
        case nil:
            assistantText(message.text)
        }
    }

    private func assistantText(_ text: String) -> some View {
        BrightText(text, size: .body1)
            .lineSpacing(.lineSpacingMedium)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Clarifying questions

    // The question reads like any coach message; the chips underneath make
    // answering two taps, and they leave once the answer is in.
    private func questionResponse(_ message: ExerciseChatMessage, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            assistantText(message.text)

            if !options.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .spacing1x) {
                        ForEach(options, id: \.self) { option in
                            chip(option) { answer(option, to: message) }
                        }
                    }
                }
                .scrollClipDisabled()
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ title: String, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            BrightText(title, size: .body2)
                .padding(.horizontal, .spacing2x)
                .frame(height: .spacing5x)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .modifier(GlassEffect(shape: .capsule))
    }

    private func answer(_ option: String, to message: ExerciseChatMessage) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }

        withAnimation(.brightSnappy) {
            messages[index].payload = .questions([])
        }
        deliver(option)
    }

    // MARK: - Program response

    private func programResponse(_ message: ExerciseChatMessage, weeks: [ExerciseChatProgramWeek]) -> some View {
        VStack(spacing: .spacing2x) {
            assistantText(message.text)
                .padding(.bottom, .spacing105x)

            ForEach(weeks) { week in
                weekSection(week)
            }
        }
    }

    private func weekSection(_ week: ExerciseChatProgramWeek) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(week.name, size: .body2, color: .semiLightTextColor)

            BrightDivider()

            ForEach(week.entries) { entry in
                weekEntry(entry, isLast: entry == week.entries.last)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func weekEntry(_ entry: ExerciseChatProgramWeek.Entry, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            BrightText(entry.count, size: .standout3, weight: .regular)
                .monospacedDigit()

            BrightText(entry.detail, size: .body2, color: .lightTextColor, scaleTextSize: Constants.detailScale)
                .lineLimit(1)
        }

        if !isLast {
            BrightDivider()
        }
    }

    // MARK: - Fake replies

    private func deliver(_ text: String) {
        withAnimation(.brightSnappy) {
            messages.append(ExerciseChatMessage(kind: .user, text: text))
            isThinking = true
        }

        replyTask = Task { await reply() }
    }

    // The first reply asks the one thing the goal alone can't answer, the
    // second proposes the program, and everything after is chatter.
    private func reply() async {
        do {
            try await Task.sleep(for: .seconds(Double.random(in: Constants.thinkingRange)))
        } catch {
            return
        }

        let message: ExerciseChatMessage = switch replyIndex {
        case 0:
            ExerciseChatMessage(
                kind: .response,
                text: Constants.questionIntro,
                payload: .questions(Constants.questionOptions)
            )
        case 1:
            ExerciseChatMessage(
                kind: .response,
                text: Constants.programIntro,
                payload: .program(Constants.programWeeks)
            )
        default:
            ExerciseChatMessage(
                kind: .assistant,
                text: Constants.replies[(replyIndex - 2) % Constants.replies.count]
            )
        }
        replyIndex += 1

        withAnimation(.brightSnappy) {
            isThinking = false
            messages.append(message)
            hasPlan = messages.contains { message in
                if case .program = message.payload { true } else { false }
            }
        }
    }

    private func stopThinking() {
        replyTask?.cancel()
        replyTask = nil
        withAnimation(.brightSnappy) { isThinking = false }
    }

    private enum Constants {
        static let thinkingRange = 4.5...6.5

        static let examples = [
            BrightChatExample("figure.run", "Get me from the couch to a 5K in eight weeks."),
            BrightChatExample("stopwatch", "Build a half marathon plan around three runs a week."),
            BrightChatExample("calendar", "Plan my strength around Tuesday, Thursday and Saturday."),
            BrightChatExample("figure.strengthtraining.traditional", "Help me squat 100kg by Christmas."),
            BrightChatExample("figure.skiing.downhill", "Six weeks of ski prep for my legs and core."),
            BrightChatExample("bandage.fill", "My left shoulder is cranky, so plan around it."),
            BrightChatExample("figure.walk", "Ease me back into running after two months off."),
            BrightChatExample("figure.pool.swim", "Two gym sessions and one swim, every week."),
            BrightChatExample("figure.hiking", "Get me strong enough for the Tongariro Crossing."),
            BrightChatExample("chart.xyaxis.line", "Keep my base through the off-season without burning out."),
        ]

        // The interval lines are designed to sit on one line, so they shrink
        // a touch rather than wrap.
        static let detailScale: CGFloat = 0.85

        static let questionIntro = "Happy to build that — one thing first: how many days "
            + "a week can you realistically train?"

        static let questionOptions = ["2 days", "3 days", "4 days", "5 days"]

        static let programIntro = "8-Week Couch to 5K Program Schedule: 3 runs per week, "
            + "with at least 1 rest day between runs. Effort: Keep all running at an easy, "
            + "conversational pace. Walking recoveries should be relaxed."

        static let runDetail = "5 min walk → 1 min run / 2 min walk × 8 → 5 min walk"

        static let programWeeks = [
            ExerciseChatProgramWeek(name: "Week 1", entries: [
                .init(count: "3×", detail: runDetail),
                .init(count: "2×", detail: "3 Sets | 12 Reps of toe curls"),
            ]),
            ExerciseChatProgramWeek(name: "Week 2", entries: [
                .init(count: "3×", detail: runDetail),
            ]),
            ExerciseChatProgramWeek(name: "Week 3", entries: [
                .init(count: "3×", detail: runDetail),
            ]),
        ]

        static let replies = [
            "Week 1: run 1 minute, walk 90 seconds, repeat 8 times. The strength days are 20 minutes — calf raises, step-downs, glute bridges and side planks.",
            "I've spaced the runs with a rest day between each. If your shins flare up, repeat the previous week and keep the strength work going.",
        ]
    }
}

private struct ExerciseChatViewPreview: View {
    @FocusState private var isTyping: Bool
    @State private var hasPlan = false

    var body: some View {
        ExerciseChatView(isTyping: $isTyping, hasPlan: $hasPlan)
            .background { ExerciseProgramBackground() }
    }
}

#Preview {
    ExerciseChatViewPreview()
}
