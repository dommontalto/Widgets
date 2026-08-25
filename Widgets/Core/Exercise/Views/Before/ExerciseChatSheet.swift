//
//  ExerciseChatSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 21/8/2026.
//

// DONT PORT THIS FILE TO IOS YET

import SwiftUI

nonisolated struct ExerciseChatMessage: Identifiable, Equatable {
    enum Kind: Equatable {
        case user
        case assistant
        // The canned program reply: intro text followed by the week cards
        // and the generate prompt.
        case program
    }

    let id = UUID()
    let kind: Kind
    let text: String
}

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

// A demo chat with the AI coach: what you type lands as an iMessage-style
// bubble, the assistant "thinks" for a beat, then a canned reply slides in.
// The first reply is the program response — plain text, the week cards and
// a generate button, per the Figma prompt-program screens.
struct ExerciseChatSheet: View {
    @State private var messages = [ExerciseChatMessage]()
    @State private var draft = ""
    @State private var isThinking = false
    @State private var replyIndex = 0
    @State private var hasGenerated = false
    @State private var replyTask: Task<Void, Never>?
    @FocusState private var isTyping: Bool

    var body: some View {
        BrightPageSheetView(
            // The wash has to run edge to edge, so the sheet's own padding is
            // turned off and the thread and input bar pad themselves.
            horizontalPadding: .spacing0x,
            showBackButton: true,
            bottomSafeArea: false,
            trailing: {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(file: #file)
                }
            },
            content: {
                thread
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background { ExerciseProgramBackground() }
                    .safeAreaInset(edge: .bottom, spacing: .spacing1x) {
                        inputBar
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        )
        .brightHaptic(.light, trigger: messages.count)
        .onDisappear { replyTask?.cancel() }
    }

    // MARK: - Thread

    private var thread: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: .spacing3x) {
                ForEach(messages) { message in
                    row(for: message)
                }

                if isThinking {
                    thinkingIndicator
                }
            }
            .padding(.spacing3x)
        }
        .defaultScrollAnchor(.bottom)
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
    }

    @ViewBuilder
    private func row(for message: ExerciseChatMessage) -> some View {
        Group {
            switch message.kind {
            case .user:
                userBubble(message)
            case .assistant:
                assistantText(message.text)
            case .program:
                programResponse(message)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // Only what you send sits in a bubble — the coach answers straight onto
    // the wash.
    private func userBubble(_ message: ExerciseChatMessage) -> some View {
        HStack(spacing: .spacing0x) {
            Spacer(minLength: .spacing8x)

            BrightText(message.text, size: .body1)
                .lineSpacing(.lineSpacingMedium)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, .spacing3x)
                .padding(.vertical, .spacing2x)
                .modifier(GlassEffect(
                    shape: .roundedRect,
                    cornerRadius: .cardCornerRadius,
                    tint: .defaultWhite.opacity(.veryMinimalOpacity),
                    interactive: false
                ))
                .shadow(color: .black.opacity(.ultraLowOpacity), radius: 15)
        }
    }

    private func assistantText(_ text: String) -> some View {
        BrightText(text, size: .body2)
            .lineSpacing(.lineSpacingMedium)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var thinkingIndicator: some View {
        BrightSolvingOrb(size: Constants.orbSize, speed: Constants.orbSpeed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity)
    }

    // MARK: - Program response

    private func programResponse(_ message: ExerciseChatMessage) -> some View {
        VStack(spacing: .spacing2x) {
            assistantText(message.text)
                .padding(.bottom, .spacing105x)

            ForEach(Constants.programWeeks) { week in
                weekCard(week)
            }

            if !hasGenerated {
                BrightText(Constants.programQuestion, size: .body2, color: .semiLightTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, .spacing4x)

                BrightPillButton(
                    "Generate",
                    color: .defaultGreen,
                    textColor: .defaultWhite,
                    buttonSize: .large
                ) {
                    generate()
                }
                .padding(.top, .spacing1x)
            }
        }
    }

    private func weekCard(_ week: ExerciseChatProgramWeek) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(week.name, size: .body2, color: .semiLightTextColor)

            BrightDivider()

            ForEach(week.entries) { entry in
                weekEntry(entry, isLast: entry == week.entries.last)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing3x)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    @ViewBuilder
    private func weekEntry(_ entry: ExerciseChatProgramWeek.Entry, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            BrightText(entry.count, size: .standout4, weight: .regular)
                .monospacedDigit()

            BrightText(entry.detail, size: .body2, color: .lightTextColor, scaleTextSize: Constants.detailScale)
                .lineLimit(1)
        }

        if !isLast {
            BrightDivider()
        }
    }

    // MARK: - Input

    private var inputBar: some View {
        BrightPromptInputBar(
            text: $draft,
            isBusy: isThinking,
            isFocused: $isTyping,
            onSend: send,
            onStop: stopThinking
        )
        .padding(.spacing3x)
    }

    // MARK: - Fake replies

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        draft = ""
        withAnimation(.brightSnappy) {
            messages.append(ExerciseChatMessage(kind: .user, text: text))
            isThinking = true
        }

        replyTask = Task { await reply() }
    }

    private func reply() async {
        do {
            try await Task.sleep(for: .seconds(Double.random(in: Constants.thinkingRange)))
        } catch {
            return
        }

        let message: ExerciseChatMessage = if replyIndex == 0 {
            ExerciseChatMessage(kind: .program, text: Constants.programIntro)
        } else {
            ExerciseChatMessage(
                kind: .assistant,
                text: Constants.replies[(replyIndex - 1) % Constants.replies.count]
            )
        }
        replyIndex += 1

        withAnimation(.brightSnappy) {
            isThinking = false
            messages.append(message)
        }
    }

    private func generate() {
        withAnimation(.brightSnappy) {
            hasGenerated = true
            isThinking = true
        }

        replyTask = Task { await confirmGenerate() }
    }

    private func confirmGenerate() async {
        do {
            try await Task.sleep(for: .seconds(Double.random(in: Constants.thinkingRange)))
        } catch {
            return
        }

        withAnimation(.brightSnappy) {
            isThinking = false
            messages.append(ExerciseChatMessage(kind: .assistant, text: Constants.generateReply))
        }
    }

    private func stopThinking() {
        replyTask?.cancel()
        replyTask = nil
        withAnimation(.brightSnappy) { isThinking = false }
    }

    private enum Constants {
        static let thinkingRange = 4.5...6.5
        static let orbSize: CGFloat = 64
        // The speed dialled in on orbs.jakubantalik.com — multiplies the orb's
        // preset rate.
        static let orbSpeed: Double = 1.2

        // The interval lines are designed to sit on one line, so they shrink
        // a touch rather than wrap.
        static let detailScale: CGFloat = 0.85

        static let programIntro = "8-Week Couch to 5K Program Schedule: 3 runs per week, "
            + "with at least 1 rest day between runs. Effort: Keep all running at an easy, "
            + "conversational pace. Walking recoveries should be relaxed."

        static let programQuestion = "Would you like to proceed with this program?"

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

        static let generateReply = "Done — I've added the plan to your weekly schedule. "
            + "You can move sessions around from the Upcoming widget whenever you need to."
    }
}

#Preview {
    ExerciseChatSheet()
}
