//
//  LighthouseChatView.swift
//  Widgets
//
//  Created by Dom Montalto on 3/9/2026.
//

import SwiftUI

typealias LighthouseChatMessage = BrightChatMessage<Never>

// A demo of Lighthouse as a chat: the shared thread over a frosted wash, the
// suggestion chips above the input, and canned replies after a beat.
struct LighthouseChatView: View {
    @Binding var isThinking: Bool
    @Binding var selectedModel: LighthouseModel
    @Binding var showingModelSelector: Bool
    var isTyping: FocusState<Bool>.Binding
    let onDismiss: () -> Void

    @State private var messages = [LighthouseChatMessage]()
    @State private var customPrompts = [String]()
    @State private var replyIndex = 0
    @State private var replyTask: Task<Void, Never>?

    var body: some View {
        BrightChat(
            messages: messages,
            isThinking: isThinking,
            isBusy: isThinking,
            isTyping: isTyping,
            suggestions: BrightChatSuggestions(
                prompts: Constants.prompts,
                custom: customPrompts,
                onTap: send,
                onAdd: { customPrompts.append($0) },
                onDelete: { prompt in customPrompts.removeAll { $0 == prompt } }
            ),
            onSend: send,
            onStop: stopThinking,
            onSwipeDismiss: onDismiss,
            response: { _ in EmptyView() },
            modelPicker: { modelPickerButton }
        )
        .safeAreaInset(edge: .top, spacing: .spacing0x) {
            Color.clear.frame(height: .spacing9x)
        }
        .background {
            LighthouseChatBackground()
                .opacity(messages.isEmpty ? 0 : 1)
                .allowsHitTesting(!messages.isEmpty)
                .animation(.brightEaseInOut, value: messages.isEmpty)
        }
        .onDisappear { replyTask?.cancel() }
    }

    private var modelPickerButton: some View {
        Button {
            guard !isThinking else { return }
            withAnimation(.brightBouncy) { showingModelSelector = true }
        } label: {
            Image(selectedModel.tierImageName)
                .frame(height: BrightButtonSizes.large.rawValue)
                .padding(.leading, .spacing1x)
                // The glyph is narrow, so the target reaches past it without
                // widening the gap to the field.
                .contentShape(Rectangle().inset(by: -.spacing2x))
        }
    }

    private func send(_ text: String) {
        withAnimation(.brightSnappy) {
            messages.append(LighthouseChatMessage(kind: .user, text: text))
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
            messages.append(LighthouseChatMessage(kind: .assistant, text: text))
        }
    }

    private func stopThinking() {
        replyTask?.cancel()
        replyTask = nil
        withAnimation(.brightSnappy) { isThinking = false }
    }

    private enum Constants {
        static let thinkingRange = 2.5...4.0
        static let prompts = [
            "Why is my sleep bad?",
            "What should I focus on?",
            "Any trends I should know?",
        ]
        static let replies = [
            "Your deep sleep dropped to 48 minutes last night, about 30% under your monthly average. The two late meals this week line up with the worst nights.",
            "Recovery is trending up. Keep the easy cardio on rest days and hold strength volume where it is for another week before adding load.",
            "Resting heart rate has been climbing since Tuesday. That usually shows up two days before you feel run down, so an early night tonight would help.",
        ]
    }
}

struct LighthouseChatBackground: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Color(light: .clear, dark: .black.opacity(.mediumOpacity)))
            .ignoresSafeArea()
    }
}

#Preview {
    @Previewable @State var isThinking = false
    @Previewable @State var selectedModel = LighthouseModel.chatGPT
    @Previewable @State var showingModelSelector = false
    @Previewable @FocusState var isTyping: Bool

    Color.defaultBackground
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            LighthouseChatView(
                isThinking: $isThinking,
                selectedModel: $selectedModel,
                showingModelSelector: $showingModelSelector,
                isTyping: $isTyping,
                onDismiss: {}
            )
        }
}
