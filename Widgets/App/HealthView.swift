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
    @State private var editor = HealthWidgetEditorV5()
    @State private var revealReplay = 0

    var body: some View {
        NavigationStack {
            content
                .background(Color.defaultBackground)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if editor.isEditing {
                            Button {
                                BrightHaptic.medium.play()
                                editor.isShowingAddSheet = true
                            } label: {
                                Label("Add", systemImage: "plus")
                                    .labelStyle(.iconOnly)
                            }
                        } else {
                            Button {
                                BrightHaptic.light.play()
                                revealReplay += 1
                            } label: {
                                Label("Replay widget animations", systemImage: "arrow.counterclockwise")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        if editor.isEditing {
                            Button {
                                editor.endEditing()
                            } label: {
                                Label("Done", systemImage: "checkmark")
                                    .labelStyle(.iconOnly)
                            }
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
                    AddWidgetSheetV5(widgetCount: editor.layout.widgets.count, layoutText: editor.layout.layoutText) {
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
                    } onShowRandom: { count in
                        editor.layout.showRandom(count)
                    } onShowNew: {
                        editor.layout.removeAll()
                        newWidgets.forEach(editor.layout.add)
                    }
                    .presentationDragIndicator(.hidden)
                    .presentationContentInteraction(.scrolls)
                }
                .sheet(item: $editor.editingWidget) { widget in
                    EditWidgetSheetV5(widget: widget) { edited in
                        withAnimation(.brightSpring) {
                            editor.layout.update(edited)
                        }
                    }
                    .presentationDragIndicator(.hidden)
                    .presentationContentInteraction(.scrolls)
                }
        }
    }

    private var newWidgets: [HealthWidgetItemV5] {
        [
            HealthWidgetItemV5(kind: .exercise, style: .exerciseSplits, size: .medium),
            HealthWidgetItemV5(kind: .exercise, style: .exerciseSplits, size: .large),
            HealthWidgetItemV5(kind: .nutrition, style: .nutritionNumber, size: .small),
            HealthWidgetItemV5(kind: .journal, style: .journalChecklist, size: .small),
            HealthWidgetItemV5(kind: .intake, style: .intakeMeter, size: .small),
            HealthWidgetItemV5(kind: .water, style: .waterMeter, size: .small),
            HealthWidgetItemV5(kind: .macros, style: .macroMeters, size: .small),
            HealthWidgetItemV5(kind: .wellbeing, style: .wellbeingMeters, size: .small),
            HealthWidgetItemV5(kind: .macros, style: .macroMeters, size: .medium),
            HealthWidgetItemV5(kind: .wellbeing, style: .wellbeingMeters, size: .medium),
        ]
            + HealthWidgetItemV5(kind: .macros, style: .macroMeter, size: .small).picks
            + HealthWidgetItemV5(kind: .sleep, style: .sleepStageMeter, size: .small).picks
            + HealthWidgetItemV5(kind: .wellbeing, style: .wellbeingMeter, size: .small).picks
            + HealthWidgetItemV5(kind: .sleep, style: .sleepStageRing, size: .small).picks
            + HealthWidgetItemV5(kind: .wellbeing, style: .wellbeingRing, size: .small).picks
    }

    private var content: some View {
        BrightSwipePageViewV5(
            pages: HomePage.allCases.map { SwipePage(title: $0.title, systemImage: $0.systemImage) },
            fakeLargeTitle: "",
            showInlineTabs: !editor.isEditing,
            pillsInToolbar: true,
            disableHorizontalScroll: editor.isEditing,
            collapsesTitleToToolbar: false,
            scrollDismissesKeyboardMode: .interactively,
            onPageScroll: { index, y, maxY in
                guard index == HomePage.health.rawValue else { return }
                editor.scrollOffsetY = y
                editor.scrollMaxOffsetY = maxY
            },
            verticalScrollPosition: $editor.scrollPosition,
            scrollControlledPageIndex: HomePage.health.rawValue,
            verticalScrollDisabledPageIndex: editor.isResizing ? HomePage.health.rawValue : nil,
            file: nil,
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
        .environment(\.brightRevealReplay, revealReplay)
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
            HealthWidgetGridV5(editor: editor)

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
