//
//  LighthouseChatView.swift
//  Widgets
//
//  Created by Dom Montalto on 3/9/2026.
//

import SwiftUI

typealias LighthouseChatMessage = BrightChatMessage<[LighthouseStoryItem]>

// A demo of Lighthouse as a chat: the shared thread over a frosted wash, the
// suggestion chips above the input, and canned replies after a beat.
struct LighthouseChatView: View {
    @Binding var isThinking: Bool
    @Binding var selectedModel: LighthouseModel
    @Binding var showingModelSelector: Bool
    var isTyping: FocusState<Bool>.Binding
    @Binding var attachments: [BrightChatAttachment]
    let dictation: BrightDictation
    let onDismiss: () -> Void
    let onThoughtProcess: () -> Void
    let onAttach: (BrightChatAttachmentSource) -> Void

    @State private var messages = [LighthouseChatMessage]()
    @State private var speed = LighthouseSpeed.adaptive
    @State private var customPrompts = [String]()
    @State private var replyIndex = 0
    @State private var replyTask: Task<Void, Never>?

    var body: some View {
        BrightChat(
            messages: messages,
            isThinking: isThinking,
            isBusy: isThinking,
            isTyping: isTyping,
            showsThinkingOrb: false,
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
            onThoughtTap: { _ in onThoughtProcess() },
            attachments: $attachments,
            onAttach: onAttach,
            dictation: dictation,
            response: { message in
                LighthouseChatResponse(text: message.text, items: message.payload ?? [])
            },
            modelPicker: {
                HStack(spacing: .spacing2x) {
                    modelPickerButton
                    speedMenu
                }
                .padding(.leading, .spacing1x)
            }
        )
        .overlay {
            if messages.isEmpty {
                welcome
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.brightEaseInOut, value: messages.isEmpty)
        .safeAreaInset(edge: .top, spacing: .spacing0x) {
            Color.clear.frame(height: .spacing2x)
        }
        .onDisappear { replyTask?.cancel() }
    }

    // One spacer above and three below park it a quarter of the way down, and
    // let it ride up and back as the keyboard comes and goes.
    private var welcome: some View {
        VStack(spacing: .spacing2x) {
            Spacer(minLength: .spacing0x)

            LighthouseBeacon()

            BrightText(Constants.welcome, size: .subheading, color: .semiLightTextColor)
                .multilineTextAlignment(.center)

            Spacer(minLength: .spacing0x)
            Spacer(minLength: .spacing0x)
            Spacer(minLength: .spacing0x)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, .spacing6x)
    }

    private var modelPickerButton: some View {
        Button {
            guard !isThinking else { return }
            showingModelSelector = true
        } label: {
            Image(selectedModel.tierImageName)
                .resizable()
                .scaledToFit()
                .frame(height: BrightButtonSizes.small.rawValue)
                .frame(height: BrightButtonSizes.large.rawValue)
                // The glyph is narrow, so the target reaches past it without
                // widening the gap to the pill.
                .contentShape(Rectangle().inset(by: -.spacing105x))
        }
    }

    // A Picker inside the Menu draws each speed with its glyph leading and
    // the tick trailing on the one in use.
    private var speedMenu: some View {
        Menu {
            Picker("Speed", selection: $speed) {
                ForEach(LighthouseSpeed.allCases) { speed in
                    Label {
                        Text(speed.title)
                        Text(speed.subtitle)
                    } icon: {
                        Image(systemName: speed.symbol)
                    }
                    .tag(speed)
                }
            }
        } label: {
            speedPill
        }
        .buttonStyle(.plain)
        .modifier(GlassEffect(shape: .capsule))
        .brightHaptic(.light, trigger: speed)
    }

    // The widest option sits hidden underneath so the pill keeps one width
    // as the choice changes and the glass never re-lays out.
    private var speedPill: some View {
        ZStack {
            speedLabel(Constants.widestSpeed)
                .hidden()

            speedLabel(speed)
        }
        .padding(.horizontal, .spacing105x)
        .frame(height: BrightButtonSizes.small.rawValue)
        .compositingGroup()
    }

    private func speedLabel(_ speed: LighthouseSpeed) -> some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: speed.symbol)
                .font(.standard(size: BrightButtonSizes.small.defaultFontSize, weight: .light))
                .foregroundStyle(Color.textColor)
                .contentTransition(.symbolEffect(.replace))

            BrightText(speed.title, size: BrightButtonSizes.small.defaultFontSize)
                .contentTransition(.numericText())
        }
        .animation(.brightSnappy, value: speed)
    }

    private func send(_ text: String) {
        let sent = attachments
        withAnimation(.brightSnappy) {
            messages.append(LighthouseChatMessage(kind: .user, text: text, attachments: sent))
            attachments = []
            isThinking = true
        }
        replyTask = Task { await reply() }
    }

    private func reply() async {
        let thinkingSeconds = Double.random(in: Constants.thinkingRange)
        do {
            try await Task.sleep(for: .seconds(thinkingSeconds))
        } catch {
            return
        }
        // The first answer is the demo story with its widgets; later ones are
        // plain text.
        let message: LighthouseChatMessage = if replyIndex == 0 {
            LighthouseChatMessage(
                kind: .response,
                text: LighthouseDemo.sleepPartOne,
                payload: LighthouseDemo.sleepItems,
                dismissesKeyboard: true,
                thoughtSeconds: Int(thinkingSeconds.rounded())
            )
        } else {
            LighthouseChatMessage(
                kind: .assistant,
                text: Constants.replies[(replyIndex - 1) % Constants.replies.count],
                thoughtSeconds: Int(thinkingSeconds.rounded())
            )
        }
        replyIndex += 1
        withAnimation(.brightSnappy) {
            isThinking = false
            messages.append(message)
        }
    }

    private func stopThinking() {
        replyTask?.cancel()
        replyTask = nil
        withAnimation(.brightSnappy) { isThinking = false }
    }

    private enum Constants {
        static let widestSpeed = LighthouseSpeed.adaptive
        static let welcome = "Welcome to Lighthouse. What would you like to do?"
        static let thinkingRange = 6.0...9.0
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

#Preview {
    @Previewable @State var isThinking = false
    @Previewable @State var selectedModel = LighthouseModel.chatGPT
    @Previewable @State var showingModelSelector = false
    @Previewable @FocusState var isTyping: Bool
    @Previewable @State var attachments = [BrightChatAttachment]()

    Color.defaultBackground
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            LighthouseChatView(
                isThinking: $isThinking,
                selectedModel: $selectedModel,
                showingModelSelector: $showingModelSelector,
                isTyping: $isTyping,
                attachments: $attachments,
                dictation: BrightDictation(),
                onDismiss: {},
                onThoughtProcess: {},
                onAttach: { _ in }
            )
            .background { LighthouseChatBackground() }
        }
}
