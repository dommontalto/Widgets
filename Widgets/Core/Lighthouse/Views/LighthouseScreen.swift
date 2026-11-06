//
//  LighthouseScreen.swift
//  Widgets
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

// Lighthouse, shown full screen from the dock: the chat with its own input, and the menu behind it top left.
struct LighthouseScreen: View {
    // Sent as Lighthouse opens, such as a widget's check-in.
    var initialPrompt: String?
    let onClose: () -> Void

    @AppStorage(Constants.modelKey) private var model = LighthouseModel.chatGPT
    @AppStorage(Constants.apiKeyKey) private var apiKey = ""
    @State private var sentPrompt: String?
    @State private var isThinking = false
    @State private var showingModelSelector = false
    @State private var showingCheckIns = false
    @State private var showingConfigurations = false
    @State private var showingSettings = false
    @State private var isMenuOpen = false
    @State private var chatResetCount = 0
    @State private var attachments = [BrightChatAttachment]()
    @State private var attachmentSource: BrightChatAttachmentSource?
    @State private var pickedPhotos = [PhotosPickerItem]()
    @State private var dictation = BrightDictation()
    @FocusState private var isTyping: Bool
    // Once a message goes, the Suggested menu stops opening itself; a new chat brings it back.
    @State private var hasConversation = false
    @State private var isWhispering = false

