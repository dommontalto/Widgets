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

    var body: some View {
        ZStack {
            if isPresented {
                LighthouseChatView(
                    isThinking: $isThinking,
                    selectedModel: $model,
                    showingModelSelector: $showingModelSelector,
                    isTyping: isTyping,
                    onDismiss: close
                )
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
            withAnimation(.brightBouncy) { isPresented = false }
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
            withAnimation(.brightBouncy) { isPresented = false }
        }
    }
}
