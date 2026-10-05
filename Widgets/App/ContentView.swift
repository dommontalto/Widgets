//
//  ContentView.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct ContentView: View {
    var onOpenLighthouse: (LighthouseAction?) -> Void = { _ in }

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

                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        Label {
                            Text("Alerts")
                        } icon: {
                            Image(ImageNames.notificationsV5)
                        }
                        .labelStyle(.iconOnly)
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
    }

    private var healthPage: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightPillButton("Sync", systemImage: "arrow.triangle.2.circlepath") {
                BrightToastPresenterV5.shared.loading("Syncing…")
                Task {
                    try? await Task.sleep(for: .seconds(Constants.syncDemoDuration))
                    BrightToastPresenterV5.shared.success("Synced")
                }
            }

            BrightPillButton("Fail", systemImage: "xmark") {
                BrightToastPresenterV5.shared.error("Couldn't save")
            }

            BrightPillButton("Long fail", systemImage: "text.alignleft") {
                BrightToastPresenterV5.shared.error(
                    "We couldn't sync your latest workouts, meals and sleep data because the connection timed out. Check your internet and try again in a few minutes."
                )
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
