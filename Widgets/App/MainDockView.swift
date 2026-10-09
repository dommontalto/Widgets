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
    @State private var lighthouse: LighthousePresentation?
    @State private var showingGenome = false
    @State private var showingGuidedTesting = false
    @AppStorage("lighthouseShowsOnboarding") private var showingLighthouseOnboarding = true

    private var tabSelection: Binding<MainDockTab> {
        Binding {
            selectedTab
        } set: { newTab in
            if newTab != .add {
                selectedTab = newTab
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            tabView

            addTabOverlayButton
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(item: $lighthouse) { presentation in
            LighthouseScreen(showOnboarding: $showingLighthouseOnboarding, action: presentation.action)
        }
    }

    private var tabView: some View {
        TabView(selection: tabSelection) {
            Tab(value: MainDockTab.home) {
                HealthView { action in
                    lighthouse = LighthousePresentation(action: action)
                }
            } label: {
                tabLabel("Home", selected: ImageNames.homeTabIconSelectedV5, unselected: ImageNames.homeTabIconUnselectedV5, tab: .home)
            }

            Tab(value: MainDockTab.vault) {
                vaultPage
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

    private var addTabOverlayButton: some View {
        Button {} label: {
            Color.clear
                .frame(width: Constants.addTargetWidth, height: Constants.addTargetHeight)
                .contentShape(Rectangle())
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: Constants.longPressDuration)
                .onEnded { _ in
                    BrightHaptic.medium.play()
                    lighthouse = LighthousePresentation(action: nil)
                }
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, .spacing4x)
        .offset(y: Constants.addTargetOffset)
    }

    private var vaultPage: some View {
        NavigationStack {
            emptyPage
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingGenome = true
                        } label: {
                            Image(ImageNames.genomeV5)
                                .resizable()
                                .scaledToFit()
                                .frame(width: Constants.genomeSize, height: Constants.genomeSize)
                        }
                    }
                    if #available(iOS 26, *) {
                        ToolbarSpacer(.fixed, placement: .topBarLeading)
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingGuidedTesting = true
                        } label: {
                            Label("Guided Testing", systemImage: "testtube.2")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
                .navigationDestination(isPresented: $showingGenome) {
                    GenomeView()
                }
                .navigationDestination(isPresented: $showingGuidedTesting) {
                    VaultGuidedTestingScreen()
                }
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
        static let addTargetWidth: CGFloat = 60
        static let addTargetHeight: CGFloat = 50
        static let addTargetOffset: CGFloat = 4
        static let longPressDuration: Double = 0.5
        static let genomeSize: CGFloat = 30
    }
}

#Preview {
    MainDockView()
}

private struct LighthousePresentation: Identifiable {
    let id = UUID()
    let action: LighthouseAction?
}
