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
    @State private var revealedLighthouse: LighthousePresentation?
    @Namespace private var promptNamespace
    @State private var screenHeight: CGFloat = .zero
    @State private var safeInsets = EdgeInsets()
    @State private var splitFraction = Constants.splitHalf
    @State private var splitDragStart: CGFloat?
    @State private var showingGenome = false
    @State private var showingGuidedTesting = false
    @State private var coveredTabs: Set<MainDockTab> = []
    @State private var lighthouseDraft = ""
    @State private var lighthouseBarHeight: CGFloat = .zero
    @FocusState private var isLighthouseBarFocused: Bool
    @State private var homeRootReset = 0
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

    private var isOnSubPage: Bool {
        if selectedTab == .vault, showingGenome || showingGuidedTesting { return true }
        return coveredTabs.contains(selectedTab)
    }

    private var dockVisibility: Visibility {
        isOnSubPage ? .hidden : .visible
    }

    // Guided Testing trials Lighthouse as its own tray instead.
    private var isLighthouseBarShown: Bool {
        isOnSubPage && revealedLighthouse == nil && !(selectedTab == .vault && showingGuidedTesting)
    }

    private var fullHeight: CGFloat {
        screenHeight + safeInsets.top + safeInsets.bottom
    }

    private var splitPanelHeight: CGFloat {
        fullHeight * splitFraction
    }

    // Past half, the panel slides over the page instead of squashing it further.
    private var pageBottomInset: CGFloat {
        guard revealedLighthouse != nil else { return .zero }
        return max(.zero, min(splitPanelHeight - safeInsets.bottom, screenHeight * Constants.splitHalf))
    }

    private var isSplitFull: Bool {
        splitFraction >= 1 && splitDragStart == nil
    }

    private func collapseSplit() {
        withAnimation(.brightBouncy) {
            splitFraction = Constants.splitNearFull
        }
    }

    // Keeps the handle clear of the Dynamic Island once the panel reaches the top.
    private var handleTopInset: CGFloat {
        max(.zero, safeInsets.top - (fullHeight - splitPanelHeight))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            tabView
                .safeAreaPadding(.bottom, isLighthouseBarShown ? lighthouseBarHeight : pageBottomInset)

            addTabOverlayButton
                .offset(y: isOnSubPage ? Constants.hiddenOffset : .zero)
                .allowsHitTesting(!isOnSubPage)
        }
        .background {
            Color.defaultBackground
                .ignoresSafeArea()
                .onGeometryChange(for: EdgeInsets.self) { $0.safeAreaInsets } action: { safeInsets = $0 }
        }
        .ignoresSafeArea(.keyboard)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { screenHeight = $0 }
        .overlay {
            if isLighthouseBarFocused {
                keyboardDismissLayer
            }
        }
        .overlay(alignment: .bottom) {
            if isLighthouseBarShown {
                lighthouseBar
                    .environment(\.brightPromptMatch, promptNamespace)
            }
        }
        .overlay(alignment: .bottom) {
            if let revealed = revealedLighthouse {
                splitPanel(revealed)
                    .transition(.offset(y: splitPanelHeight))
            }
        }
        .animation(.brightBouncy, value: isOnSubPage)
        .onChange(of: isOnSubPage) { _, onSubPage in
            if !onSubPage { revealedLighthouse = nil }
        }
        .fullScreenCover(item: $lighthouse) { presentation in
            LighthouseScreen(showOnboarding: $showingLighthouseOnboarding, action: presentation.action)
        }
    }

    private func splitPanel(_ revealed: LighthousePresentation) -> some View {
        splitPanelContent(revealed)
            .frame(height: splitPanelHeight)
            .background { LighthouseChatBackground() }
            .clipShape(.rect(topLeadingRadius: .cardCornerRadius, topTrailingRadius: .cardCornerRadius))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.container, edges: .vertical)
    }

    private func splitPanelContent(_ revealed: LighthousePresentation) -> some View {
        VStack(spacing: .spacing0x) {
            if !isSplitFull {
                splitHandle
                    .padding(.top, handleTopInset)
            }
            splitLighthouseScreen(revealed)
        }
    }

    private func splitLighthouseScreen(_ revealed: LighthousePresentation) -> some View {
        let collapse: (() -> Void)? = isSplitFull ? { collapseSplit() } : nil
        let topInset: CGFloat = isSplitFull ? safeInsets.top : .zero
        return LighthouseScreenGenome(
            showOnboarding: $showingLighthouseOnboarding,
            action: revealed.action,
            onClose: closeRevealedLighthouse,
            onCollapse: collapse
        )
        .environment(\.brightPromptMatch, promptNamespace)
        .environment(\.lighthouseGenomeShowsTopBar, isSplitFull)
        .padding(.top, topInset)
    }

    private var splitHandle: some View {
        Capsule()
            .fill(Color.lightTextColor)
            .frame(width: .spacing6x, height: .spacing1x)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacing2x)
            .contentShape(.rect)
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        guard fullHeight > 0 else { return }
                        let start = splitDragStart ?? splitFraction
                        splitDragStart = start
                        splitFraction = min(1, max(Constants.splitMin, start - value.translation.height / fullHeight))
                    }
                    .onEnded { value in
                        splitDragStart = nil
                        let fling = (value.predictedEndTranslation.height - value.translation.height) / max(fullHeight, 1)
                        let projected = splitFraction - fling
                        if projected < Constants.splitCloseBelow {
                            closeRevealedLighthouse()
                        } else {
                            withAnimation(.brightBouncy) {
                                splitFraction = projected > Constants.splitFullAbove ? 1 : Constants.splitHalf
                            }
                        }
                    }
            )
            .accessibilityLabel("Resize Lighthouse")
    }

    private func closeRevealedLighthouse() {
        withAnimation(.brightEaseInOut) {
            revealedLighthouse = nil
        }
    }

    private var tabView: some View {
        TabView(selection: tabSelection) {
            Tab(value: MainDockTab.home) {
                HealthView(rootResetID: homeRootReset) { action in
                    lighthouse = LighthousePresentation(action: action)
                } onRootCovered: { covered in
                    setCovered(.home, covered)
                }
                .toolbarVisibility(dockVisibility, for: .tabBar)
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
            BrightPageViewV5 {
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
            } content: {
                VaultSummaryWidget(ranking: .demo)
            }
            .onAppear { setCovered(.vault, false) }
            .onDisappear { setCovered(.vault, true) }
            .navigationDestination(isPresented: $showingGenome) {
                GenomeView()
            }
            .navigationDestination(isPresented: $showingGuidedTesting) {
                VaultGuidedTestingScreen()
            }
        }
    }

    private var lighthouseBar: some View {
        HStack(spacing: .spacing2x) {
            BrightRoundButton(imageName: rootIcon, size: .large, fontSize: .standout2, onTapCallback: backToRoot)
                .accessibilityLabel("Back to \(rootTitle)")

            BrightPromptInputBarV5(
                text: $lighthouseDraft,
                isBusy: false,
                isFocused: $isLighthouseBarFocused,
                onSend: sendToLighthouse,
                onStop: {}
            )
            .environment(\.brightPromptIsPill, true)
        }
        .padding(.horizontal, .spacing3x)
        .padding(.bottom, .spacing3x)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { lighthouseBarHeight = $0 }
        .ignoresSafeArea(.container, edges: .bottom)
        .transition(.opacity)
    }

    private var rootIcon: String {
        switch selectedTab {
        case .vault: ImageNames.vaultTabIconSelectedV5
        case .atlas: ImageNames.atlasTabIconSelectedV5
        case .dailyLog: ImageNames.logTabIconSelectedV5
        case .home, .add: ImageNames.homeTabIconSelectedV5
        }
    }

    private var rootTitle: String {
        switch selectedTab {
        case .vault: "Vault"
        case .atlas: "Atlas"
        case .dailyLog: "Daily"
        case .home, .add: "Home"
        }
    }

    private func backToRoot() {
        isLighthouseBarFocused = false
        switch selectedTab {
        case .vault:
            showingGenome = false
            showingGuidedTesting = false
        case .home, .add:
            homeRootReset += 1
        case .atlas, .dailyLog:
            break
        }
    }

    private var keyboardDismissLayer: some View {
        Color.clear
            .contentShape(.rect)
            .ignoresSafeArea()
            .onTapGesture { isLighthouseBarFocused = false }
            .gesture(
                DragGesture(minimumDistance: .spacing1x)
                    .onChanged { value in
                        if value.translation.height > 0 { isLighthouseBarFocused = false }
                    }
            )
    }

    private func sendToLighthouse() {
        let prompt = lighthouseDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        isLighthouseBarFocused = false
        lighthouseDraft = ""
        splitFraction = Constants.splitHalf
        withAnimation(.brightBouncy) {
            revealedLighthouse = LighthousePresentation(action: .prompt(prompt))
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
        static let addTargetWidth: CGFloat = 60
        static let addTargetHeight: CGFloat = 50
        static let addTargetOffset: CGFloat = 4
        static let longPressDuration: Double = 0.5
        static let genomeSize: CGFloat = 30
        static let hiddenOffset: CGFloat = 120
        static let splitHalf: CGFloat = 0.5
        static let splitMin: CGFloat = 0.15
        static let splitCloseBelow: CGFloat = 0.25
        static let splitFullAbove: CGFloat = 0.75
        static let splitNearFull: CGFloat = 0.85
    }
}

#Preview {
    MainDockView()
}

private struct LighthousePresentation: Identifiable {
    let id = UUID()
    let action: LighthouseAction?
}
