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

            BrightPillButton("Sync", systemImage: "arrow.triangle.2.circlepath") {
                BrightToastPresenterV5.shared.loading("Syncing…")
                Task {
                    try? await Task.sleep(for: .seconds(Constants.syncDemoDuration))
                    BrightToastPresenterV5.shared.success("Synced")
                }
            }

            BrightPillButton("Sync error", systemImage: "xmark") {
                BrightToastPresenterV5.shared.loading("Syncing…")
                Task {
                    try? await Task.sleep(for: .seconds(Constants.syncDemoDuration))
                    BrightToastPresenterV5.shared.error("Couldn't sync")
                }
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
            .modifier(BrightCardModifierV5(cornerRadius: .cardCornerRadius))
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
        static let syncDemoDuration: Double = 2.5
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
