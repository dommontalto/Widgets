//
//  LighthouseLayer.swift
//  Widgets
//
//  Created by Dom Montalto on 10/9/2026.
//

import SwiftUI

// Everything Lighthouse puts over a screen: the chat, its chrome, the edge
// beam while it thinks, and the model picker in front of the lot. The screen
// underneath only says whether it is up.
struct LighthouseLayer: View {
    @Binding var isPresented: Bool
    var isTyping: FocusState<Bool>.Binding

    @State private var isThinking = false
    @State private var model = LighthouseModel.chatGPT
    @State private var showingModelSelector = false
    @State private var page = Page.chat
    @State private var pageWidth: CGFloat = 0
    // How far the pages have been dragged sideways, so they follow the finger.
    @State private var pageDrag: CGFloat = 0
    // Decided on the first movement of a drag: nil until then, then whether it
    // is sideways enough to page rather than scroll the thread.
    @State private var isPaging: Bool?

    private enum Page: Hashable {
        case placeholder
        case chat
    }

    var body: some View {
        ZStack {
            if isPresented {
                pages
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(!showingModelSelector)

                chrome
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.opacity)
            }

            if isThinking {
                BrightScreenEdgeBeam(colorVariant: .skyBlueCyan)
                    .transition(.identity)
            }

            // The picker sits in front of the input bar and the close button so
            // nothing shows through it.
            if showingModelSelector {
                modelSelector
                    .transition(.opacity)
            }
        }
    }

    // The page still to come, then the chat Lighthouse opens on. The chrome
    // stays put over both. Hand-rolled rather than a ScrollView or TabView:
    // both host the chat in a way that loses either the keyboard inset or its
    // animation, so the input card stops tracking the keyboard.
    private var pages: some View {
        ZStack {
            placeholder
                .offset(x: chatOffset - pageWidth)

            LighthouseChatView(
                isThinking: $isThinking,
                selectedModel: $model,
                showingModelSelector: $showingModelSelector,
                isTyping: isTyping,
                onDismiss: close
            )
            .offset(x: chatOffset)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { pageWidth = $0 }
        .simultaneousGesture(pageDragGesture)
        .brightHaptic(.impact, trigger: page)
        .background { LighthouseChatBackground() }
    }

    private var chatOffset: CGFloat {
        let resting: CGFloat = page == .chat ? 0 : pageWidth
        return min(max(resting + pageDrag, 0), pageWidth)
    }

    private var pageDragGesture: some Gesture {
        DragGesture(minimumDistance: Constants.pageDragDistance)
            .onChanged { value in
                if isPaging == nil {
                    isPaging = abs(value.translation.width) > abs(value.translation.height)
                }
                guard isPaging == true else { return }
                pageDrag = value.translation.width
            }
            .onEnded { value in
                defer { isPaging = nil }
                guard isPaging == true else { return }
                let projected = value.predictedEndTranslation.width
                withAnimation(.brightBouncy) {
                    if page == .chat, projected > pageWidth / 2 {
                        page = .placeholder
                    } else if page == .placeholder, projected < -pageWidth / 2 {
                        page = .chat
                    }
                    pageDrag = 0
                }
            }
    }

    private var placeholder: some View {
        BrightPlaceholderView(
            systemImage: "sparkles",
            title: "Coming soon",
            subtitle: "This part of Lighthouse is still on its way."
        )
    }

    private var chrome: some View {
        HStack(spacing: .spacing0x) {
            BrightRoundButton(systemImage: "bubble.left.and.bubble.right", size: .large) {}

            Spacer()

            BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: close)
        }
        .padding(.horizontal, .spacing205x)
    }

    private var modelSelector: some View {
        ZStack {
            LighthouseModelSelectorBackground()
            LighthouseModelSelectorView(currentModel: model) { model = $0 } onDismiss: {
                withAnimation(.brightBouncy) { showingModelSelector = false }
            }
        }
    }

    // Resign first so the keyboard glides down with its system animation —
    // tearing the focused field out with the view snaps it away instead. With
    // no keyboard up there is nothing to wait for.
    private func close() {
        guard isTyping.wrappedValue else {
            dismiss()
            return
        }
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            dismiss()
        }
    }

    // Reopening lands on the chat, whichever page was showing when it closed.
    private func dismiss() {
        withAnimation(.brightBouncy) { isPresented = false }
        page = .chat
    }

    private enum Constants {
        static let pageDragDistance: CGFloat = 20
    }
}
