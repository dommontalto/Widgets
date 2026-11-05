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
    @State private var coveredTabs: Set<MainDockTab> = []
    @State private var showingLighthouse = false
    @State private var trayState = LighthouseTrayState()
    @State private var isMenuExpanded = false
    @State private var showingLighthouseCover = false
    @State private var lighthouseCoverDetent = PresentationDetent.large
    @State private var quickActions = LighthouseQuickAction.defaults

    private var isOnSubPage: Bool {
        return coveredTabs.contains(selectedTab)
    }

    private var dockVisibility: Visibility {
        isOnSubPage ? .hidden : .visible
    }

    private var isDockHidden: Bool {
        isOnSubPage || (selectedTab == .home && isMenuExpanded)
    }

    // Sub pages hide the dock, and the tray rests as the mini bar in its place.
    private var restsLighthouse: Bool {
        isOnSubPage && !(selectedTab == .home && isMenuExpanded)
    }

    var body: some View {
        tabView
            .environment(\.brightLighthouseRestHeight, restsLighthouse ? LighthouseTray.restHeight : .zero)
            .background(LighthouseTrayWindowInstaller(root: LighthouseTrayRoot(state: trayState, isOpen: $showingLighthouse)))
            .onChange(of: restsLighthouse, initial: true) { _, rests in
                trayState.rests = rests
            }
            .onChange(of: showingLighthouse) { _, showing in
                if showing {
                    if trayState.detent == LighthouseTray.restDetent { trayState.detent = LighthouseTray.halfDetent }
                } else if restsLighthouse {
                    withAnimation(.brightEaseInOut) { trayState.detent = LighthouseTray.restDetent }
                }
            }
            .onChange(of: trayState.detent) { _, detent in
                let isOpen = detent != LighthouseTray.restDetent
                if showingLighthouse != isOpen { showingLighthouse = isOpen }
            }
            // The plus is a tab of its own: undo the switch to it with the tab bar's
            // animations off, so it never shows, then open Lighthouse instead.
            .onChange(of: selectedTab) { oldTab, newTab in
                if newTab == .add {
                    UITabBar.setAnimationsEnabled(false)
                    selectedTab = oldTab
                    DispatchQueue.main.async {
                        UITabBar.setAnimationsEnabled(true)
                        openLighthouseCover()
                    }
                }
            }
            .onChange(of: isMenuExpanded) { _, expanded in
                if expanded { showingLighthouse = false }
            }
            .fullScreenCover(isPresented: $showingLighthouseCover) {
                lighthouseCover
            }
    }

    // The tray pinned at full height, with quick actions under its top row. Its
    // chat's own close drops it to rest, which here means closing the cover.
    private var lighthouseCover: some View {
        LighthouseTray(
            detent: $lighthouseCoverDetent,
            quickActions: LighthouseQuickActions(actions: $quickActions) { _ in
                showingLighthouseCover = false
            }
        ) {
            showingLighthouseCover = false
        }
        .presentationBackground(.thinMaterial)
        .onChange(of: lighthouseCoverDetent) { _, detent in
            if detent != .large { showingLighthouseCover = false }
        }
    }

    private func openLighthouseCover() {
        BrightHaptic.light.play()
        lighthouseCoverDetent = .large
        showingLighthouseCover = true
    }

    private func openLighthouse(_ action: LighthouseAction?) {
        trayState.prompt = action?.prompt
        trayState.detent = LighthouseTray.halfDetent
        showingLighthouse = true
    }

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            Tab(value: MainDockTab.home) {
                HealthView(
                    onOpenLighthouse: openLighthouse,
                    onRootCovered: { setCovered(.home, $0) },
                    isMenuExpanded: $isMenuExpanded
                )
                .toolbarVisibility(isMenuExpanded ? .hidden : dockVisibility, for: .tabBar)
            } label: {
                tabLabel("Home", selected: ImageNames.homeTabIconSelectedV5, unselected: ImageNames.homeTabIconUnselectedV5, tab: .home)
            }

            Tab(value: MainDockTab.vault) {
                vaultPage
                    .toolbarVisibility(dockVisibility, for: .tabBar)
            } label: {
                tabLabel("Vault", selected: ImageNames.vaultTabIconSelectedV5, unselected: ImageNames.vaultTabIconUnselectedV5, tab: .vault)
            }

            Tab(value: MainDockTab.atlas) {
                emptyPage
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
                .onAppear { setCovered(.vault, false) }
                .onDisappear { setCovered(.vault, true) }
        }
    }

    // A tab switch also hides its root, which isn't a sub page.
    private func setCovered(_ tab: MainDockTab, _ covered: Bool) {
        if !covered {
            coveredTabs.remove(tab)
        } else if selectedTab == tab {
            coveredTabs.insert(tab)
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
}

#Preview {
    MainDockView()
}
