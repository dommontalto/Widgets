//
//  CustomiseMenuView.swift
//  Widgets
//
//  Created by Amin Zabihi on 30/12/2025.
//

import SwiftUI

enum CustomiseMenuTab: Int, CaseIterable, TabDisplayable {
    case active = 0
    case inactive = 1

    var displayTitle: String {
        switch self {
        case .active: "Active"
        case .inactive: "Inactive"
        }
    }

    var systemImage: String {
        switch self {
        case .active: "checkmark.circle.fill"
        case .inactive: "circle.dashed"
        }
    }
}

struct CustomiseMenuItemRowState: Identifiable, Hashable {
    let id: String
    let item: TabPlusItem
    var isEnabled: Bool
}

struct CustomiseMenuView: View {
    @Bindable var viewModel: CustomiseMenuViewModel
    @State private var isSaving = false

    private var selectedTabIndex: Binding<Int> {
        Binding(
            get: { viewModel.selectedTab.rawValue },
            set: {
                let tab = CustomiseMenuTab(rawValue: $0) ?? .active
                viewModel.selectedTab = tab
            }
        )
    }

    var body: some View {
        BrightPageViewV5(
            title: "Menu",
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultSheetBackground,
            toolbar: {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.hasChanges {
                        Button {
                            guard viewModel.hasChanges else { return }
                            isSaving = true
                            viewModel.save()
                            isSaving = false
                        } label: {
                            Text("Save")
                                .foregroundStyle(Color.defaultBlack)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.defaultGreen)
                        .transition(.opacity.combined(with: .scale).animation(.brightEaseInOut))
                    }
                }
            }
        ) {
            BrightSwipePageViewV5(
                pages: CustomiseMenuTab.allCases.map { SwipePage(title: $0.displayTitle, systemImage: $0.systemImage) },
                selectedIndex: selectedTabIndex
            ) { index in
                switch CustomiseMenuTab(rawValue: index) ?? .active {
                case .active:
                    activeList
                case .inactive:
                    inactiveList
                }
            }
        }
    }

    private var activeList: some View {
        List($viewModel.activeItems, editActions: .move) { $row in
            BrightRowV5(
                titleOverride(for: row.item),
                icon: row.item.icon,
                color: .defaultSheetModalCards,
                trailing: {
                    menuControls(isOn: $row.isEnabled, showsReorderHandle: true)
                }
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
        .listRowSpacing(.spacing2x)
        .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListHeaderHeight, 0)
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 16)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: .spacing0x)
        }
    }

    private func menuControls(isOn: Binding<Bool>, showsReorderHandle: Bool) -> some View {
        HStack(spacing: .spacing2x) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.defaultBrightGreen)

            if showsReorderHandle {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.textColor)
                    .frame(width: 34, height: 34)
            }
        }
    }

    private var inactiveList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: .spacing2x) {
                ForEach($viewModel.inactiveItems) { $row in
                    BrightRowV5(
                        titleOverride(for: row.item),
                        icon: row.item.icon,
                        color: .defaultSheetModalCards,
                        trailing: {
                            menuControls(isOn: $row.isEnabled, showsReorderHandle: false)
                        }
                    )
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, .spacing3x)
        }
    }

    private func titleOverride(for item: TabPlusItem) -> String {
        switch item {
        case .imageSearch:
            "Camera"
        default:
            item.title
        }
    }
}
