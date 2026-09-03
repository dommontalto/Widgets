//
//  BrightChat.swift
//  Widgets
//
//  Created by Dom Montalto on 2/9/2026.
//

import SwiftUI

nonisolated struct BrightChatMessage<Payload>: Identifiable, Equatable {
    enum Kind: Equatable {
        case user
        case assistant
        // A reply the caller draws itself, from the payload it carried.
        case response
        // A turn that never came back — rendered with a retry button.
        case failure
    }

    let id = UUID()
    let kind: Kind
    let text: String
    var payload: Payload?

    init(kind: Kind, text: String, payload: Payload? = nil) {
        self.kind = kind
        self.text = text
        self.payload = payload
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// A starter prompt paired with the glyph for what it asks about.
nonisolated struct BrightChatExample {
    let symbol: String
    let prompt: String

    init(_ symbol: String, _ prompt: String) {
        self.symbol = symbol
        self.prompt = prompt
    }
}

nonisolated struct BrightChatEmptyState {
    let title: String
    let examples: [BrightChatExample]

    init(title: String, examples: [BrightChatExample]) {
        self.title = title
        self.examples = examples
    }
}

// The chips above the input bar. `onAdd` is what enables the "+" — leave it
// nil for a thread whose suggestions are fixed.
struct BrightChatSuggestions {
    var prompts: [String] = []
    var custom: [String] = []
    var onTap: (String) -> Void
    var onAdd: ((String) -> Void)?
    var onDelete: ((String) -> Void)?

    var isEmpty: Bool {
        prompts.isEmpty && custom.isEmpty && onAdd == nil
    }
}

// The chat shell: what you send lands as an iMessage-style bubble, the orb
// spins while the answer is worked out, and a reply lands as plain text or as
// whatever the caller draws for a `.response`. The caller owns the background
// and the response design; everything else — thread, empty state, suggestion
// chips and the input bar — lives here.
struct BrightChat<Payload, Response: View, ModelPicker: View>: View {
    let messages: [BrightChatMessage<Payload>]
    let isThinking: Bool
    let isBusy: Bool
    var isTyping: FocusState<Bool>.Binding
    var emptyState: BrightChatEmptyState?
    var suggestions: BrightChatSuggestions?
    var onSend: (String) -> Void
    var onStop: () -> Void
    var onRetry: () -> Void = {}
    // Set to make a swipe down on the card — once the keyboard is away —
    // dismiss the whole chat.
    var onSwipeDismiss: (() -> Void)?
    @ViewBuilder var response: (BrightChatMessage<Payload>) -> Response
    @ViewBuilder var modelPicker: ModelPicker

    @State private var draft = ""
    @State private var promptIndex = 0
    @State private var isAddingPrompt = false
    @State private var newPromptText = ""
    @State private var chipsScrollProgress: CGFloat = 0
    @State private var chipsScrollable = false
    @FocusState private var isNewPromptFocused: Bool
    // True when the drag in flight began with the keyboard up, so the swipe
    // that puts it away can't also dismiss the chat.
    @State private var dragStartedFocused = false
    // How far the card has been dragged down, so it follows the finger.
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        thread
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: .spacing1x) {
                inputCard
            }
            // The input bar hugs the true bottom edge — its own padding is the
            // gap — rather than stacking the sheet's bottom insets under it.
            .ignoresSafeArea(.container, edges: .bottom)
            .brightHaptic(.light, trigger: messages.count)
            .onAppear { isTyping.wrappedValue = true }
            .onDisappear { onStop() }
    }

    // MARK: - Thread

    private var thread: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: .spacing3x) {
                    ForEach(messages) { message in
                        row(for: message)
                            .id(message.id)
                    }

                    if isThinking {
                        thinkingIndicator
                            .id(Constants.thinkingID)
                    }
                }
                .padding(.spacing3x)
                .animation(.brightSnappy, value: messages)
            }
            .defaultScrollAnchor(.bottom)
            // Dragging the thread carries the keyboard — and the input card
            // riding above it — down with the finger.
            .scrollDismissesKeyboard(.interactively)
            // A drawn response is read from its top, so only plain replies
            // follow the thread down to the bottom.
            .onChange(of: messages) { _, messages in
                guard let last = messages.last, last.kind != .response else { return }
                withAnimation(.brightSnappy) { proxy.scrollTo(last.id, anchor: .bottom) }
            }
            .onChange(of: isThinking) { _, isThinking in
                guard isThinking else { return }
                withAnimation(.brightSnappy) { proxy.scrollTo(Constants.thinkingID, anchor: .bottom) }
            }
        }
        // The scroll view collapses to its content while the thread is empty,
        // so the overlay only lands full width once the frame is spelled out.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if messages.isEmpty, let emptyState {
                emptyStateView(emptyState)
                    .padding(.spacing3x)
            }
        }
        // A tap anywhere off the card puts the keyboard away.
        .contentShape(.rect)
        .onTapGesture { isTyping.wrappedValue = false }
        // With nothing drawn the thread is invisible, so it shouldn't stand
        // between the finger and whatever the chat is floating over — unless
        // the keyboard is up, when a tap anywhere above the card puts it away.
        .allowsHitTesting(!messages.isEmpty || emptyState != nil || isTyping.wrappedValue)
    }

    // MARK: - Empty state

    // Before anything is sent the thread shows what it can do: an example
    // prompt under the glyph for what it asks about, cycling together and
    // fading away with the first message.
    private func emptyStateView(_ state: BrightChatEmptyState) -> some View {
        let example = state.examples.isEmpty
            ? nil
            : state.examples[promptIndex % state.examples.count]

        return VStack(spacing: .spacing4x) {
            if let example {
                Image(systemName: example.symbol)
                    .font(.system(size: Constants.exampleIconSize, weight: .light))
                    .foregroundStyle(Color.defaultSlateBlue)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(height: Constants.exampleIconSize)
            }

            BrightText(state.title, size: .huge205, color: .defaultSlateBlue)
                .multilineTextAlignment(.center)

            if let example {
                BrightText(example.prompt, size: .body1, color: .lightTextColor)
                    .lineSpacing(.lineSpacingMedium)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity)
        .task {
            guard state.examples.count > 1 else { return }
            while true {
                do {
                    try await Task.sleep(for: .seconds(Constants.exampleSwapEvery))
                } catch {
                    return
                }
                withAnimation(.brightEaseInOut) {
                    promptIndex = (promptIndex + 1) % state.examples.count
                }
            }
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private func row(for message: BrightChatMessage<Payload>) -> some View {
        Group {
            switch message.kind {
            case .user:
                userBubble(message)
            case .assistant:
                assistantText(message.text)
            case .response:
                response(message)
            case .failure:
                failureRow(message)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // Only what you send sits in a bubble — the answer lands straight on the
    // background.
    private func userBubble(_ message: BrightChatMessage<Payload>) -> some View {
        HStack(spacing: .spacing0x) {
            Spacer(minLength: .spacing8x)

            BrightText(message.text, size: .body1)
                .lineSpacing(.lineSpacingMedium)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, .spacing3x)
                .padding(.vertical, .spacing2x)
                .modifier(GlassEffect(
                    shape: .roundedRect,
                    cornerRadius: .cardCornerRadius,
                    interactive: false
                ))
                .shadow(color: .black.opacity(.ultraLowOpacity), radius: 15)
        }
    }

    private func assistantText(_ text: String) -> some View {
        BrightText(text, size: .body1)
            .lineSpacing(.lineSpacingMedium)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func failureRow(_ message: BrightChatMessage<Payload>) -> some View {
        HStack(spacing: .spacing2x) {
            BrightText(message.text, size: .body2, color: .lightTextColor)
                .lineSpacing(.lineSpacingMedium)

            BrightPillButton("Retry", buttonSize: .small) {
                onRetry()
            }

            Spacer(minLength: .spacing0x)
        }
    }

    private var thinkingIndicator: some View {
        BrightSolvingOrb(size: Constants.orbSize, speed: Constants.orbSpeed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity)
    }

    // MARK: - Input

    private var inputCard: some View {
        VStack(spacing: .spacing0x) {
            if let suggestions, !suggestions.isEmpty {
                suggestionChips(suggestions)
                    .padding(.leading, .spacing2x)
            }

            BrightPromptInputBar(
                text: $draft,
                isBusy: isBusy,
                isFocused: isTyping,
                showsModelPicker: ModelPicker.self != EmptyView.self,
                onSend: send,
                onStop: onStop
            ) {
                modelPicker
            }
            .padding(.horizontal, .spacing3x)
            .padding(.bottom, .spacing3x)
        }
        .brightKeyboardDismissDrag(isActive: isTyping.wrappedValue)
        .offset(y: dragOffset)
        .simultaneousGesture(dismissKeyboardDrag)
    }

    private var dismissKeyboardDrag: some Gesture {
        DragGesture(minimumDistance: Constants.dismissDragDistance)
            .onChanged { value in
                if isTyping.wrappedValue {
                    dragStartedFocused = true
                    return
                }
                guard onSwipeDismiss != nil, !dragStartedFocused, isDownward(value) else { return }
                dragOffset = value.translation.height
            }
            .onEnded { value in
                let startedFocused = dragStartedFocused
                dragStartedFocused = false
                let shouldDismiss = onSwipeDismiss != nil && !startedFocused && isDownward(value)
                    && (value.translation.height > Constants.dismissThreshold
                        || value.velocity.height > Constants.dismissVelocity)
                if shouldDismiss {
                    onSwipeDismiss?()
                } else {
                    withAnimation(.brightBouncy) { dragOffset = 0 }
                }
            }
    }

    private func isDownward(_ value: DragGesture.Value) -> Bool {
        value.translation.height > 0
            && value.translation.height > abs(value.translation.width)
    }

    private func suggestionChips(_ suggestions: BrightChatSuggestions) -> some View {
        HStack(spacing: .spacing0x) {
            if suggestions.onAdd != nil, !isAddingPrompt {
                Button {
                    withAnimation(.brightBouncy) {
                        isAddingPrompt = true
                    }
                } label: {
                    Image(ImageNames.lighthouseCirclePlusV5)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: Constants.addPromptSize, height: Constants.addPromptSize)
                        .foregroundStyle(Color.defaultBlue)
                }
                .padding(.top, .spacing1x)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing105x) {
                    ForEach(suggestions.prompts, id: \.self) { prompt in
                        BrightTag(title: prompt, systemImage: "sparkles", isSelected: true) {
                            suggestions.onTap(prompt)
                        }
                        .disabled(isBusy)
                    }

                    ForEach(suggestions.custom, id: \.self) { prompt in
                        BrightTag(title: prompt, systemImage: "bookmark", isSelected: true) {
                            suggestions.onTap(prompt)
                        }
                        .disabled(isBusy)
                        .transition(.scale.combined(with: .opacity))
                        .contextMenu {
                            if let onDelete = suggestions.onDelete {
                                Button(role: .destructive) {
                                    withAnimation(.brightBouncy) {
                                        onDelete(prompt)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.defaultRed)
                            }
                        }
                    }

                    if isAddingPrompt, let onAdd = suggestions.onAdd {
                        newPromptField(onAdd: onAdd)
                    }
                }
                .padding(.leading, .spacing2x)
                .padding(.trailing, .spacing3x)
                .padding(.top, .spacing3x)
                .padding(.bottom, .spacing2x)
            }
            .scrollClipDisabled()
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                let maxOffset = max(0, geo.contentSize.width - geo.containerSize.width)
                guard maxOffset > 0 else { return 0 }
                return min(1, max(0, geo.contentOffset.x / maxOffset))
            } action: { _, newValue in
                chipsScrollProgress = newValue
            }
            .onScrollGeometryChange(for: Bool.self) { geo in
                geo.contentSize.width > geo.containerSize.width
            } action: { _, newValue in
                chipsScrollable = newValue
            }
            .mask {
                HStack(spacing: .spacing0x) {
                    LinearGradient(
                        stops: [
                            .init(
                                color: .black.opacity(chipsScrollable ? (1.0 - min(
                                    CGFloat(1.0),
                                    chipsScrollProgress * 6.0
                                )) : 1.0),
                                location: 0
                            ),
                            .init(color: .black, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: Constants.chipsFadeWidth)

                    Color.black
                }
            }
        }
    }

    private func newPromptField(onAdd: @escaping (String) -> Void) -> some View {
        ZStack(alignment: .leading) {
            if newPromptText.isEmpty {
                BrightText("New prompt", size: .body1, color: .semiLightTextColor)
            }
            TextField("", text: $newPromptText)
                .font(.standard(size: .body1, weight: .light))
                .focused($isNewPromptFocused)
        }
        .padding(.horizontal, .spacing3x)
        .padding(.vertical, .spacing1x + .spacing05x)
        .modifier(GlassEffect(shape: .capsule))
        .frame(minWidth: Constants.newPromptMinWidth)
        .onAppear { isNewPromptFocused = true }
        // Tapping outside with nothing typed dismisses the new chip.
        .onChange(of: isNewPromptFocused) { _, focused in
            guard !focused,
                  newPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return }
            withAnimation(.brightBouncy) { isAddingPrompt = false }
        }
        .submitLabel(.done)
        .onSubmit {
            let trimmed = newPromptText.trimmingCharacters(in: .whitespacesAndNewlines)
            withAnimation(.brightBouncy) {
                if !trimmed.isEmpty {
                    onAdd(trimmed)
                }
                newPromptText = ""
                isAddingPrompt = false
            }
        }
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        draft = ""
        withAnimation(.brightSnappy) {
            onSend(text)
        }
    }
}

// Outside the struct: a generic type cannot hold static stored properties.
private enum Constants {
    static let thinkingID = "thinking"

    static let orbSize: CGFloat = 64
    // The speed dialled in on orbs.jakubantalik.com — multiplies the orb's
    // preset rate.
    static let orbSpeed: Double = 1.2

    static let exampleIconSize: CGFloat = 64
    static let exampleSwapEvery: TimeInterval = 3

    static let addPromptSize: CGFloat = 30
    static let chipsFadeWidth: CGFloat = 30
    static let newPromptMinWidth: CGFloat = 120
    static let dismissDragDistance: CGFloat = 20
    static let dismissThreshold: CGFloat = 50
    static let dismissVelocity: CGFloat = 300
}

extension BrightChat where ModelPicker == EmptyView {
    init(
        messages: [BrightChatMessage<Payload>],
        isThinking: Bool,
        isBusy: Bool,
        isTyping: FocusState<Bool>.Binding,
        emptyState: BrightChatEmptyState? = nil,
        suggestions: BrightChatSuggestions? = nil,
        onSend: @escaping (String) -> Void,
        onStop: @escaping () -> Void,
        onRetry: @escaping () -> Void = {},
        onSwipeDismiss: (() -> Void)? = nil,
        @ViewBuilder response: @escaping (BrightChatMessage<Payload>) -> Response
    ) {
        self.init(
            messages: messages,
            isThinking: isThinking,
            isBusy: isBusy,
            isTyping: isTyping,
            emptyState: emptyState,
            suggestions: suggestions,
            onSend: onSend,
            onStop: onStop,
            onRetry: onRetry,
            onSwipeDismiss: onSwipeDismiss,
            response: response
        ) {
            EmptyView()
        }
    }
}
