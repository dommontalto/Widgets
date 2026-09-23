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
    var usesApiKey = false
    @Binding var showingModelSelector: Bool
    var isTyping: FocusState<Bool>.Binding
    @Binding var attachments: [BrightChatAttachment]
    let dictation: BrightDictation
    // Each change clears the thread for a new chat.
    var resetCount = 0
    let onDismiss: () -> Void
    let onThoughtProcess: () -> Void
    let onAttach: (BrightChatAttachmentSource) -> Void

    @State private var messages = [LighthouseChatMessage]()
    @State private var speed = LighthouseSpeed.adaptive
    // The tier picked from the pill; nil falls back to the stored choice, and
    // it clears whenever the model or the selector sheet changes so the pill
    // rereads what was saved there.
    @State private var pickedTier: LighthouseModelTier?
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
            focusesOnAppear: false,
            suggestions: BrightChatSuggestions(
                prompts: Constants.quickActions,
                custom: customPrompts,
                onTap: send,
                // TODO: Decide whether to delete custom prompt creation.
//                onAdd: { customPrompts.append($0) },
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
                LighthouseChatResponse(text: message.text, items: message.payload ?? [], onSubmit: send)
            },
            modelPicker: {
                HStack(spacing: .spacing1x) {
                    modelPickerButton
                    tierMenu
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
        .onChange(of: selectedModel) { _, _ in pickedTier = nil }
        .onChange(of: showingModelSelector) { _, _ in pickedTier = nil }
        .safeAreaInset(edge: .top, spacing: .spacing0x) {
            Color.clear.frame(height: .spacing2x)
        }
        .onDisappear { replyTask?.cancel() }
        .onChange(of: resetCount) { _, _ in
            replyTask?.cancel()
            replyTask = nil
            messages = []
            replyIndex = 0
        }
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
            modelGlyph
                .frame(height: BrightButtonSizes.large.rawValue)
                // The glyph is narrow, so the target reaches past it without
                // widening the gap to the pill.
                .contentShape(Rectangle().inset(by: -.spacing105x))
        }
    }

    // The key stands in for the model logo while a bring-your-own key is in use.
    @ViewBuilder
    private var modelGlyph: some View {
        if usesApiKey {
            LighthouseApiKeyGlyph(size: BrightButtonSizes.small.rawValue)
        } else {
            Image(selectedModel.tierImageName)
                .resizable()
                .scaledToFit()
                .frame(height: BrightButtonSizes.small.rawValue)
        }
    }

    private var tier: LighthouseModelTier {
        pickedTier ?? selectedModel.selectedTier()
    }

    private var tierBinding: Binding<LighthouseModelTier> {
        Binding(
            get: { tier },
            set: { picked in
                pickedTier = picked
                selectedModel.saveTier(picked)
            }
        )
    }

    // The current model's tiers, ticked on the one in use, in a pill cut like
    // the speed one beside it.
    private var tierMenu: some View {
        Menu {
            Picker("Tier", selection: tierBinding) {
                ForEach(selectedModel.tiers) { tier in
                    Label {
                        Text(tier.name)
                        Text(tier.label)
                    } icon: {
                        EmptyView()
                    }
                    .tag(tier)
                }
            }
        } label: {
            tierPill
        }
        .buttonStyle(.plain)
        .modifier(GlassEffect(shape: .capsule))
        .brightHaptic(.light, trigger: tier)
    }

    // Sized to the name in use, so the pill grows and shrinks with the tier.
    private var tierPill: some View {
        tierLabel(tier)
            .padding(.horizontal, .spacing105x)
            .frame(height: BrightButtonSizes.small.rawValue)
            .compositingGroup()
    }

    private func tierLabel(_ tier: LighthouseModelTier) -> some View {
        BrightText(tier.name, size: BrightButtonSizes.small.defaultFontSize)
            .monospacedDigit()
            .fixedSize()
            .animation(.brightSnappy, value: tier)
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

    private var speedPill: some View {
        speedLabel(speed)
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
        }
        // The menu hands its label a stale width for a beat after a pick, and
        // a squeezed label truncates; sizing to the text keeps every glyph.
        .fixedSize()
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
        static let quickActions = [
            BrightChatExample("bell.badge.waveform", "Create alerts"),
            BrightChatExample("person.fill.checkmark.and.xmark", "Create checkin"),
            BrightChatExample("figure.indoor.cycle", "Create workout program"),
            BrightChatExample(
                "chevron.compact.up.chevron.compact.right.chevron.compact.down.chevron.compact.left",
                "Create waypoint"
            ),
            BrightChatExample("graph.3d", "Trend analysis"),
            BrightChatExample("graph.2d", "Forecast metrics"),
            BrightChatExample("fork.knife", "Log food"),
        ]
        static let welcome = "Welcome to Lighthouse. What would you like to do?"
        static let thinkingRange = 6.0...9.0
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
