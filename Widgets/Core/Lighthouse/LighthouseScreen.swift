//
//  LighthouseScreen.swift
//  Widgets
//
//  Created by Dom Montalto on 10/9/2026.
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

// Lighthouse as a full-screen cover over the app: the onboarding on first run,
// then the chat with the side menu behind it, with the island orb while it
// thinks and the model picker in front of the lot.
// Keeping the chat out of a paging scroll view lets its bottom safe-area inset
// stay attached to the keyboard throughout its interactive dismissal.
struct LighthouseScreen: View {
    // Finishing the onboarding puts the chat in its place; the flag is stored
    // by the screen underneath, so it stays off across launches until switched
    // back on.
    @Binding var showOnboarding: Bool

    @Environment(\.dismiss) private var dismiss

    // The model picked in onboarding (or later, in the selector) survives
    // relaunches, so a returning user lands on the assistant they chose.
    @AppStorage(Constants.modelKey) private var model = LighthouseModel.chatGPT
    // Set when the API key card is chosen instead of a model: while it holds a
    // key, the key stands in for the model logo across the chat and the menu.
    @AppStorage(Constants.apiKeyKey) private var apiKey = ""
    @State private var isThinking = false
    @State private var showingModelSelector = false
    @State private var showingCheckIns = false
    @State private var showingConfigurations = false
    @State private var showingSettings = false
    // Bumped to have the chat view clear its thread in place, so the input
    // field survives and keeps the keyboard.
    @State private var chatResetCount = 0
    @State private var showingThoughtProcess = false
    // Presenting the thought process takes the keyboard with it, so this
    // remembers whether it was up to bring it straight back after.
    @State private var wasTypingBeforeThoughtProcess = false
    @State private var attachments = [BrightChatAttachment]()
    @State private var dictation = BrightDictation()
    @State private var attachmentSource: BrightChatAttachmentSource?
    @State private var pickedPhotos = [PhotosPickerItem]()
    @State private var isMenuOpen = false
    @FocusState private var isTyping: Bool

