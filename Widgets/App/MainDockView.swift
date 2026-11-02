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
    @State private var lighthouseDetent = PresentationDetent.medium
    @State private var lighthousePrompt: String?
    @State private var isMenuExpanded = false
    @State private var showingLighthouseCover = false
    @State private var lighthouseCoverDetent = PresentationDetent.large
    @State private var quickActions = LighthouseQuickAction.defaults
    @Namespace private var lighthouseZoom

    private var isOnSubPage: Bool {
        return coveredTabs.contains(selectedTab)
    }

    private var dockVisibility: Visibility {
        isOnSubPage ? .hidden : .visible
    }

    private var isDockHidden: Bool {
        isOnSubPage || (selectedTab == .home && isMenuExpanded)
    }

    var body: some View {
        tabView
            .overlay(alignment: .bottomTrailing) { plusZoomSource }
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
            .sheet(isPresented: $showingLighthouse) {
                LighthouseTray(
                    detent: $lighthouseDetent,
                    hasRest: false,
                    initialPrompt: lighthousePrompt
                )
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationDragIndicator(.visible)
            }
    }

    // The tray pinned at full height, with quick actions under its top row in
    // place of the welcome beacon. Its chat's own close drops it to rest, which
    // here means closing the cover.
    private var lighthouseCover: some View {
        LighthouseTray(
            detent: $lighthouseCoverDetent,
            hasRest: false,
            isSolidAtFull: false,
            hasWelcome: false,
            quickActions: LighthouseQuickActions(actions: $quickActions) { _ in
                showingLighthouseCover = false
            },
            onClose: { showingLighthouseCover = false }
        )
        .presentationBackground(.thinMaterial)
        .navigationTransition(.zoom(sourceID: Constants.plusZoomID, in: lighthouseZoom))
        .onChange(of: lighthouseCoverDetent) { _, detent in
            if detent != .large { showingLighthouseCover = false }
        }
    }

    // The plus belongs to the system dock, which SwiftUI can't zoom from, so a
    // clear stand-in sits exactly over it as the zoom's source.
    private var plusZoomSource: some View {
        Color.clear
            .frame(width: Constants.plusSize, height: Constants.plusSize)
            .matchedTransitionSource(id: Constants.plusZoomID, in: lighthouseZoom)
            .padding(.trailing, Constants.plusTrailing)
            .padding(.bottom, Constants.plusLift)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func openLighthouseCover() {
        BrightHaptic.light.play()
        lighthouseCoverDetent = .large
        showingLighthouseCover = true
    }

    private func openLighthouse(_ action: LighthouseAction?) {
        lighthousePrompt = action?.prompt
        lighthouseDetent = .medium
        showingLighthouse = true
    }

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            Tab(value: MainDockTab.home) {
                HealthView(
                    onOpenLighthouse: openLighthouse,
                    onRootCovered: { setCovered(.home, $0) },
                    isMenuExpanded: $isMenuExpanded,
                    onNavTap: { showingLighthouse = false }
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
        .modifier(MainDockMinimizesOnScroll())
    }

    private var vaultPage: some View {
        NavigationStack {
            BrightPageViewV5 {
                VaultSummaryWidget(ranking: .demo)
            }
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

    private enum Constants {
        static let plusZoomID = "lighthousePlus"
        static let plusSize: CGFloat = BrightButtonSizes.finalBossLarge.rawValue
        static let plusTrailing: CGFloat = .spacing3x + .spacing05x
        static let plusLift: CGFloat = .spacing10x
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

// iOS 26 only: the dock shrinks as a page scrolls down.
private struct MainDockMinimizesOnScroll: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}
