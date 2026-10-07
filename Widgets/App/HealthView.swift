//
//  HealthView.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct HealthView: View {
    var onOpenLighthouse: (LighthouseAction?) -> Void = { _ in }

    @State private var selectedPage = HomePage.health.rawValue
    @State private var isSideMenuExpanded = false
    @State private var showingMyOrders = false
    @State private var editor = HealthWidgetEditor()

    var body: some View {
        NavigationStack {
            BrightSideMenuV5(
                isEnabled: !showingMyOrders && !editor.isEditing,
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
                    if editor.isEditing {
                        Button("Add") {
                            BrightHaptic.medium.play()
                            editor.isShowingAddSheet = true
                        }
                    } else {
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

                ToolbarItem(placement: .topBarTrailing) {
                    if editor.isEditing {
                        Button("Done") {
                            editor.endEditing()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.defaultSkyBlue)
                    } else {
                        Button {
                            withAnimation(.brightEaseInOut) {
                                isSideMenuExpanded = false
                                selectedPage = HomePage.health.rawValue
                            }
                            editor.beginEditing()
                        } label: {
                            Label("Edit", systemImage: "paintbrush")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showingMyOrders) {
                MyOrdersView()
            }
            .sheet(isPresented: $editor.isShowingAddSheet) {
                AddWidgetSheet {
                    editor.layout.add($0)
                } onReset: {
                    editor.layout.reset()
                }
                .presentationDragIndicator(.hidden)
                .presentationContentInteraction(.scrolls)
            }
            .sheet(item: $editor.editingWidget) { widget in
                EditWidgetSheet(widget: widget) { size, window in
                    withAnimation(.brightSpring) {
                        editor.layout.update(id: widget.id, size: size, window: window)
                    }
                }
                .presentationDragIndicator(.hidden)
                .presentationContentInteraction(.scrolls)
            }
        }
        .toolbarVisibility(isSideMenuExpanded ? .hidden : .visible, for: .tabBar)
    }

    private var content: some View {
        BrightSwipePageViewV5(
            pages: HomePage.allCases.map { SwipePage(title: $0.title, systemImage: $0.systemImage) },
            fakeLargeTitle: "",
            showInlineTabs: !editor.isEditing,
            disableHorizontalScroll: editor.isEditing,
            scrollDismissesKeyboardMode: .interactively,
            onPageScroll: { index, y, maxY in
                guard index == HomePage.health.rawValue else { return }
                editor.scrollOffsetY = y
                editor.scrollMaxOffsetY = maxY
            },
            verticalScrollPosition: $editor.scrollPosition,
            scrollControlledPageIndex: HomePage.health.rawValue,
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
        VStack(spacing: .spacing0x) {
            HealthWidgetGrid(editor: editor)

            // Room below the last widget to drag into while editing.
            Spacer(minLength: editor.isEditing ? Constants.editingBottomRoom : .spacing0x)
                .animation(.brightEaseInOut, value: editor.isEditing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private enum Constants {
        static let logoSize: CGFloat = 22
        static let menuSpringDuration: Double = 0.25
        static let menuSpringBounce: Double = 0.02
        static let editingBottomRoom: CGFloat = 300
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

#Preview {
    HealthView()
}
