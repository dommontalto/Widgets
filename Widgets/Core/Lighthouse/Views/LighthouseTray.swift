//
//  LighthouseTray.swift
//  Widgets
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

// Lighthouse as a tray that lives at the bottom of a page. At rest it's a floating bar: the model on the left, the
// ask field in the middle and dictation on the right. Pulled up, the chat fills in above the bar, and at full height
// the menu sits top left.
struct LighthouseTray: View {
    @Binding var detent: PresentationDetent
    // Kept at the foot of a sub page as the resting bar, which a swipe down returns to rather than closing.
    var hasRest = false
    var focusesOnOpen = false
    // Sent as the tray opens, such as a widget's check-in; a tray left resting is handed later ones too.
    var initialPrompt: String?
    // Shortcuts under the top row, until the first message goes.
    var quickActions: LighthouseQuickActions?
    let onClose: () -> Void

    // Just the ask bar: 12pt round its 44pt buttons.
    static let restHeight = CGFloat.spacing2x + BrightButtonSizes.large.rawValue + .spacing2x
    static let restDetent = PresentationDetent.height(restHeight)
    // Half height less the keyboard: iOS sets the tray on top of the keyboard, so its top stays where half was.
    static let typingDetent = PresentationDetent.custom(TrayTypingDetent.self)
    // The tray's "half": a little under the system's medium, so more of the page shows above it.
    nonisolated static let halfShare: CGFloat = 0.38
    static let halfDetent = PresentationDetent.fraction(halfShare)

    @AppStorage(Constants.modelKey) private var model = LighthouseModel.chatGPT
    @AppStorage(Constants.apiKeyKey) private var apiKey = ""
    @State private var draft = ""
    @State private var sentPrompt: String?
    @State private var isThinking = false
    @State private var showingModelSelector = false
    @State private var modelLogoFrame: CGRect = .zero
    @State private var modelReturns = 0
    @State private var showingCheckIns = false
    @State private var showingConfigurations = false
    @State private var showingSettings = false
    @State private var page: TrayPage? = .chat
    @State private var chatResetCount = 0
    @State private var attachments = [BrightChatAttachment]()
    @State private var attachmentSource: BrightChatAttachmentSource?
    @State private var pickedPhotos = [PhotosPickerItem]()
    @State private var dictation = BrightDictation()
    @FocusState private var isFieldFocused: Bool
    @FocusState private var isChatTyping: Bool
    // From the keyboard's own notices, so a drag up can be told apart from the keyboard closing after a send.
    @State private var isKeyboardShowing = false
    // The placeholder's own width: a centred field's ideal width alone cuts it short.
    @State private var askPromptWidth: CGFloat = 0
    @State private var sendCount = 0
    // Once a message goes, the suggestions step aside for the conversation; a new chat brings them back.
    @State private var hasConversation = false
    @State private var topBarHeight: CGFloat = .zero
    @State private var isWhispering = false

    private var isResting: Bool {
        detent == Self.restDetent
    }

    private var isFull: Bool {
        detent == .large
    }

    // While typing below full height, full is off the list: iOS would otherwise lift the tray there for the keyboard.
    private var allowedDetents: Set<PresentationDetent> {
        let detents: Set<PresentationDetent> = isFieldFocused && detent != .large
            ? [Self.restDetent, Self.halfDetent, Self.typingDetent]
            : [Self.restDetent, Self.halfDetent, .large]
        return hasRest ? detents : detents.subtracting([Self.restDetent])
    }

    private var hasDraft: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSend: Bool {
        hasDraft || !attachments.isEmpty
    }

