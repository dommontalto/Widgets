//
//  ContentView.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct ContentView: View {
    var onOpenLighthouse: (LighthouseAction?) -> Void = { _ in }

    @AppStorage("lighthouseShowsOnboarding") private var showingLighthouseOnboarding = true
    @State private var showingBeam = false
    @State private var showingGraphWorkbench = false
    @State private var beamTarget = BeamTarget.screen
    @State private var screenBeam = BeamConfig.screen
    @State private var cardBeam = BeamConfig.card
    @State private var selectedPage = HomePage.health.rawValue
    @State private var isSideMenuExpanded = false
    @State private var showingMyOrders = false

    var body: some View {
        NavigationStack {
            BrightSideMenuV5(
                isEnabled: !showingMyOrders,
                canOpenBySwipe: selectedPage == HomePage.health.rawValue,
                isExpanded: $isSideMenuExpanded
            ) {
                SideMenuView {
                    isSideMenuExpanded = false
                    showingMyOrders = true
                }
            } content: {
                content
            }
            .background(Color.defaultBackground)
            .overlay {
                if selectedPage == HomePage.health.rawValue && !isSideMenuExpanded {
                    VStack(spacing: .spacing2x) {
                        ForEach(MorphLoader.allCases, id: \.self) { loader in
                            MorphLoadingPill(loader: loader)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.interactiveSpring(duration: Constants.menuSpringDuration, extraBounce: Constants.menuSpringBounce)) {
                            isSideMenuExpanded.toggle()
                        }
                    } label: {
                        Image(ImageNames.brightLogoSearchingV4)
                            .resizable()
                            .scaledToFit()
                            .frame(width: Constants.logoSize, height: Constants.logoSize)
                    }
                }
            }
            .navigationDestination(isPresented: $showingMyOrders) {
                MyOrdersView()
            }
        }
        .toolbarVisibility(isSideMenuExpanded ? .hidden : .visible, for: .tabBar)
    }

    private var content: some View {
        BrightSwipePageViewV5(
            pages: HomePage.allCases.map { SwipePage(title: $0.title, systemImage: $0.systemImage) },
            fakeLargeTitle: "",
            scrollDismissesKeyboardMode: .interactively,
            selectedIndex: $selectedPage
        ) { index in
            switch HomePage(rawValue: index) ?? .health {
            case .health:
                healthPage
            case .waypoint:
                WaypointView(onCheckIn: { onOpenLighthouse(.checkIn) })
            case .explore:
                ExploreView()
            }
        }
        .background(Color.defaultBackground.ignoresSafeArea())
        .onChange(of: selectedPage) {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
        .fullScreenCover(isPresented: $showingBeam) {
            beamScreen
        }
        .fullScreenCover(isPresented: $showingGraphWorkbench) {
            GraphWorkbenchScreen()
        }
    }

    private var healthPage: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightPillButton("Show beam", systemImage: "wand.and.stars") {
                showingBeam = true
            }

            BrightPillButton(
                showingLighthouseOnboarding ? "Lighthouse onboarding: On" : "Lighthouse onboarding: Off",
                systemImage: "sparkles",
                isSelected: showingLighthouseOnboarding
            ) {
                showingLighthouseOnboarding.toggle()
            }
            .brightHapticV5(.light, trigger: showingLighthouseOnboarding)

            BrightPillButton("GraphRAG Workbench", systemImage: "point.3.connected.trianglepath.dotted") {
                showingGraphWorkbench = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing3x)
    }

    private var beamScreen: some View {
        NavigationStack {
            VStack(spacing: .spacing3x) {
                beamCard
                    .padding(.top, .spacing2x)

                BeamControlsView(defaults: controlDefaults, config: controlBinding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.defaultBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingBeam = false
                    } label: {
                        Label("Close", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.brightSnappy) { beamTarget = beamTarget.next }
                    } label: {
                        Label(beamTarget.title, systemImage: beamTarget.symbol)
                    }
                    .brightHapticV5(.light, trigger: beamTarget)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .overlay {
            BrightScreenEdgeBeamV5(
                isActive: screenBeam.isActive,
                cornerRadius: screenBeam.cornerRadius,
                colorVariant: screenBeam.colorVariant,
                size: screenBeam.size,
                duration: screenBeam.duration,
                brightness: screenBeam.brightness,
                saturation: screenBeam.saturation,
                strength: screenBeam.strength,
                renderScale: screenBeam.renderScale,
                tuning: screenBeam.tuning
            )
        }
        .statusBarHidden()
    }

    private var controlDefaults: BeamConfig {
        beamTarget == .card ? .card : .screen
    }

    private var controlBinding: Binding<BeamConfig> {
        beamTarget == .card ? $cardBeam : $screenBeam
    }

    // Matches the live session sheet's set row — same width inset, corner and
    // beam — with nothing in it.
    private var beamCard: some View {
        Color.clear
            .frame(height: Constants.beamCardHeight)
            .modifier(BrightCardModifierV5(cornerRadius: .cornerRadius24))
            .brightBorderBeamV5(
                cardBeam.size,
                colorVariant: cardBeam.colorVariant,
                theme: .auto,
                duration: cardBeam.duration,
                active: cardBeam.isActive,
                borderRadius: cardBeam.cornerRadius,
                brightness: cardBeam.brightness,
                saturation: cardBeam.saturation,
                strength: cardBeam.strength,
                tuning: cardBeam.tuning
            )
            .padding(.horizontal, .spacing3x)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(title, size: .standout1, weight: .medium)
            content()
        }
    }

    private func widgetLabel(_ name: String) -> some View {
        WidgetLabelRow(name: name)
    }

    private enum Constants {
        static let beamCardHeight: CGFloat = 68
        static let logoSize: CGFloat = 22
        static let menuSpringDuration: Double = 0.25
        static let menuSpringBounce: Double = 0.02
    }
}

