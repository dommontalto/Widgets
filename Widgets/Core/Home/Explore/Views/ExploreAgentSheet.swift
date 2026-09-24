//
//  ExploreAgentSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

typealias ExploreAgentMessage = ExerciseProgramChatMessage<[ExploreSearchClinic]>

// Setting up an agent: its intro over the agent's own wash, then Configure
// opens a chat with it, the way a guided program is built.
struct ExploreAgentSheet: View {
    let agent: ExploreAgent

    @FocusState private var isTyping: Bool
    @State private var isConfiguring = false
    @State private var messages = [ExploreAgentMessage]()
    @State private var isThinking = false
    @State private var replyTask: Task<Void, Never>?

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
        .onDisappear { replyTask?.cancel() }
    }

    // The artwork stays behind both steps, dimmed under the chat so its text reads.
    private var wash: some View {
        Image(agent.background)
            .resizable()
            .scaledToFill()
            // Blur feathers the image's edges, so it runs past the sheet.
            .scaleEffect(Constants.washOverscan)
            .blur(radius: Constants.washBlur)
            .overlay(Color.white.opacity(.ultraLowOpacity))
            .overlay(Color.defaultSheetBackground.opacity(isConfiguring ? .mediumOpacity : 0))
            .ignoresSafeArea()
    }

    private var intro: some View {
        VStack(spacing: .spacing2x) {
            Spacer(minLength: .spacing0x)

            mark
                .frame(width: .spacing10x, height: .spacing10x)
                .padding(.bottom, .spacing1x)

            BrightText(agent.name, size: .standout1, color: .white, weight: .regular)

            BrightText(agent.blurb, size: .body1, color: .white, weight: .regular)
                .multilineTextAlignment(.center)
                .frame(maxWidth: Constants.blurbWidth)

            Spacer(minLength: .spacing0x)

            BrightPillButton("Configure", systemImage: "hammer.fill", buttonSize: .large, isClear: true) {
                isConfiguring = true
            }
            .padding(.bottom, .spacing4x)
        }
        .blendMode(.overlay)
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
            isThinking: isThinking,
            isBusy: isThinking,
            isTyping: $isTyping,
            emptyState: ExerciseProgramChatEmptyState(title: agent.name, examples: agent.examples, tint: .textColor),
            suggestions: ExerciseProgramChatSuggestions(
                prompts: agent.suggestions.map(\.prompt),
                symbols: Dictionary(uniqueKeysWithValues: agent.suggestions.map { ($0.prompt, $0.symbol) }),
                onTap: send
            ),
            onSend: send,
            onStop: stop,
            bubbleTint: agent.tint
        ) { message in
            response(message)
        }
    }

    private func response(_ message: ExploreAgentMessage) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(message.text, size: .body1)
                .lineSpacing(.lineSpacingMedium)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(message.payload ?? []) { clinic in
                ExploreResultCard(clinic: clinic)
            }
        }
    }

    // The demo answers after a beat with the clinics that match what was asked,
    // or all of them when nothing does.
    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        messages.append(ExploreAgentMessage(kind: .user, text: trimmed))
        isThinking = true
        replyTask = Task {
            do {
                try await Task.sleep(for: .seconds(Constants.replyDelay))
            } catch {
                return
            }
            let hits = ExploreSearchClinic.results.filter { $0.matches(trimmed) }
            withAnimation(.brightSnappy) {
                isThinking = false
                messages.append(ExploreAgentMessage(
                    kind: .response,
                    text: agent.reply,
                    payload: hits.isEmpty ? ExploreSearchClinic.results : hits,
                    dismissesKeyboard: true
                ))
            }
        }
    }

    private func stop() {
        replyTask?.cancel()
        isThinking = false
    }

    private enum Constants {
        static let blurbWidth: CGFloat = 256
        static let replyDelay: TimeInterval = 1.6
        static let washBlur: CGFloat = .spacing4x
        static let washOverscan: CGFloat = 1.2
    }
}
