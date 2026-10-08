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
    @State private var editor = HealthWidgetEditor()

    var body: some View {
        NavigationStack {
            content
                .background(Color.defaultBackground)
                .toolbar {
                    // Straight to the widgets, editing or not.
                    ToolbarItem(placement: .topBarLeading) {
                        if editor.isEditing {
                            Button("Add") {
                                BrightHaptic.medium.play()
                                editor.isShowingAddSheet = true
                            }
                        } else {
                            Button {
                                BrightHaptic.medium.play()
                                withAnimation(.brightEaseInOut) {
                                    selectedPage = HomePage.health.rawValue
                                }
                                editor.isShowingAddSheet = true
                            } label: {
                                Label("Add widget", systemImage: "plus")
                                    .labelStyle(.iconOnly)
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
                .sheet(isPresented: $editor.isShowingAddSheet) {
                    AddWidgetSheet(widgetCount: editor.layout.widgets.count) {
                        editor.add($0)
                    } onReset: {
                        editor.layout.reset()
                    } onAddAll: {
                        editor.layout.addAll()
                    } onRemoveAll: {
                        editor.layout.removeAll()
                    } onShowAll: { size in
                        editor.layout.showAll(size)
                    } onShowFamily: { family in
                        editor.layout.showAll(family)
                    }
                    .presentationDragIndicator(.hidden)
                    .presentationContentInteraction(.scrolls)
                }
                .sheet(item: $editor.editingWidget) { widget in
                    EditWidgetSheet(widget: widget) { edited in
                        withAnimation(.brightSpring) {
                            editor.layout.update(edited)
                        }
                    }
                    .presentationDragIndicator(.hidden)
                    .presentationContentInteraction(.scrolls)
                }
        }
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