    var body: some View {
        NavigationStack {
            layers
                .background { LighthouseChatBackground() }
                .toolbar(.hidden, for: .navigationBar)
        }
        .presentationBackground(.clear)
        .animation(.brightEaseInOut, value: showOnboarding)
        .sheet(isPresented: $showingCheckIns) {
            LighthouseCheckInsSheet()
        }
        .sheet(isPresented: $showingSettings) {
            LighthouseSettingsSheet()
        }
        .sheet(isPresented: $showingConfigurations) {
            LighthouseConfigurationsSheet()
        }
        .sheet(isPresented: $showingThoughtProcess) {
            if wasTypingBeforeThoughtProcess {
                isTyping = true
            }
        } content: {
            LighthouseThoughtProcessSheet(steps: LighthouseDemo.thoughtSteps)
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
        .fullScreenCover(isPresented: $showingModelSelector) {
            LighthouseModelSelectorView(
                currentModel: model,
                onApiKeySaved: { apiKey = $0 }
            ) { model = $0; apiKey = "" }
        }
    }

    private var topButtons: some View {
        HStack(spacing: .spacing2x) {
            BrightRoundButton(systemImage: "line.3.horizontal", size: .large) {
                withAnimation(.brightSnappy) {
                    isMenuOpen.toggle()
                }
            }
            .accessibilityLabel(isMenuOpen ? "Close menu" : "Open menu")

            BrightRoundButton(systemImage: "bubble.left.and.bubble.right", size: .large, onTapCallback: startNewChat)
                .accessibilityLabel("Temporary chat")

            Spacer(minLength: .spacing0x)

            closeButton
        }
        .padding(.horizontal, .spacing3x)
    }

    private var closeButton: some View {
        BrightRoundButton(systemImage: "xmark", size: .large) { dismiss() }
            .accessibilityLabel("Close")
    }

    private var layers: some View {
        ZStack(alignment: .top) {
            if showOnboarding {
                onboarding
                    .overlay(alignment: .topTrailing) {
                        closeButton
                            .padding(.horizontal, .spacing3x)
                    }
                    .transition(.opacity)
            } else {
                pages
                    .transition(.opacity)
            }

            // Speaking to it lights the orb up too: it listens to the mic
            // and swells with your voice until the reply is being worked out.
            island
        }
    }

    // The island's grow and collapse are animated here, scoped to it, so the
    // chat's own changes keep their animations. A real container rather than
    // a Group: a Group is gone once its only child leaves, and the collapse
    // has nothing to animate on.
    private var island: some View {
        ZStack(alignment: .top) {
            if isThinking || dictation.isListening {
                BrightIslandIndicator(onTap: islandTap) {
                    BrightSolvingStars(
                        state: dictation.isListening ? .listening : .thinking,
                        audioLevel: dictation.audioLevel,
                        ambientMotion: .off
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .containerRelativeFrame(.horizontal) { width, _ in
                        width * Constants.orbWidthFraction
                    }
                } footer: {
                    LighthouseThinkingStatus(isListening: dictation.isListening)
                }
            }
        }
        .animation(.brightEaseInOut, value: isThinking)
        .animation(.brightEaseInOut, value: dictation.isListening)
    }

    private var onboarding: some View {
        LighthouseOnboardingView(
            selectedModel: $model,
            onApiKeySaved: { apiKey = $0 }
        ) {
            showOnboarding = false
        }
    }

    // The chat slides right off the menu behind it, dimming as it goes, by
    // swipe or the bar button. Opening puts the keyboard away.
    private var pages: some View {
        BrightSideMenu(isExpanded: $isMenuOpen) {
            menu
        } content: {
            chat
                .background { LighthouseChatBackground() }
                // Fixed where the bar's buttons would sit, so their glass
                // can't fold together or stretch to fit a glyph, and riding
                // on the chat page so they slide over with it.
                .overlay(alignment: .top) { topButtons }
        }
        .onChange(of: isMenuOpen) { _, isMenuOpen in
            guard isMenuOpen else { return }
            isTyping = false
        }
    }

    private var chat: some View {
        LighthouseChatView(
            isThinking: $isThinking,
            selectedModel: $model,
            usesApiKey: usesApiKey,
            showingModelSelector: $showingModelSelector,
            isTyping: $isTyping,
            attachments: $attachments,
            dictation: dictation,
            resetCount: chatResetCount,
            onDismiss: { dismiss() },
            onThoughtProcess: showThoughtProcess,
            onAttach: { attachmentSource = $0 }
        )
    }

    private var usesApiKey: Bool {
        !apiKey.isEmpty
    }

    private var menu: some View {
        LighthouseMenuView(
            model: model,
            usesApiKey: usesApiKey,
            onSwitchModel: { showingModelSelector = true },
            onCheckIns: { showingCheckIns = true },
            onConfigurations: { showingConfigurations = true },
            onSettings: { showingSettings = true },
            onNewChat: startNewChat
        )
    }

    // Tapping the island while a reply is being worked out opens the thought
    // process; while listening it stays out of the way.
    private var islandTap: (() -> Void)? {
        guard isThinking, !dictation.isListening else { return nil }
        return { showThoughtProcess() }
    }

    private func showThoughtProcess() {
        wasTypingBeforeThoughtProcess = isTyping
        showingThoughtProcess = true
    }

    private func startNewChat() {
        isThinking = false
        attachments = []
        withAnimation(.brightSnappy) {
            chatResetCount += 1
            isMenuOpen = false
        }
        // Opening the menu put the keyboard away; a fresh chat wants it back.
        isTyping = true
    }

    // MARK: - Attachments

    // One optional drives all three pickers, so only the source that was
    // picked from the "+" menu is presented.
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
            // Files from outside the sandbox are security scoped; the read has
            // to sit inside the access window.
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { continue }
            attachments.append(BrightChatAttachment(image: image))
        }
    }

    private enum Constants {
        static let maxAttachments = 4
        static let orbWidthFraction: CGFloat = 0.3
        static let modelKey = "lighthouseSelectedModel"
        static let apiKeyKey = "lighthouseApiKey"
    }
}