    var body: some View {
        // The chat slides right off the menu behind it. Keeping the chat out of a paging scroll view lets its
        // bottom safe-area inset stay attached to the keyboard throughout its interactive dismissal.
        NavigationStack {
            BrightSideMenuV5(isExpanded: $isMenuOpen) {
                lighthouseMenu
                    .background { veil }
            } content: {
                chatPage
                    .background { veil }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onChange(of: isMenuOpen) { _, isMenuOpen in
            guard isMenuOpen else { return }
            isTyping = false
        }
        .onChange(of: isThinking) { _, thinking in
            if thinking { hasConversation = true }
        }
        .task(id: initialPrompt) {
            guard let initialPrompt else { return }
            sentPrompt = initialPrompt
            hasConversation = true
        }
        .sheet(isPresented: $showingCheckIns) {
            LighthouseCheckInsSheet()
        }
        .photosPicker(
            isPresented: attaching(.photos),
            selection: $pickedPhotos,
            maxSelectionCount: Constants.maxAttachments,
            matching: .images
        )
        .onChange(of: pickedPhotos) { _, items in
            guard !items.isEmpty else { return }
            pickedPhotos = []
            Task { await attach(items) }
        }
        .fullScreenCover(isPresented: attaching(.camera)) {
            BrightCameraPicker { image in
                attachments.append(BrightChatAttachment(image: image))
            }
            .ignoresSafeArea()
        }
        .fileImporter(
            isPresented: attaching(.files),
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            attach(try? result.get())
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

    // The Suggested pills sit in the chat's own input card, above the field.
    private var chatPage: some View {
        chat
            .environment(\.brightChatTopics, BrightChatTopics(
                topics: suggestionTopics,
                opensOnAppear: hasConversation ? nil : screenTopic.id,
                onSelect: { prompt in
                    hasConversation = true
                    sentPrompt = prompt
                }
            ))
            .modifier(LighthouseTopBar { menuRow })
            .brightSoftScrollEdgesV5()
            .overlay {
                if isWhispering, !hasConversation {
                    BrightPlaceholderViewV5(
                        image: ImageNames.lighthouseWhisperV5,
                        title: Constants.whisperTitle,
                        subtitle: Constants.whisperSubtitle,
                        fillsViewport: false
                    )
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
            .animation(.brightEaseInOut, value: isWhispering)
    }

    // The screen's starter questions lead, ahead of the general topics. Demo questions here; the app takes the
    // current screen's from the server.
    private var suggestionTopics: [BrightSuggestionTopic] {
        [screenTopic] + BrightSuggestionsDemo.topics
    }

    private var screenTopic: BrightSuggestionTopic {
        BrightSuggestionTopic(
            title: Constants.suggestedTitle,
            systemImage: "sparkles",
            prompts: Constants.demoStarters
        )
    }

    private var veil: some View {
        Color.defaultBackground
            .ignoresSafeArea()
    }

    private var menuRow: some View {
        HStack(spacing: .spacing2x) {
            BrightRoundButton(imageName: ImageNames.lighthouseMenuV5, size: .large, fontSize: .standout3) { withAnimation(.brightSnappy) { isMenuOpen = true } }
                .accessibilityLabel(Constants.menuLabel)

            BrightRoundButton(
                imageName: ImageNames.lighthouseWhisperV5,
                size: .large,
                fontSize: .huge,
                color: isWhispering ? .defaultSkyBlue : nil,
                imageColor: isWhispering ? .white : nil,
                onTapCallback: toggleWhisper
            )
            .accessibilityLabel(Constants.whisperTitle)
            .accessibilityAddTraits(isWhispering ? .isSelected : [])

            Spacer(minLength: .spacing0x)

            BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)
                .accessibilityLabel(Constants.closeLabel)
        }
        .padding(.horizontal, .spacing3x)
    }

    // MARK: - Chat

    private var chat: some View {
        LighthouseChatView(
            isThinking: $isThinking,
            selectedModel: $model,
            usesApiKey: !apiKey.isEmpty,
            showingModelSelector: $showingModelSelector,
            isTyping: $isTyping,
            attachments: $attachments,
            dictation: dictation,
            resetCount: chatResetCount,
            action: nil,
            onDismiss: onClose,
            onAttach: { attachmentSource = $0 },
            externalPrompt: $sentPrompt,
            showsWelcome: false,
            isWhispering: isWhispering
        )
    }

    // MARK: - Menu

    private var lighthouseMenu: some View {
        LighthouseMenuView(
            model: model,
            usesApiKey: !apiKey.isEmpty,
            onSwitchModel: { pick(.switchModel) },
            onCheckIns: { pick(.checkIns) },
            onConfigurations: { pick(.configurations) },
            onSettings: { pick(.settings) },
            onNewChat: { pick(.newChat) }
        )
    }

    // Only a new chat leaves the menu; everything else opens over it.
    private func pick(_ action: MenuAction) {
        if action == .newChat {
            withAnimation(.brightSnappy) { isMenuOpen = false }
        }
        run(action)
    }

    private func run(_ action: MenuAction) {
        switch action {
        case .switchModel: showingModelSelector = true
        case .checkIns: showingCheckIns = true
        case .configurations: showingConfigurations = true
        case .settings: showingSettings = true
        case .newChat: startNewChat()
        }
    }

    private enum MenuAction {
        case switchModel
        case checkIns
        case configurations
        case settings
        case newChat
    }

    // MARK: - Attachments

    // One optional drives all three pickers, so only the source picked from the plus is presented.
    private func attaching(_ source: BrightChatAttachmentSource) -> Binding<Bool> {
        Binding(
            get: { attachmentSource == source },
            set: { if !$0, attachmentSource == source { attachmentSource = nil } }
        )
    }

    private func attach(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { continue }
            attachments.append(BrightChatAttachment(image: image))
        }
    }

    private func attach(_ urls: [URL]?) {
        for url in urls ?? [] {
            // Files from outside the sandbox are security scoped; the read has to sit inside the access window.
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }
            guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { continue }
            attachments.append(BrightChatAttachment(image: image))
        }
    }

    // A whisper is a session of its own, so switching either way starts a fresh chat.
    private func toggleWhisper() {
        withAnimation(.brightSnappy) { isWhispering.toggle() }
        hasConversation = false
        isThinking = false
        attachments = []
        chatResetCount += 1
    }

    private func startNewChat() {
        hasConversation = false
        isThinking = false
        attachments = []
        chatResetCount += 1
    }

    private enum Constants {
        static let menuLabel = "Lighthouse menu"
        static let closeLabel = "Close"
        static let suggestedTitle = "Suggested"
        static let demoStarters = [
            "How did I sleep last night?",
            "What should I focus on today?",
            "Am I recovered enough to train?",
        ]
        static let whisperTitle = "Whisper mode"
        static let whisperSubtitle = "This session will disappear after 1 hour.\nYou can ask discreet questions here."
        static let maxAttachments = 4
        static let modelKey = "lighthouseSelectedModel"
        static let apiKeyKey = "lighthouseApiKey"
    }
}

// Fixed where the bar's buttons would sit, so their glass can't fold together or stretch to fit a glyph.
private struct LighthouseTopBar<Bar: View>: ViewModifier {
    @ViewBuilder let bar: Bar

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: .top, spacing: .spacing0x) { bar }
        } else {
            content.overlay(alignment: .top) { bar }
        }
    }
}
