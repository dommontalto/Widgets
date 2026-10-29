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

    private var tabSelection: Binding<MainDockTab> {
        Binding {
            selectedTab
        } set: { newTab in
            if newTab != .add {
                selectedTab = newTab
            }
        }
    }

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
            .overlay(alignment: .bottomTrailing) {
                if !isDockHidden {
                    lighthouseButton
                        .transition(.opacity)
                }
            }
            .animation(.brightBouncy, value: isDockHidden)
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

    // Floats over the dock's plus and opens the tray at half.
    private var lighthouseButton: some View {
        Button {
            openLighthouse(nil)
        } label: {
            LighthouseBeacon(size: Constants.beaconSize, isLit: true)
                .frame(width: Constants.lighthouseSize, height: Constants.lighthouseSize)
                .contentShape(Circle())
                .modifier(BrightGlassEffectV5(shape: .circle))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Lighthouse")
        .padding(.trailing, Constants.lighthouseTrailing)
        .padding(.bottom, Constants.lighthouseLift)
    }

    private func openLighthouse(_ action: LighthouseAction?) {
        lighthousePrompt = action?.prompt
        lighthouseDetent = .medium
        showingLighthouse = true
    }

    private var tabView: some View {
        TabView(selection: tabSelection) {
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

    private func tabLabel(_ title: String, selected: String, unselected: String, tab: MainDockTab) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(selectedTab == tab ? selected : unselected)
        }
    }

    private enum Constants {
        // The size of the dock's own plus, centred over it.
        static let lighthouseSize: CGFloat = BrightButtonSizes.finalBossLarge.rawValue
        static let beaconSize: CGFloat = .spacing6x
        static let lighthouseTrailing: CGFloat = .spacing3x + .spacing05x
        static let lighthouseLift: CGFloat = .spacing10x
    }
}

#Preview {
    MainDockView()
}
