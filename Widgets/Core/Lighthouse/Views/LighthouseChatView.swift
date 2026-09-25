//
//  LighthouseChatView.swift
//  Widgets
//
//  Created by Dom Montalto on 3/9/2026.
//

import SwiftUI

typealias LighthouseChatMessage = BrightChatMessage<LighthouseResponsePayload>

enum LighthouseAction {
    case createCheckIn

    var prompt: String {
        switch self {
        case .createCheckIn: "Create checkin"
        }
    }
}

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
    var action: LighthouseAction?
    let onDismiss: () -> Void
    let onAttach: (BrightChatAttachmentSource) -> Void
    // The welcome beacon's centre in global coordinates, for the opening burst.
    var onBeaconCentre: (CGPoint) -> Void = { _ in }

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
            attachments: $attachments,
            onAttach: onAttach,
            dictation: dictation,
            response: { message in
                if let payload = message.payload, payload.isThoughtProcess {
                    LighthouseThinkingInline(steps: LighthouseDemo.thoughtSteps, thoughtSeconds: payload.thoughtSeconds)
                } else {
                    LighthouseChatResponse(text: message.text, items: message.payload?.items ?? [], checkIn: message.payload?.checkIn, date: message.date, onSubmit: send)
                }
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
        .task { run(action) }
        .onChange(of: resetCount) { _, _ in
            replyTask?.cancel()
            replyTask = nil
            messages = []
            replyIndex = 0
            isThinking = false
        }
    }

    // One spacer above and three below park it a quarter of the way down, and
    // let it ride up and back as the keyboard comes and goes.
    private var welcome: some View {
        VStack(spacing: .spacing2x) {
            Spacer(minLength: .spacing0x)

            LighthouseBeacon(isLit: true)
                .onGeometryChange(for: CGPoint.self) { proxy in
                    let frame = proxy.frame(in: .global)
                    return CGPoint(x: frame.midX, y: frame.midY)
                } action: { onBeaconCentre($0) }

            VStack(spacing: .spacing1x) {
                BrightText(Constants.welcomeTitle, size: .standout3)
                    .brightTextReveal()

                BrightText(Constants.welcomePrompt, size: .subheading, color: .semiLightTextColor)
                    .brightTextReveal(delay: Constants.welcomePromptDelay)
            }
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
        let isCheckIn = text.trimmingCharacters(in: .whitespacesAndNewlines) == LighthouseAction.createCheckIn.prompt
        replyTask = Task {
            if isCheckIn {
                await replyToCheckIn()
            } else {
                await reply()
            }
        }
    }

    private func reply() async {
        let thinkingSeconds = Constants.thinkingSeconds
        guard await think(for: thinkingSeconds) else { return }
        // The first answer is the demo story with its widgets; later ones are
        // plain text.
        let message: LighthouseChatMessage = if replyIndex == 0 {
            LighthouseChatMessage(
                kind: .response,
                text: LighthouseDemo.sleepPartOne,
                payload: LighthouseResponsePayload(items: LighthouseDemo.sleepItems)
            )
        } else {
            LighthouseChatMessage(
                kind: .assistant,
                text: LighthouseDemo.replies[(replyIndex - 1) % LighthouseDemo.replies.count]
            )
        }
        replyIndex += 1
        withAnimation(.brightSnappy) {
            isThinking = false
            finishThinking(after: thinkingSeconds)
            messages.append(message)
        }
    }

    // The thinking row lands a beat after the sent message, so the send
    // flight still sees the user's bubble as the newest arrival.
    private func think(for seconds: TimeInterval) async -> Bool {
        do {
            try await Task.sleep(for: .seconds(Constants.thinkingDelay))
            withAnimation(.brightSnappy) {
                messages.append(LighthouseChatMessage(kind: .response, text: "", payload: LighthouseResponsePayload(isThoughtProcess: true)))
            }
            try await Task.sleep(for: .seconds(seconds - Constants.thinkingDelay))
            return true
        } catch {
            return false
        }
    }

    private func finishThinking(after seconds: TimeInterval) {
        guard let index = messages.lastIndex(where: isStillThinking) else { return }
        messages[index].payload?.thoughtSeconds = Int(seconds.rounded())
    }

    private func removeThinking() {
        messages.removeAll(where: isStillThinking)
    }

    private func isStillThinking(_ message: LighthouseChatMessage) -> Bool {
        guard let payload = message.payload else { return false }
        return payload.isThoughtProcess && payload.thoughtSeconds == nil
    }

    private func run(_ action: LighthouseAction?) {
        guard let action, messages.isEmpty else { return }
        send(action.prompt)
    }

    private func replyToCheckIn() async {
        let thinkingSeconds = Constants.thinkingSeconds
        guard await think(for: thinkingSeconds) else { return }
        let review = LighthouseDemo.weeklyClimbingReview
        withAnimation(.brightSnappy) {
            isThinking = false
            finishThinking(after: thinkingSeconds)
            messages.append(LighthouseChatMessage(
                kind: .response,
                text: review.title,
                payload: LighthouseResponsePayload(checkIn: review)
            ))
        }
    }

    private func stopThinking() {
        replyTask?.cancel()
        replyTask = nil
        withAnimation(.brightSnappy) {
            isThinking = false
            removeThinking()
        }
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
        static let welcomeTitle = "Welcome to Lighthouse."
        static let welcomePrompt = "What would you like to do?"
        static let welcomePromptDelay: TimeInterval = 0.5
        static let thinkingSeconds: TimeInterval = 10
        static let thinkingDelay: TimeInterval = 0.4
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
                onAttach: { _ in }
            )
            .background { LighthouseChatBackground() }
        }
}