private enum HomePage: Int, CaseIterable {
    case health
    case waypoint
    case explore

    var title: String {
        switch self {
        case .health: "Health"
        case .waypoint: "Waypoint"
        case .explore: "Explore"
        }
    }

    var systemImage: String {
        switch self {
        case .health: "heart.fill"
        case .waypoint: "safari.fill"
        case .explore: "map.fill"
        }
    }
}

private enum MorphLoader: CaseIterable {
    case orb
    case galaxy
    case logo
    case spinner

    var title: String {
        switch self {
        case .orb: "Button 1"
        case .galaxy: "Button 2"
        case .logo: "Button 3"
        case .spinner: "Button 4"
        }
    }
}

private struct MorphLoadingPill: View {
    let loader: MorphLoader
    @State private var isLoading = false

    var body: some View {
        Button {
            isLoading = true
        } label: {
            ZStack {
                if isLoading {
                    loadingView
                        .transition(.scale.combined(with: .opacity))
                } else {
                    BrightText(loader.title, size: BrightButtonSizes.large.defaultFontSize)
                        .fixedSize()
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, isLoading ? .spacing0x : .spacing3x)
            .frame(width: isLoading ? Constants.height : nil, height: Constants.height)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .modifier(BrightGlassEffectV5(shape: .capsule))
        .animation(.brightBouncy, value: isLoading)
        .brightHapticV5(.light, trigger: isLoading)
        .task(id: isLoading) {
            guard isLoading else { return }
            try? await Task.sleep(for: .seconds(5))
            isLoading = false
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        switch loader {
        case .orb:
            BrightSolvingOrbV5(size: Constants.height * 0.6)
        case .galaxy:
            BrightSolvingGalaxyV5(state: .thinking, size: Constants.height * 0.8, ambientMotion: .off)
        case .logo:
            BrightLogoAnimationV5(size: Constants.height * 0.6)
        case .spinner:
            ProgressView()
        }
    }

    private enum Constants {
        static let height: CGFloat = BrightButtonSizes.large.rawValue
    }
}

private struct WidgetLabelRow: View {
    let name: String
    @AppStorage private var isTicked: Bool

    init(name: String) {
        self.name = name
        _isTicked = AppStorage(wrappedValue: false, "widgetTicked_\(name)")
    }

    var body: some View {
        HStack(spacing: .spacing1x) {
            Button {
                isTicked.toggle()
            } label: {
                BrightTickV5(isTicked: isTicked)
            }
            .buttonStyle(.plain)

            BrightText(name, size: .body1, color: Color.lightTextColor, weight: .regular)
        }
    }
}

#Preview {
    ContentView()
}
