//
//  LighthouseTrayGuidedTesting.swift
//  Widgets
//

import SwiftUI

// Lighthouse as a tray that lives at the bottom of a page, the way Maps keeps its search: the ask field and menu
// sit on top, and the chat fills in beneath once the tray is pulled up.
struct LighthouseTrayGuidedTesting: View {
    @Binding var detent: PresentationDetent

    static let restDetent = PresentationDetent.height(CGFloat.spacing12x + .spacing4x)

    @AppStorage(Constants.modelKey) private var model = LighthouseModel.chatGPT
    @AppStorage(Constants.apiKeyKey) private var apiKey = ""
    @State private var draft = ""
    @State private var sentPrompt: String?
    @State private var isThinking = false
    @State private var showingModelSelector = false
    @State private var showingCheckIns = false
    @State private var showingConfigurations = false
    @State private var showingSettings = false
    @State private var chatResetCount = 0
    @State private var attachments = [BrightChatAttachment]()
    @State private var dictation = BrightDictation()
    @FocusState private var isFieldFocused: Bool
    @FocusState private var isChatTyping: Bool

    private var isResting: Bool {
        detent == Self.restDetent
    }

    private var hasDraft: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: .spacing0x) {
            askRow

            if !isResting {
                chat
                    .environment(\.brightChatShowsInput, false)
                    .transition(.opacity)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .animation(.brightEaseInOut, value: isResting)
        // Typing goes straight to full height: a half-height tray would be shoved up by the keyboard and bounce.
        .onChange(of: isFieldFocused) { _, focused in
            guard focused, detent != .large else { return }
            withAnimation(.brightEaseInOut) { detent = .large }
        }
        .onChange(of: detent) { _, detent in
            if detent == Self.restDetent { isFieldFocused = false }
        }
        .sheet(isPresented: $showingCheckIns) {
            LighthouseCheckInsSheet()
        }
        .sheet(isPresented: $showingSettings) {
            LighthouseSettingsSheet()
        }
        .sheet(isPresented: $showingConfigurations) {
            LighthouseConfigurationsSheet()
        }
        .fullScreenCover(isPresented: $showingModelSelector) {
            LighthouseModelSelectorView(
                currentModel: model,
                onApiKeySaved: { apiKey = $0 }
            ) { model = $0; apiKey = "" }
        }
    }

    // MARK: - Ask

    private var askRow: some View {
        HStack(spacing: .spacing2x) {
            askField
            menu
        }
        .padding(.horizontal, .spacing3x)
        .padding(.top, .spacing3x)
        .padding(.bottom, .spacing1x)
    }

    private var askField: some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: "sparkles")
                .font(.standard(size: .subheading2, weight: .regular))
                .foregroundStyle(Color.semiLightTextColor)

            TextField("", text: $draft, prompt: Text(Constants.askTitle).foregroundStyle(Color.lightTextColor))
                .font(.standard(size: .subheading2, weight: .light))
                .foregroundStyle(Color.textColor)
                .focused($isFieldFocused)
                .submitLabel(.send)
                .onSubmit(send)

            fieldAction
        }
        .padding(.leading, .spacing2x)
        .padding(.trailing, .spacing05x)
        .frame(height: BrightButtonSizes.large.rawValue)
        .contentShape(.capsule)
        .onTapGesture { isFieldFocused = true }
        .modifier(BrightGlassEffectV5(shape: .capsule))
        .animation(.brightSnappy, value: hasDraft)
    }

    // The mic until there's something to send, then the send arrow.
    @ViewBuilder
    private var fieldAction: some View {
        if hasDraft {
            BrightRoundButton(systemImage: "arrow.up", size: .medium, color: .defaultGreen, tinted: true, onTapCallback: send)
                .transition(.scale.combined(with: .opacity))
        } else {
            BrightRoundButton(systemImage: dictation.isListening ? "waveform" : "mic.fill", size: .medium) {
                dictation.toggle($draft)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Chat

    private var chat: some View {
        LighthouseChatViewGuidedTesting(
            isThinking: $isThinking,
            selectedModel: $model,
            usesApiKey: !apiKey.isEmpty,
            showingModelSelector: $showingModelSelector,
            isTyping: $isChatTyping,
            attachments: $attachments,
            dictation: dictation,
            resetCount: chatResetCount,
            action: nil,
            onDismiss: { detent = Self.restDetent },
            onAttach: { _ in },
            externalPrompt: $sentPrompt
        )
    }

    // MARK: - Menu

    private var menu: some View {
        Menu {
            Button("New Chat", systemImage: "square.and.pencil", action: startNewChat)
            Button("Switch Model", systemImage: "cpu") { showingModelSelector = true }
            Divider()
            Button("Check-Ins", systemImage: "person.badge.clock") { showingCheckIns = true }
            Button("Configurations", systemImage: "slider.horizontal.3") { showingConfigurations = true }
            Button("Settings", systemImage: "gearshape") { showingSettings = true }
        } label: {
            BrightRoundButton(systemImage: "line.3.horizontal", size: .large)
                .allowsHitTesting(false)
        }
        .accessibilityLabel("Lighthouse menu")
    }

    // MARK: - Actions

    private func send() {
        guard hasDraft else { return }
        dictation.stop()
        sentPrompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = ""
        isFieldFocused = false
        if detent != .large {
            withAnimation(.brightEaseInOut) { detent = .large }
        }
    }

    private func startNewChat() {
        isThinking = false
        attachments = []
        chatResetCount += 1
        isFieldFocused = true
    }

    private enum Constants {
        static let askTitle = "Ask Lighthouse"
        static let modelKey = "lighthouseSelectedModel"
        static let apiKeyKey = "lighthouseApiKey"
    }
}
