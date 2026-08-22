//
//  ExerciseChatSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 21/8/2026.
//

// DONT PORT THIS FILE TO IOS YET

import SwiftUI

nonisolated struct ExerciseChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// A demo chat with the AI coach: what you type lands as an iMessage-style
// bubble, the assistant "thinks" for a beat, then a canned reply slides in.
struct ExerciseChatSheet: View {
    @State private var messages = [ExerciseChatMessage]()
    @State private var draft = ""
    @State private var isThinking = false
    @State private var replyIndex = 0
    @State private var replyTask: Task<Void, Never>?
    @State private var draftNudge = 0

    @FocusState private var isTyping: Bool

    var body: some View {
        BrightPageSheetView(
            // The wash has to run edge to edge, so the sheet's own padding is
            // turned off and the thread and input bar pad themselves.
            horizontalPadding: .spacing0x,
            showBackButton: true,
            trailing: {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(file: #file)
                }
            },
            content: {
                thread
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background { ExerciseProgrammeBackground() }
                    .safeAreaInset(edge: .bottom, spacing: .spacing2x) {
                        inputBar
                    }
            }
        )
        .brightHaptic(.light, trigger: messages.count)
        .onDisappear { replyTask?.cancel() }
    }

    // MARK: - Thread

    private var thread: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: .spacing2x) {
                ForEach(messages) { message in
                    bubble(for: message)
                }

                if isThinking {
                    thinkingIndicator
                }
            }
            .padding(.horizontal, .spacing3x)
            .padding(.top, .spacing2x)
        }
        .defaultScrollAnchor(.bottom)
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
    }

    private func bubble(for message: ExerciseChatMessage) -> some View {
        HStack(spacing: .spacing0x) {
            if message.isUser {
                Spacer(minLength: .spacing8x)
            }

            BrightText(message.text, size: .body3)
                .lineSpacing(.lineSpacingMedium)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, .spacing3x)
                .padding(.vertical, .spacing2x)
                .modifier(GlassEffect(
                    shape: .cornerRadii(bubbleCorners(isUser: message.isUser)),
                    tint: message.isUser
                        ? .defaultSheetModalCards
                        : .defaultWhite.opacity(.veryMinimalOpacity),
                    isClear: !message.isUser,
                    interactive: false
                ))
                .shadow(color: .black.opacity(.ultraLowOpacity), radius: 15)

            if !message.isUser {
                Spacer(minLength: .spacing8x)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // The corner nearest the sender squares off into a tail, like iMessage.
    private func bubbleCorners(isUser: Bool) -> RectangleCornerRadii {
        RectangleCornerRadii(
            topLeading: isUser ? .cardCornerRadius : .cornerRadius18,
            bottomLeading: .cardCornerRadius,
            bottomTrailing: .cardCornerRadius,
            topTrailing: isUser ? .cornerRadius18 : .cardCornerRadius
        )
    }

    private var thinkingIndicator: some View {
        BrightSolvingOrb(size: Constants.orbSize, speed: Constants.orbSpeed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity)
    }

    // MARK: - Input

    private var inputBar: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            TextField("", text: $draft, axis: .vertical)
                .focused($isTyping)
                .font(.standard(size: .body2, weight: .light))
                .foregroundStyle(Color.textColor)
                .lineLimit(1...4)
                .brightWiggle(trigger: draftNudge)
                .overlay(alignment: .leading) {
                    if draft.isEmpty {
                        BrightText(
                            "What would you like us to do?",
                            size: .body2,
                            color: .textColor.opacity(.semiLowOpacity)
                        )
                        .allowsHitTesting(false)
                    }
                }

            HStack(spacing: .spacing0x) {
                Spacer(minLength: .spacing0x)

                BrightRoundButton(
                    systemImage: isThinking ? "stop.fill" : "arrow.up",
                    size: .large,
                    imageColor: .defaultSkyBlue
                ) {
                    if isThinking {
                        stopThinking()
                    } else {
                        send()
                    }
                }
            }
        }
        .padding(.spacing3x)
        .background(
            Color.defaultWhite.opacity(.veryMinimalOpacity),
            in: RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(.ultraLowOpacity), radius: 15)
        .padding(.horizontal, .spacing3x)
    }

    // MARK: - Fake replies

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            draftNudge += 1
            return
        }

        draft = ""
        withAnimation(.brightSnappy) {
            messages.append(ExerciseChatMessage(text: text, isUser: true))
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

        let text = Constants.replies[replyIndex % Constants.replies.count]
        replyIndex += 1

        withAnimation(.brightSnappy) {
            isThinking = false
            messages.append(ExerciseChatMessage(text: text, isUser: false))
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

        static let replies = [
            "Here's an 8-week couch-to-5K. Three run-walk sessions a week, building from 60-second jogs to a full 5K, plus two short strength days for your calves, tibialis and glutes to keep shin splints away and your knees strong.",
            "Week 1: run 1 minute, walk 90 seconds, repeat 8 times. The strength days are 20 minutes — calf raises, step-downs, glute bridges and side planks.",
            "I've spaced the runs with a rest day between each. If your shins flare up, repeat the previous week and keep the strength work going.",
            "Done — I've added the plan to your weekly schedule. You can move sessions around from the Upcoming widget whenever you need to.",
        ]
    }
}

#Preview {
    ExerciseChatSheet()
}