    var body: some View {
        // The menu page sits to the left of the chat: swipe across to it, or tap the button. A paging scroll view
        // rather than a page TabView, which loses its place and falls back to the menu when the tray changes height.
        ScrollView(.horizontal) {
            HStack(spacing: .spacing0x) {
                lighthouseMenu
                    .padding(.top, .spacing2x)
                    .containerRelativeFrame(.horizontal)
                    .id(TrayPage.menu)

                trayColumn
                    .containerRelativeFrame(.horizontal)
                    .id(TrayPage.chat)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $page)
        .defaultScrollAnchor(.trailing)
        .scrollIndicators(.hidden)
        .scrollDisabled(isResting)
        // Unfocused as the swipe starts, so the keyboard slides away as it does anywhere else.
        .onScrollPhaseChange { _, phase in
            if phase == .interacting { isFieldFocused = false }
        }
        .onChange(of: isResting) { _, resting in
            if resting { page = .chat }
        }
        .onChange(of: page) { _, page in
            guard page == .menu else { return }
            isFieldFocused = false
            isChatTyping = false
        }
        .task(id: initialPrompt) {
            guard let initialPrompt else { return }
            sentPrompt = initialPrompt
            hasConversation = true
        }
        .animation(.brightSnappy, value: attachments.count)
        .presentationDetents(allowedDetents, selection: $detent)
        .interactiveDismissDisabled(hasRest)
        .animation(.brightEaseInOut, value: isResting)

        // Typing from rest or half goes straight to the keyboard-sized height, so the tray never sits at plain
        // half while the keyboard comes up under it.
        .onChange(of: isFieldFocused) { _, focused in
            guard focused, detent != .large, detent != Self.typingDetent else { return }
            withAnimation(.brightEaseInOut) { detent = Self.typingDetent }
        }
        .onChange(of: detent) { old, new in
            if new == Self.restDetent { isFieldFocused = false }
            if old == Self.restDetent, hasConversation {
                hasConversation = false
                isThinking = false
                attachments = []
                chatResetCount += 1
            }
            // Dragged up from the keyboard height while still typing: the keyboard goes and the tray carries on to
            // full, since full can't be on offer while it's up without iOS lifting the tray there itself.
            if old == Self.typingDetent, new == Self.halfDetent, isKeyboardShowing {
                isFieldFocused = false
                withAnimation(.brightEaseInOut) { detent = .large }
            }
        }
        .onAppear {
            guard focusesOnOpen else { return }
            Task {
                try? await Task.sleep(for: .seconds(Constants.focusDelay))
                isFieldFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
            guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            TrayTypingDetent.keyboardHeight = frame.height
            isKeyboardShowing = true
            guard isFieldFocused, detent != .large else { return }
            withAnimation(.brightEaseInOut) { detent = Self.typingDetent }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardShowing = false
            guard detent == Self.typingDetent else { return }
            withAnimation(.brightEaseInOut) { detent = Self.halfDetent }
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
                sourceFrame: modelLogoFrame,
                onReturned: { modelReturns += 1 },
                onApiKeySaved: { apiKey = $0 }
            ) { model = $0; apiKey = "" }
        }
    }

    private var trayColumn: some View {
        VStack(spacing: .spacing0x) {
            if !isResting {
                // The menu floats over the chat, so messages scroll on up under it rather than being cut at its edge.
                chat
                    .environment(\.brightChatShowsInput, false)
                    .environment(\.brightChatShowsBottomEdge, true)
                    .safeAreaPadding(.top, topBarHeight)
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
                    .overlay(alignment: .top) { topBar }
                    .transition(.opacity)
            }

            // Before anything is asked, a few prompts to start from, just above the ask bar.
            if !isResting, !hasConversation {
                BrightSuggestionsV5(topics: suggestionTopics, initialTopic: screenTopic) { prompt in
                    draft = prompt
                    send()
                }
                .padding(.bottom, .spacing1x)
                .transition(.opacity)
            }

            if !attachments.isEmpty, !isResting {
                attachmentStrip
                    .transition(.opacity)
            }

            askRow
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .animation(.brightEaseInOut, value: hasConversation)
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
            prompts: Constants.demoStarters,
            isFixed: true
        )
    }

    // MARK: - Ask

    // One row, the field centred between the buttons.
    private var askRow: some View {
        HStack(spacing: .spacing2x) {
            modelButton

            askField

            HStack(spacing: .spacing1x) {
                if !isResting {
                    attachMenu
                        .transition(.scale.combined(with: .opacity))
                }
                fieldAction
            }
        }
        .padding(.horizontal, .spacing2x)
        .padding(.bottom, .spacing2x)
        .padding(.top, .spacing2x)
        // At rest the whole bar is the field to tap; the buttons in it still take their own taps.
        .contentShape(.rect)
        .onTapGesture {
            if isResting { isFieldFocused = true }
        }
        .animation(.brightSnappy, value: hasDraft)
        .animation(.brightSnappy, value: dictation.isListening)
        .animation(.brightSnappy, value: isThinking)
    }

    // Centred only on the resting bar; pulled up, the prompt sits left where typing starts.
    private var isAskCentred: Bool {
        isResting && !isFieldFocused && draft.isEmpty
    }

    private var askField: some View {
        TextField("", text: $draft, prompt: Text(Constants.askTitle).foregroundStyle(Color.lightTextColor))
            .font(.standard(size: .subheading2, weight: .regular))
            .foregroundStyle(Color.textColor)
            .lineLimit(1)
            .focused($isFieldFocused)
            .submitLabel(.send)
            .onSubmit(send)
            .frame(minWidth: isAskCentred ? askPromptWidth + .spacing2x : nil)
            .fixedSize(horizontal: isAskCentred, vertical: false)
            .frame(maxWidth: .infinity, alignment: isAskCentred ? .center : .leading)
            .animation(.brightSnappy, value: isAskCentred)
            .background {
                Text(Constants.askTitle)
                    .font(.standard(size: .subheading2, weight: .regular))
                    .fixedSize()
                    .hidden()
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { askPromptWidth = $0 }
            }
            .frame(height: BrightButtonSizes.large.rawValue)
            .contentShape(.rect)
            .onTapGesture { isFieldFocused = true }
    }

    // The model's tile fills the whole circle, in its own colours, which a round button's template glyph would flatten.
    private var modelButton: some View {
        Button {
            guard !isThinking else { return }
            openModelSelector()
        } label: {
            LighthouseTrayModelLogo(model: model, glowTrigger: modelReturns)
                .opacity(showingModelSelector ? .zero : .opaque)
        }
        .buttonStyle(.plain)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { modelLogoFrame = $0 }
        .accessibilityLabel(Constants.modelLabel)
        .accessibilityValue(model.displayName)
    }

    // Dictation until there's something to send, then the send arrow; while it listens, a red wave that ripples.
    @ViewBuilder
    private var fieldAction: some View {
        if isThinking {
            BrightRoundButton(systemImage: "stop.fill", size: .large, imageColor: .defaultRed) {
                isThinking = false
            }
            .accessibilityLabel(Constants.stopLabel)
            .transition(.scale.combined(with: .opacity))
        } else if canSend, !dictation.isListening {
            // The sent bubble's own tinted glass, so the two read as the same blue.
            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: BrightButtonSizes.large.rawValue, height: BrightButtonSizes.large.rawValue)
                    .contentShape(Circle())
                    .modifier(BrightGlassEffectV5(shape: .circle, tint: .defaultSkyBlue, interactive: false))
            }
            .buttonStyle(.plain)
            .brightHapticV5(.light, trigger: sendCount)
            .accessibilityLabel(Constants.sendLabel)
            .transition(.scale.combined(with: .opacity))
        } else {
            BrightRoundButton(
                systemImage: dictation.isListening ? "waveform" : "mic.fill",
                size: .large,
                imageColor: dictation.isListening ? .defaultRed : nil
            ) {
                dictation.toggle($draft)
            }
            .symbolEffect(.variableColor.iterative, isActive: dictation.isListening)
            .brightHapticV5(.light, trigger: dictation.isListening)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // Pulled up only, so the resting bar stays two buttons.
    private var attachMenu: some View {
        Menu {
            ForEach(BrightChatAttachmentSource.allCases.filter(\.isAvailable).reversed()) { source in
                Button(source.title, systemImage: source.symbol) { attachmentSource = source }
            }
        } label: {
            // A bare glyph, as in the chat's own input, rather than a glass circle.
            Image(systemName: "plus")
                .font(.standard(size: .subheading1, weight: .regular))
                .foregroundStyle(Color.textColor)
                .frame(width: Constants.plusSize, height: Constants.plusSize)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(Constants.attachLabel)
    }

    // Pulled up only: the menu page's button top left.
    // The menu row, at full height only (at half the tray is a quick ask, swiped away
    // rather than closed), and any quick actions under it until the first message.
    // Measured, so the chat starts below whatever shows.
    private var topBar: some View {
        VStack(spacing: .spacing2x) {
            if isFull {
                menuRow
                    .transition(.opacity)
            }
            if let quickActions, !hasConversation {
                quickActions
                    .transition(.opacity)
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { topBarHeight = $0 }
        .animation(.brightEaseInOut, value: isFull)
        .animation(.brightEaseInOut, value: hasConversation)
    }

    private var menuRow: some View {
        HStack(spacing: .spacing2x) {
            BrightRoundButton(imageName: ImageNames.lighthouseMenuV5, size: .large, fontSize: .standout3) { withAnimation(.brightSnappy) { page = .menu } }
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
        .padding(.top, .spacing3x)
    }

    // MARK: - Chat

    private var chat: some View {
        LighthouseChatView(
            isThinking: $isThinking,
            selectedModel: $model,
            usesApiKey: !apiKey.isEmpty,
            showingModelSelector: $showingModelSelector,
            isTyping: $isChatTyping,
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

    // MARK: - Old menu page

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

    // Only a new chat leaves the menu page; everything else opens over it.
    private func pick(_ action: MenuAction) {
        if action == .newChat {
            withAnimation(.brightSnappy) { page = .chat }
        }
        run(action)
    }

    // The selector draws its own entrance from the logo, so the cover itself appears without sliding up.
    private func openModelSelector() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { showingModelSelector = true }
    }

    private func run(_ action: MenuAction) {
        switch action {
        case .switchModel: openModelSelector()
        case .checkIns: showingCheckIns = true
        case .configurations: showingConfigurations = true
        case .settings: showingSettings = true
        case .newChat: startNewChat()
        }
    }

    private enum TrayPage {
        case menu
        case chat
    }

    private enum MenuAction {
        case switchModel
        case checkIns
        case configurations
        case settings
        case newChat
    }

    // MARK: - Actions

    private func send() {
        guard canSend, !isThinking else { return }
        dictation.stop()
        sendCount += 1
        hasConversation = true
        sentPrompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = ""
        // The keyboard stays up, as in Messages: closing it would move the tray off the keyboard height mid-send,
        // and iOS can jump it to full on the way.
        if isResting {
            withAnimation(.brightEaseInOut) { detent = Self.halfDetent }
        }
    }

    // MARK: - Attachments

    // Waiting to go with the next message, above the bar.
    private var attachmentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacing2x) {
                ForEach(attachments) { attachment in
                    thumbnail(attachment)
                }
            }
            .padding(.horizontal, .spacing2x)
            .padding(.top, .spacing1x)
        }
        .scrollClipDisabled()
    }

    private func thumbnail(_ attachment: BrightChatAttachment) -> some View {
        Image(uiImage: attachment.image)
            .resizable()
            .scaledToFill()
            .frame(width: Constants.thumbnailSize, height: Constants.thumbnailSize)
            .clipShape(RoundedRectangle(cornerRadius: .squareCornerRadius, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Button {
                    attachments.removeAll { $0.id == attachment.id }
                } label: {
                    Image(systemName: "xmark")
                        .font(.standard(size: .body5, weight: .medium))
                        .foregroundStyle(Color.white)
                        .frame(width: Constants.removeSize, height: Constants.removeSize)
                        .background(Color.black.opacity(.lowOpacity), in: .circle)
                        .contentShape(Circle())
                }
                .padding(.spacing05x)
            }
    }

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
        isFieldFocused = true
    }

    private enum Constants {
        static let askTitle = "Ask Lighthouse anything"
        static let modelLabel = "Model"
        static let stopLabel = "Stop"
        static let sendLabel = "Send"
        static let attachLabel = "Attach"
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
        static let focusDelay: TimeInterval = 0.35
        static let plusSize: CGFloat = 28
        static let maxAttachments = 4
        static let thumbnailSize: CGFloat = .spacing10x
        static let removeSize: CGFloat = .spacing3x
        static let modelKey = "lighthouseSelectedModel"
        static let apiKeyKey = "lighthouseApiKey"
    }
}

// Half the screen less the keyboard, never shorter than the resting bar. The last keyboard's height is kept, and
// before the first one it's a typical keyboard's share of the screen.
private struct TrayTypingDetent: CustomPresentationDetent {
    nonisolated(unsafe) static var keyboardHeight: CGFloat?

    static func height(in context: Context) -> CGFloat? {
        let keyboard = keyboardHeight ?? context.maxDetentValue * Constants.keyboardShare
        return max(context.maxDetentValue * LighthouseTray.halfShare - keyboard, .spacing2x + BrightButtonSizes.large.rawValue + .spacing2x)
    }

    private enum Constants {
        static let keyboardShare: CGFloat = 0.4
    }
}

// The model's logo in the tray. It keeps its own glow, so lighting it up redraws only the logo, not the tray:
// it arrives back from the selector lit, as it left the dial, and dims after a moment.
private struct LighthouseTrayModelLogo: View {
    let model: LighthouseModel
    let glowTrigger: Int

    @State private var glow: Double = .zero

    var body: some View {
        Image(model.tierImageName)
            .resizable()
            .scaledToFill()
            .frame(width: BrightButtonSizes.large.rawValue, height: BrightButtonSizes.large.rawValue)
            .clipShape(Circle())
            .contentShape(Circle())
            .modifier(LighthouseModelGlow(color: model.tint, amount: glow))
            .onChange(of: glowTrigger) {
                glow = .opaque
                withAnimation(.easeOut(duration: Constants.glowFadeDuration).delay(Constants.glowHold)) { glow = .zero }
            }
    }

    private enum Constants {
        static let glowHold: TimeInterval = 2
        static let glowFadeDuration: TimeInterval = 1
    }
}
