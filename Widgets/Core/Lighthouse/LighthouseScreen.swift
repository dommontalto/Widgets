//
//  LighthouseScreen.swift
//  Widgets
//
//  Created by Dom Montalto on 10/9/2026.
//

import SwiftUI

// Lighthouse as a full-screen cover over the app: the onboarding on first run,
// then the chat with the side menu behind it, with the edge beam and the
// island orb while it thinks and the model picker in front of the lot.
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
    @State private var isThinking = false
    @State private var showingModelSelector = false
    @State private var showingCheckIns = false
    @State private var isMenuOpen = false
    @FocusState private var isTyping: Bool

    var body: some View {
        NavigationStack {
            layers
                .background { LighthouseChatBackground() }
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    if !showOnboarding {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                withAnimation(.brightSnappy) {
                                    isMenuOpen.toggle()
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(Color.textColor)
                            }
                            .accessibilityLabel(isMenuOpen ? "Close menu" : "Open menu")
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

    // The chat slides right off the menu behind it, dimming as it goes, by
    // swipe or the bar button. Opening puts the keyboard away.
    private var pages: some View {
        BrightSlideMenu(isExpanded: $isMenuOpen) {
            menu
        } content: {
            chat
                .background { LighthouseChatBackground() }
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
        withAnimation(.brightSnappy) { isMenuOpen = false }
    }

    private enum Constants {
        static let orbWidthFraction: CGFloat = 0.25
        static let modelKey = "lighthouseSelectedModel"
    }
}
