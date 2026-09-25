//
//  ExploreAgentSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

typealias ExploreAgentMessage = ExerciseProgramChatMessage<ExploreAgentReply>

// Setting up an agent: its intro over the agent's own wash, then Configure
// opens a chat with it, the way a guided program is built.
struct ExploreAgentSheet: View {
    let agent: ExploreAgent

    @FocusState private var isTyping: Bool
    @State private var isConfiguring = false
    @State private var messages = [ExploreAgentMessage]()
    @State private var creatingCall: UUID?
    @State private var finishedCalls = Set<UUID>()

    var body: some View {
        BrightPageSheetView(
            horizontalPadding: .spacing0x,
            trailing: {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(file: #file)
                }
            },
            content: {
                ZStack {
                    if isConfiguring {
                        chat
                            .transition(.opacity)
                    } else {
                        intro
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // A background, so the filled, overscanned artwork can't widen the layout.
                .background { wash }
                .animation(.brightEaseInOut, value: isConfiguring)
            }
        )
    }

    // The artwork stays behind both steps, dimmed under the chat so its text reads.
    private var wash: some View {
        BrightRipple(size: 2.26, caustic: 0.18, waves: 0.21, layering: 0.15, edges: 0.36, highlights: 0.35) {
            Image(agent.background)
                .resizable()
                .scaledToFill()
                .blur(radius: Constants.washBlur)
        }
            // Zoomed after the ripple, so its warped edges and the blur's feathering fall past the sheet.
            .scaleEffect(Constants.washOverscan)
            .overlay(Color.white.opacity(.ultraLowOpacity))
            .overlay(Color.defaultSheetBackground.opacity(isConfiguring ? .mediumOpacity : 0))
            .ignoresSafeArea()
    }

    private var intro: some View {
        VStack(spacing: .spacing2x) {
            Spacer(minLength: .spacing0x)

            VStack(spacing: .spacing2x) {
                mark
                    .frame(width: .spacing10x, height: .spacing10x)
                    .padding(.bottom, .spacing1x)

                BrightText(agent.name, size: .standout1, color: .white, weight: .regular)

                BrightText(agent.blurb, size: .body1, color: .white, weight: .regular)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: Constants.blurbWidth)
            }
            .blendMode(.overlay)

            Spacer(minLength: .spacing0x)

            BrightPillButton("Configure", systemImage: "hammer.fill", buttonSize: .large) {
                isConfiguring = true
            }
            .padding(.bottom, .spacing4x)
        }
        .padding(.horizontal, .spacing3x)
    }

    @ViewBuilder
    private var mark: some View {
        switch agent.mark {
        case let .asset(name):
            Image(name)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
        case let .symbol(name):
            Image(systemName: name)
                .font(.system(size: .spacing8x, weight: .regular))
                .foregroundStyle(.white)
        }
    }

    private var chat: some View {
        ExerciseProgramChat(
            messages: messages,
            isThinking: false,
            isBusy: creatingCall != nil,
            isTyping: $isTyping,
            emptyState: ExerciseProgramChatEmptyState(title: agent.name, examples: agent.examples, tint: agent.tint),
            suggestions: ExerciseProgramChatSuggestions(
                prompts: agent.suggestions.map(\.prompt),
                symbols: Dictionary(uniqueKeysWithValues: agent.suggestions.map { ($0.prompt, $0.symbol) }),
                onTap: send
            ),
            onSend: send,
            onStop: stop,
            bubbleTint: agent.tint,
            sendTint: agent.tint,
            placeholder: "What would you like this agent to do?"
        ) { message in
            response(message)
        }
    }

    private func response(_ message: ExploreAgentMessage) -> some View {
        let isFinished = finishedCalls.contains(message.id)
        return VStack(alignment: .leading, spacing: .spacing3x) {
            if let reply = message.payload {
                ExploreAgentCallCard(agent: agent, query: reply.query, isFinished: isFinished) {
                    finish(message.id)
                }

                if isFinished {
                    VStack(alignment: .leading, spacing: .spacing2x) {
                        BrightText(message.text, size: .body1)
                            .lineSpacing(.lineSpacingMedium)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(reply.clinics) { clinic in
                            ExploreResultCard(clinic: clinic, chipTint: agent.tint, chipFill: agent.tint.opacity(.ultraLowOpacity))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .animation(.brightSnappy, value: isFinished)
    }

    private func finish(_ id: UUID) {
        finishedCalls.insert(id)
        if creatingCall == id {
            creatingCall = nil
        }
    }

    // The demo creates the agent straight away, then shows the clinics that
    // match what was asked, or all of them when nothing does.
    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, creatingCall == nil else { return }
        let hits = ExploreSearchClinic.results.filter { $0.matches(trimmed) }
        let reply = ExploreAgentMessage(
            kind: .response,
            text: agent.reply,
            payload: ExploreAgentReply(query: trimmed, clinics: hits.isEmpty ? ExploreSearchClinic.results : hits),
            dismissesKeyboard: true
        )
        messages.append(ExploreAgentMessage(kind: .user, text: trimmed))
        withAnimation(.brightSnappy) {
            creatingCall = reply.id
            messages.append(reply)
        }
    }

    private func stop() {
        if let creatingCall {
            finish(creatingCall)
        }
    }

    private enum Constants {
        static let blurbWidth: CGFloat = 256
        static let washBlur: CGFloat = .spacing4x
        static let washOverscan: CGFloat = 1.35
    }
}
