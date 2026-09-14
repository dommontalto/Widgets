//
//  LighthouseScreen.swift
//  Widgets
//
//  Created by Dom Montalto on 10/9/2026.
//

import SwiftUI

// Lighthouse as a full-screen cover over the app: the onboarding on first run,
// then the menu and chat side by side, with the edge beam and the island orb
// while it thinks and the model picker in front of the lot. Presenting it as a
// cover leaves the keyboard to the system, so the input card rides above it
// without any help from here.
struct LighthouseScreen: View {
    // Finishing the onboarding puts the chat in its place; the flag is stored
    // by the screen underneath, so it stays off across launches until switched
    // back on.
    @Binding var showOnboarding: Bool

    @Environment(\.dismiss) private var dismiss

    // The model picked in onboarding (or later, in the selector) survives
    // relaunches, so a returning user lands on the assistant they chose.
    @AppStorage(Constants.modelKey) private var model = LighthouseModel.chatGPT
    @State private var isThinking = false
    @State private var showingModelSelector = false
    @State private var showingCheckIns = false
    @State private var page: Page? = .chat
    @FocusState private var isTyping: Bool

    private enum Page: Hashable {
        case menu
        case chat
    }

    var body: some View {
        NavigationStack {
            layers
                .background { LighthouseChatBackground() }
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    if !showOnboarding {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                withAnimation(.brightEaseInOut) {
                                    page = page == .menu ? .chat : .menu
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(Color.textColor)
                            }
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.textColor)
                        }
                    }
                }
        }
        .presentationBackground(.clear)
        .animation(.brightEaseInOut, value: showOnboarding)
        .sheet(isPresented: $showingCheckIns) {
            LighthouseCheckInsSheet()
        }
        .fullScreenCover(isPresented: $showingModelSelector) {
            LighthouseModelSelectorView(currentModel: model) { model = $0 }
        }
    }

    private var layers: some View {
        ZStack(alignment: .top) {
            if showOnboarding {
                onboarding
                    .transition(.opacity)
            } else {
                pages
                    .transition(.opacity)
            }

            if isThinking {
                BrightScreenEdgeBeam(colorVariant: .skyBlueCyan)
                    .transition(.identity)
            }

            if isThinking {
                BrightIslandIndicator {
                    BrightSolvingStars(state: .thinking, ambientMotion: .off)
                        .aspectRatio(1, contentMode: .fit)
                        .containerRelativeFrame(.horizontal) { width, _ in
                            width * Constants.orbWidthFraction
                        }
                }
            }
        }
    }

    private var onboarding: some View {
        LighthouseOnboardingView(selectedModel: $model) {
            showOnboarding = false
        }
    }

    // The menu, then the chat Lighthouse opens on.
    private var pages: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing0x) {
                menu
                    .containerRelativeFrame(.horizontal)
                    .id(Page.menu)

                chat
                    .containerRelativeFrame(.horizontal)
                    .id(Page.chat)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $page)
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(.trailing)
        .brightHaptic(.impact, trigger: page)
        .onChange(of: page) { _, page in
            guard page == .menu else { return }
            isTyping = false
        }
    }

    private var chat: some View {
        LighthouseChatView(
            isThinking: $isThinking,
            selectedModel: $model,
            showingModelSelector: $showingModelSelector,
            isTyping: $isTyping,
            onDismiss: { dismiss() }
        )
    }

    private var menu: some View {
        LighthouseMenuView(
            model: model,
            onSwitchModel: { showingModelSelector = true },
            onCheckIns: { showingCheckIns = true },
            onNewChat: showChat
        )
    }

    private func showChat() {
        withAnimation(.brightEaseInOut) { page = .chat }
    }

    private enum Constants {
        static let orbWidthFraction: CGFloat = 0.25
        static let modelKey = "lighthouseSelectedModel"
    }
}
