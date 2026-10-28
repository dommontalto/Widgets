//
//  LighthouseTrayGuidedTesting.swift
//  Widgets
//

import SwiftUI

// Lighthouse as a tray that lives at the bottom of a page. At rest it's a floating bar: the model on the left, the
// ask field in the middle and dictation on the right. Pulled up, the chat fills in above the bar, and at full height
// the menu sits top left.
struct LighthouseTrayGuidedTesting: View {
    @Binding var detent: PresentationDetent

    // Just the ask bar: 12pt round its 44pt buttons.
    static let restHeight = CGFloat.spacing2x + BrightButtonSizes.large.rawValue + .spacing2x
    static let restDetent = PresentationDetent.height(restHeight)
    // Half height less the keyboard: iOS sets the tray on top of the keyboard, so its top stays where half was.
    static let typingDetent = PresentationDetent.custom(TrayTypingDetent.self)

    @AppStorage(Constants.modelKey) private var model = LighthouseModel.chatGPT
    @AppStorage(Constants.apiKeyKey) private var apiKey = ""
    @State private var draft = ""
    @State private var sentPrompt: String?
    @State private var isThinking = false
    @State private var showingModelSelector = false
    @State private var showingCheckIns = false
    @State private var showingConfigurations = false
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var chatResetCount = 0
    @State private var attachments = [BrightChatAttachment]()
    @State private var dictation = BrightDictation()
    @FocusState private var isFieldFocused: Bool
    @Namespace private var barNamespace
    // The field moves rows as the tray leaves rest, which drops focus, so it's taken again once it lands.
    @State private var refocusAfterMove = false
    @FocusState private var isChatTyping: Bool

    private var isResting: Bool {
        detent == Self.restDetent
    }

    // While typing below full height, full is off the list: iOS would otherwise lift the tray there for the keyboard.
    private var allowedDetents: Set<PresentationDetent> {
        isFieldFocused && detent != .large
            ? [Self.restDetent, .medium, Self.typingDetent]
            : [Self.restDetent, .medium, .large]
    }

