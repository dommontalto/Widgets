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
    let date = Date()
    let kind: Kind
    let text: String
    var payload: Payload?
    // How long the model worked before this reply; set, a "Thought for…" row
    // sits above the answer and opens the thought process.
    var thoughtSeconds: Int?
    // Images sent along with the text, shown above it in the bubble.
    var attachments: [BrightChatAttachment] = []

    init(
        kind: Kind,
        text: String,
        payload: Payload? = nil,
        thoughtSeconds: Int? = nil,
        attachments: [BrightChatAttachment] = []
    ) {
        self.kind = kind
        self.text = text
        self.payload = payload
        self.thoughtSeconds = thoughtSeconds
        self.attachments = attachments
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

// The chips above the input bar.
struct BrightChatSuggestions {
    var prompts: [BrightChatExample] = []
    var custom: [String] = []
    var onTap: (String) -> Void
    // TODO: Decide whether to delete custom prompt creation.
//    var onAdd: ((String) -> Void)?
    var onDelete: ((String) -> Void)?

    var isEmpty: Bool {
        prompts.isEmpty && custom.isEmpty
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
    // Off when the caller draws the orb somewhere of its own — Lighthouse
    // hangs it off the Dynamic Island instead of the thread.
    var showsThinkingOrb = true
    // Off to leave the keyboard down until the field is tapped.
    var focusesOnAppear = true
    var emptyState: BrightChatEmptyState?
    var suggestions: BrightChatSuggestions?
    var onSend: (String) -> Void
    var onStop: () -> Void
    var onRetry: () -> Void = {}
    // Set to make a swipe down on the card — once the keyboard is away —
    // dismiss the whole chat.
    var onSwipeDismiss: (() -> Void)?
    // Tapping a reply's "Thought for…" row; the caller presents the detail.
    var onThoughtTap: ((BrightChatMessage<Payload>) -> Void)?
    // Images queued in the input card for the next message; the caller owns
    // them so it can present the pickers from the screen root.
    var attachments: Binding<[BrightChatAttachment]> = .constant([])
    var onAttach: (BrightChatAttachmentSource) -> Void = { _ in }
    // The caller's dictation, when it wants to watch the mic itself.
    var dictation: BrightDictation?
    @ViewBuilder var response: (BrightChatMessage<Payload>) -> Response
    @ViewBuilder var modelPicker: ModelPicker

    @State private var draft = ""
    @State private var flight = BrightSendFlight()
    @Namespace private var sendNamespace
    @State private var promptIndex = 0
    // TODO: Decide whether to delete custom prompt creation.
//    @State private var isAddingPrompt = false
//    @State private var newPromptText = ""
    @State private var chipsScrollProgress: CGFloat = 0
    @State private var chipsScrollable = false
//    @FocusState private var isNewPromptFocused: Bool
    // True when the drag in flight began with the keyboard up, so the swipe
    // that puts it away can't also dismiss the chat.
    @State private var dragStartedFocused = false
    // How far the card has been dragged down, so it follows the finger.
    @State private var dragOffset: CGFloat = 0
    // A swipe that starts over the card must not end as a tap on a chip or
    // a focus on the field.
    @State private var isDismissDragging = false
    // True once the thread is scrolled up past the latest message, so the
    // arrow that jumps back down has a reason to show.
    @State private var isAwayFromBottom = false

    // The message currently flying out of the input field: the newest one, held
    // back by the thread until the copy over the field hands it over.
    // Stays put through the landing animation as well as the wait, so the fit
    // it carries can't leak onto the sent bubble before it.
    private var flightID: UUID? {
        guard flight.isWaiting || flight.isFitted,
              let last = messages.last, last.kind == .user, flight.isNew(last.id) else { return nil }
        return last.id
    }

    var body: some View {
        thread
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // An empty thread stops taking taps, so the ground behind it takes
            // the tap that puts the keyboard away.
            .background {
                if isTyping.wrappedValue {
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture { isTyping.wrappedValue = false }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: .spacing1x) {
                inputCard
            }
            // The input bar hugs the true bottom edge — its own padding is the
            // gap — rather than stacking the sheet's bottom insets under it.
            .ignoresSafeArea(.container, edges: .bottom)
            .brightHaptic(.light, trigger: messages.count)
            .onAppear {
                if focusesOnAppear {
                    isTyping.wrappedValue = true
                }
            }
            .onDisappear { onStop() }
    }

    // MARK: - Thread

    private var thread: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: .spacing0x) {
                    VStack(spacing: .spacing3x) {
                        ForEach(messages) { message in
                            row(for: message)
                                .id(message.id)
                        }

                        if isThinking, showsThinkingOrb {
                            thinkingIndicator
                        }
                    }
                    .padding(.spacing3x)
                    .animation(.brightSnappy, value: messages)

                    // Sits under the padding, so scrolling to it lands on the
                    // true end of the content with nothing left to drag.
                    Color.clear
                        .frame(height: .spacing0x)
                        .id(Constants.bottomID)
                }
                .containerRelativeFrame(.horizontal)
            }
            .defaultScrollAnchor(.bottom)
            .onScrollGeometryChange(for: Bool.self) { geo in
                let remaining = geo.contentSize.height - geo.contentOffset.y - geo.containerSize.height
                return remaining > Constants.awayFromBottomThreshold
            } action: { _, isAway in
                isAwayFromBottom = isAway
            }
            // Sits just above the input card, riding the keyboard with it.
            .overlay(alignment: .bottom) {
                if isAwayFromBottom {
                    BrightRoundButton(systemImage: "arrow.down", size: .small) {
                        withAnimation(.brightSnappy) { proxy.scrollTo(Constants.bottomID, anchor: .bottom) }
                    }
                    .accessibilityLabel("Scroll to latest")
                    .padding(.bottom, .spacing2x)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.brightSnappy, value: isAwayFromBottom)
            // Dragging the thread carries the keyboard — and the input card
            // riding above it — down with the finger.
            .scrollDismissesKeyboard(.interactively)
            // Anything that arrives puts the keyboard away. A drawn response
            // is read from its top, so only plain replies follow the thread
            // down to the bottom.
            .onChange(of: messages) { _, messages in
                guard let last = messages.last else { return }
                if last.kind == .user {
                    flight.land()
                }
                if last.kind != .user {
                    isTyping.wrappedValue = false
                }
                guard last.kind != .response else { return }
                withAnimation(.brightSnappy) { proxy.scrollTo(Constants.bottomID, anchor: .bottom) }
            }
            .onChange(of: isThinking) { _, isThinking in
                guard isThinking, showsThinkingOrb else { return }
                withAnimation(.brightSnappy) { proxy.scrollTo(Constants.bottomID, anchor: .bottom) }
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
        // between the finger and whatever the chat is floating over.
        .allowsHitTesting(!messages.isEmpty || emptyState != nil)
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

    // What you send rises into place; an answer condenses out of the orb's
    // burst where it was thinking.
    @ViewBuilder
    private func row(for message: BrightChatMessage<Payload>) -> some View {
        switch message.kind {
        case .user:
            userBubble(message)
        case .assistant:
            withThought(message) { assistantText(message.text) }
                .transition(.asymmetric(insertion: .brightCondenseIn, removal: .opacity))
        case .response:
            withThought(message) { response(message) }
                .transition(.asymmetric(insertion: .brightCondenseIn, removal: .opacity))
        case .failure:
            failureRow(message)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // Only what you send sits in a bubble — the answer lands straight on the
    // background.
    private func userBubble(_ message: BrightChatMessage<Payload>) -> some View {
        HStack(spacing: .spacing0x) {
            Spacer(minLength: .spacing8x)

            sentBubble(text: message.text, attachments: message.attachments)
                .brightSendDestination(
                    flight,
                    isHeld: flight.isWaiting && flightID == message.id,
                    isFitted: flight.isFitted && flightID == message.id,
                    id: message.id,
                    in: sendNamespace
                )
        }
    }

    // Drawn twice over: once in the thread, and once over the input field
    // while the message is in flight between the two.
    private func sentBubble(text: String, attachments: [BrightChatAttachment]) -> some View {
        VStack(alignment: .trailing, spacing: .spacing2x) {
            if !attachments.isEmpty {
                sentImages(attachments)
            }

            if !text.isEmpty {
                // A touch larger than the reply text, with the padding
                // pulled in so the bubble stays the same size.
                BrightText(text, size: .subheading, color: .white)
                    .lineSpacing(.lineSpacingMedium)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, .spacing2x)
                    .padding(.vertical, .spacing105x)
                    // The tight bottom trailing corner stands in for a tail.
                    .modifier(GlassEffect(
                        shape: .cornerRadii(RectangleCornerRadii(
                            topLeading: .cornerRadius22,
                            bottomLeading: .cornerRadius22,
                            bottomTrailing: .cornerRadius8,
                            topTrailing: .cornerRadius22
                        )),
                        tint: .defaultSkyBlue,
                        interactive: false
                    ))
            }
        }
    }

    private func sentImages(_ attachments: [BrightChatAttachment]) -> some View {
        HStack(spacing: .spacing1x) {
            ForEach(attachments) { attachment in
                Image(uiImage: attachment.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Constants.sentImageSize, height: Constants.sentImageSize)
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius20, style: .continuous))
            }
        }
    }

    // Mirrors the sent bubble: a reply keeps clear of the trailing edge, so
    // the thread reads as two sides of a conversation.
    private func assistantText(_ text: String) -> some View {
        HStack(spacing: .spacing0x) {
            BrightText(text, size: .body1)
                .lineSpacing(.lineSpacingMedium)
                .multilineTextAlignment(.leading)

            Spacer(minLength: .spacing8x)
        }
    }

    // A reply the model thought about first carries the row that says so.
    @ViewBuilder
    private func withThought<Content: View>(
        _ message: BrightChatMessage<Payload>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if let seconds = message.thoughtSeconds {
            VStack(alignment: .leading, spacing: .spacing2x) {
                thoughtRow(seconds: seconds, message: message)
                content()
            }
        } else {
            content()
        }
    }

    private func thoughtRow(seconds: Int, message: BrightChatMessage<Payload>) -> some View {
        Button {
            onThoughtTap?(message)
        } label: {
            HStack(spacing: .spacing105x) {
                Image(systemName: "brain")
                    .font(.standard(size: .body1, weight: .light))

                BrightText("Thought for \(seconds) seconds", size: .body1, color: .lightTextColor)
                    .monospacedDigit()

                Image(systemName: "chevron.forward")
                    .font(.standard(size: .body4, weight: .regular))

                Spacer(minLength: .spacing0x)
            }
            .foregroundStyle(Color.lightTextColor)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
            .transition(.asymmetric(insertion: .opacity, removal: .brightBurstOut))
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
                attachments: attachments,
                isBusy: isBusy,
                isFocused: isTyping,
                showsModelPicker: ModelPicker.self != EmptyView.self,
                onSend: send,
                onStop: onStop,
                onAttach: onAttach,
                dictation: dictation,
                fieldFrame: $flight.fieldFrame
            ) {
                modelPicker
            }
            .padding(.horizontal, .spacing3x)
            .padding(.bottom, .spacing3x)
        }
        .coordinateSpace(.named(BrightChatSpace.input))
        .overlay(alignment: .topLeading) { sentSource }
        .disabled(isDismissDragging)
        .brightKeyboardDismissDrag(isActive: isTyping.wrappedValue)
        .offset(y: dragOffset)
        .simultaneousGesture(dismissKeyboardDrag)
    }

    @ViewBuilder
    private var sentSource: some View {
        if flight.isWaiting, let flightID {
            sentBubble(text: flight.text, attachments: flight.attachments)
                .brightSendSource(flight, id: flightID, in: sendNamespace)
        }
    }

    private var dismissKeyboardDrag: some Gesture {
        DragGesture(minimumDistance: Constants.dismissDragDistance)
            .onChanged { value in
                if isTyping.wrappedValue {
                    dragStartedFocused = true
                    return
                }
                guard onSwipeDismiss != nil, !dragStartedFocused, isDownward(value) else { return }
                isDismissDragging = true
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
                // The lift that ends the drag is still in flight, so the chips
                // come back a turn later.
                Task { @MainActor in
                    isDismissDragging = false
                }
            }
    }

    private func isDownward(_ value: DragGesture.Value) -> Bool {
        value.translation.height > 0
            && value.translation.height > abs(value.translation.width)
    }

    private func suggestionChips(_ suggestions: BrightChatSuggestions) -> some View {
        HStack(spacing: .spacing0x) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing105x) {
                    ForEach(suggestions.prompts, id: \.prompt) { prompt in
                        BrightTag(title: prompt.prompt, systemImage: prompt.symbol, isSelected: true) {
                            suggestions.onTap(prompt.prompt)
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

                    // TODO: Decide whether to delete custom prompt creation.
//                    if isAddingPrompt, let onAdd = suggestions.onAdd {
//                        newPromptField(onAdd: onAdd)
//                    }
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

    // TODO: Decide whether to delete custom prompt creation.
//    private func newPromptField(onAdd: @escaping (String) -> Void) -> some View {
//        ZStack(alignment: .leading) {
//            if newPromptText.isEmpty {
//                BrightText("New prompt", size: .body1, color: .semiLightTextColor)
//            }
//            TextField("", text: $newPromptText)
//                .font(.standard(size: .body1, weight: .light))
//                .focused($isNewPromptFocused)
//        }
//        .padding(.horizontal, .spacing3x)
//        .padding(.vertical, .spacing1x + .spacing05x)
//        .modifier(GlassEffect(shape: .capsule))
//        .frame(minWidth: Constants.newPromptMinWidth)
//        .onAppear { isNewPromptFocused = true }
//        // Tapping outside with nothing typed dismisses the new chip.
//        .onChange(of: isNewPromptFocused) { _, focused in
//            guard !focused,
//                  newPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//            else { return }
//            withAnimation(.brightBouncy) { isAddingPrompt = false }
//        }
//        .submitLabel(.done)
//        .onSubmit {
//            let trimmed = newPromptText.trimmingCharacters(in: .whitespacesAndNewlines)
//            withAnimation(.brightBouncy) {
//                if !trimmed.isEmpty {
//                    onAdd(trimmed)
//                }
//                newPromptText = ""
//                isAddingPrompt = false
//            }
//        }
//    }

    private func send() {
        send(draft)
    }

    private func send(_ prompt: String) {
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || !attachments.wrappedValue.isEmpty else { return }

        flight.begin(text: text, attachments: attachments.wrappedValue, after: messages.last?.id)
        onSend(text)
        isTyping.wrappedValue = false
        // Clearing in the same turn as the tap can land while the field is
        // still committing pending input, leaving typed text on screen over an
        // empty draft; the next turn lets it settle first.
        Task { @MainActor in
            draft = ""
        }
    }
}

// Outside the struct: a generic type cannot hold static stored properties.
private enum Constants {
    // How far up the thread has to sit before the arrow appears: a nudge to
    // reread the last reply shouldn't summon it, only a real scroll back.
    static let awayFromBottomThreshold: CGFloat = .spacing12x * 4
    static let bottomID = "bottom"
    static let orbSize: CGFloat = 64
    // The speed dialled in on orbs.jakubantalik.com — multiplies the orb's
    // preset rate.
    static let orbSpeed: Double = 1.2

    static let exampleIconSize: CGFloat = 64
    static let sentImageSize: CGFloat = .spacing12x + .spacing8x
    static let exampleSwapEvery: TimeInterval = 3

    static let chipsFadeWidth: CGFloat = 30
//    static let newPromptMinWidth: CGFloat = 120
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
        showsThinkingOrb: Bool = true,
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
            showsThinkingOrb: showsThinkingOrb,
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
