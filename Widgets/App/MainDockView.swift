//
//  MainDockView.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

enum MainDockTab: Int {
    case home
    case vault
    case add
    case atlas
    case dailyLog
}

struct MainDockView: View {
    @State private var selectedTab = MainDockTab.home
    @State private var showingLighthouse = false
    @State private var lighthousePrompt: String?
    @State private var isMenuExpanded = false
    @State private var plusFrame = CGRect.zero

    var body: some View {
        ZStack(alignment: .bottom) {
            tabView
            plusOverlayButton
        }
        // The plus is a tab of its own: undo the switch to it with the tab bar's
        // animations off, so it never shows.
        .onChange(of: selectedTab) { oldTab, newTab in
            if newTab == .add {
                UITabBar.setAnimationsEnabled(false)
                selectedTab = oldTab
                DispatchQueue.main.async {
                    UITabBar.setAnimationsEnabled(true)
                }
            }
        }
        .fullScreenCover(isPresented: $showingLighthouse) {
            lighthouseScreen
        }
    }

    // Lighthouse at full height over the whole app.
    private var lighthouseScreen: some View {
        LighthouseWaveCover(source: plusFrame, onClosed: { present(false) }) { close in
            LighthouseScreen(initialPrompt: lighthousePrompt, onClose: close)
        }
        .presentationBackground(.clear)
        .onDisappear { lighthousePrompt = nil }
    }

    // Laid over the system plus tab: a hold opens Lighthouse.
    private var plusOverlayButton: some View {
        Color.clear
            .frame(width: Constants.plusTargetWidth, height: Constants.plusTargetHeight)
            .contentShape(Rectangle())
            .background {
                // Read on appear as well as on change, so the wave knows where the plus is before it ever moves.
                GeometryReader { geometry in
                    Color.clear
                        .onAppear { plusFrame = geometry.frame(in: .global) }
                        .onChange(of: geometry.frame(in: .global)) { _, frame in plusFrame = frame }
                }
            }
            .onLongPressGesture(minimumDuration: Constants.holdDuration) {
                BrightHaptic.medium.play()
                openLighthouse(nil)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, .spacing4x)
            .offset(y: isPlusHidden ? Constants.hiddenOffset : Constants.restingOffset)
            .allowsHitTesting(!isPlusHidden)
    }

    private var isPlusHidden: Bool {
        selectedTab == .home && isMenuExpanded
    }

    private func openLighthouse(_ action: LighthouseAction?) {
        lighthousePrompt = action?.prompt
        present(true)
    }

    // The wave brings Lighthouse in and takes it away, so the cover itself neither slides up nor down.
    private func present(_ isPresented: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { showingLighthouse = isPresented }
    }

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            Tab(value: MainDockTab.home) {
                HealthView(
                    onOpenLighthouse: openLighthouse,
                    isMenuExpanded: $isMenuExpanded
                )
                .toolbarVisibility(isMenuExpanded ? .hidden : .visible, for: .tabBar)
            } label: {
                tabLabel("Home", selected: ImageNames.homeTabIconSelectedV5, unselected: ImageNames.homeTabIconUnselectedV5, tab: .home)
            }

            Tab(value: MainDockTab.vault) {
                vaultPage
            } label: {
                tabLabel("Vault", selected: ImageNames.vaultTabIconSelectedV5, unselected: ImageNames.vaultTabIconUnselectedV5, tab: .vault)
            }

            Tab(value: MainDockTab.atlas) {
                NavigationStack {
                    ActivityView()
                }
            } label: {
                tabLabel("Atlas", selected: ImageNames.atlasTabIconSelectedV5, unselected: ImageNames.atlasTabIconUnselectedV5, tab: .atlas)
            }

            Tab(value: MainDockTab.dailyLog) {
                emptyPage
            } label: {
                tabLabel("Daily", selected: ImageNames.logTabIconSelectedV5, unselected: ImageNames.logTabIconUnselectedV5, tab: .dailyLog)
            }

            if #available(iOS 27, *) {
                Tab(value: MainDockTab.add, role: .prominent) {
                    Color.clear
                } label: {
                    addTabLabel
                }
            } else {
                Tab(value: MainDockTab.add, role: .search) {
                    Color.clear
                } label: {
                    addTabLabel
                }
            }
        }
        .tint(.primary)
    }

    private var vaultPage: some View {
        NavigationStack {
            VaultView(title: "Vault")
        }
    }

    private var emptyPage: some View {
        Color.defaultBackground.ignoresSafeArea()
    }

    private var addTabLabel: some View {
        Label {
            Text("Log")
        } icon: {
            Image(systemName: "plus")
        }
    }

    private func tabLabel(_ title: String, selected: String, unselected: String, tab: MainDockTab) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(selectedTab == tab ? selected : unselected)
        }
    }

    private enum Constants {
        static let holdDuration: TimeInterval = 0.5
        static let plusTargetWidth: CGFloat = 60
        static let plusTargetHeight: CGFloat = 50
        static let restingOffset: CGFloat = 4
        static let hiddenOffset: CGFloat = 120
    }
}

#Preview {
    MainDockView()
}