    private var hasDraft: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: .spacing0x) {
            if !isResting {
                menuRow
                    .transition(.opacity)
            }

            if !isResting {
                chat
                    .environment(\.brightChatShowsInput, false)
                    .transition(.opacity)
            }

            askRow
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .presentationDetents(allowedDetents, selection: $detent)
        .animation(.brightEaseInOut, value: isResting)

        // Typing from rest pulls the tray up to half.
        .onChange(of: isFieldFocused) { _, focused in
            guard focused, isResting else { return }
            refocusAfterMove = true
            withAnimation(.brightEaseInOut) { detent = .medium }
        }
        .onChange(of: isResting) { _, resting in
            guard !resting, refocusAfterMove else { return }
            refocusAfterMove = false
            Task {
                try? await Task.sleep(for: .seconds(Constants.refocusDelay))
                isFieldFocused = true
            }
        }
        .onChange(of: detent) { _, detent in
            if detent == Self.restDetent { isFieldFocused = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
            guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            TrayTypingDetent.keyboardHeight = frame.height
            guard isFieldFocused, detent != .large else { return }
            withAnimation(.brightEaseInOut) { detent = Self.typingDetent }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            TrayTypingDetent.keyboardHeight = .zero
            guard detent == Self.typingDetent else { return }
            withAnimation(.brightEaseInOut) { detent = .medium }
        }
        .sheet(isPresented: $showingCheckIns) {
            LighthouseCheckInsSheet()
        }
        .sheet(isPresented: $showingHistory) {
            LighthouseHistoryGuidedTesting { _ in startNewChat() }
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

    // At rest one row with the field between the buttons; pulled up, the field rises onto its own line above them,
    // starting where the model button does.
    private var askRow: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            if !isResting {
                askField
            }

            HStack(spacing: .spacing2x) {
                modelButton

                if isResting {
                    askField
                } else {
                    Spacer(minLength: .spacing0x)
                }

                HStack(spacing: .spacing1x) {
                    if !isResting {
                        attachMenu
                            .transition(.scale.combined(with: .opacity))
                    }
                    fieldAction
                }
            }
        }
        .padding(.spacing2x)
        .animation(.brightSnappy, value: hasDraft)
        .animation(.brightSnappy, value: dictation.isListening)
    }

    // Centred until there's something in it or it's being typed in, then it reads from the left.
    // One field: at rest it hugs its placeholder in the middle, and on tap it widens to the full row from the
    // leading edge, carrying the placeholder with it.
    private var askField: some View {
        TextField("", text: $draft, prompt: Text(Constants.askTitle).foregroundStyle(Color.lightTextColor))
            .font(.standard(size: .subheading2, weight: .light))
            .foregroundStyle(Color.textColor)
            .lineLimit(1)
            .focused($isFieldFocused)
            .submitLabel(.send)
            .onSubmit(send)
            .fixedSize(horizontal: isPlaceholderCentred, vertical: false)
            .frame(maxWidth: .infinity, alignment: isPlaceholderCentred ? .center : .leading)
            .frame(height: BrightButtonSizes.large.rawValue)
            .contentShape(.rect)
            .onTapGesture { isFieldFocused = true }
            .animation(.brightEaseInOut, value: isPlaceholderCentred)
            .matchedGeometryEffect(id: Constants.fieldID, in: barNamespace)
    }

    private var isPlaceholderCentred: Bool {
        isResting && !isFieldFocused && !hasDraft
    }

    // The model's tile fills the whole circle, in its own colours, which a round button's template glyph would flatten.
    private var modelButton: some View {
        Button {
            showingModelSelector = true
        } label: {
            Image(model.tierImageName)
                .resizable()
                .scaledToFill()
                .frame(width: BrightButtonSizes.large.rawValue, height: BrightButtonSizes.large.rawValue)
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Switch model")
    }

    // Dictation until there's something to send, then the send arrow; while it listens, a red wave that ripples.
    @ViewBuilder
    private var fieldAction: some View {
        if hasDraft, !dictation.isListening {
            BrightRoundButton(systemImage: "arrow.up", size: .large, color: .defaultSkyBlue, tinted: true, onTapCallback: send)
                .transition(.scale.combined(with: .opacity))
        } else {
            BrightRoundButton(
                systemImage: "waveform",
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
                Button(source.title, systemImage: source.symbol) {}
            }
        } label: {
            // A bare glyph, as in the chat's own input, rather than a glass circle.
            Image(systemName: "plus")
                .font(.standard(size: .subheading1, weight: .regular))
                .foregroundStyle(Color.textColor)
                .frame(width: Constants.plusSize, height: Constants.plusSize)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Attach")
    }

    // Pulled up only: the menu top right.
    private var menuRow: some View {
        HStack(spacing: .spacing0x) {
            Spacer(minLength: .spacing0x)

            menu
        }
        .padding(.horizontal, .spacing3x)
        .padding(.top, .spacing3x)
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
            Button("History", systemImage: "clock.arrow.circlepath") { showingHistory = true }
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
        if isResting {
            withAnimation(.brightEaseInOut) { detent = .medium }
        }
    }

    private func startNewChat() {
        isThinking = false
        attachments = []
        chatResetCount += 1
        isFieldFocused = true
    }

    private enum Constants {
        static let askTitle = "Ask Lighthouse anything"
        static let fieldID = "askField"
        static let refocusDelay: TimeInterval = 0.05
        static let plusSize: CGFloat = 28
        static let modelKey = "lighthouseSelectedModel"
        static let apiKeyKey = "lighthouseApiKey"
    }
}

// Half the screen less the keyboard, never shorter than the resting bar.
private struct TrayTypingDetent: CustomPresentationDetent {
    nonisolated(unsafe) static var keyboardHeight: CGFloat = .zero

    static func height(in context: Context) -> CGFloat? {
        max(context.maxDetentValue / 2 - keyboardHeight, .spacing2x + BrightButtonSizes.large.rawValue + .spacing2x)
    }
}
