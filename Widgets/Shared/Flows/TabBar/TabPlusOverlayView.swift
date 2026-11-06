//
//  TabPlusOverlayView.swift
//  Widgets
//
//  Created by Zoe Friedman on 28/11/2023.
//

import SwiftUI

enum TabPlusItem: String, CaseIterable, Identifiable {
    case createRecipe
    case manualLog
    case imageSearch
    case describeMeal
    case scanBarcode
    case importRecipe
    case searchMeal
    case savedMeals
    case logWeight
    case logActivity
    case logWater
    case logCycle
    case lighthouse
    case uploadDocument
    case startExercise

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .createRecipe:
            "Create Recipe"
        case .manualLog:
            "Manual Log"
        case .imageSearch:
            "Image Search"
        case .describeMeal:
            "Describe"
        case .scanBarcode:
            "Barcode Scan"
        case .importRecipe:
            "Import Recipe"
        case .searchMeal:
            "Search Meal"
        case .savedMeals:
            "Saved Meals"
        case .logWeight:
            "Log Weight"
        case .logActivity:
            "Log Activity"
        case .logWater:
            "Log Water"
        case .logCycle:
            "Log Menstrual"
        case .lighthouse:
            "Lighthouse"
        case .uploadDocument:
            "Upload Document"
        case .startExercise:
            "Start Exercise"
        }
    }

    var icon: BrightRowV5Icon {
        switch self {
        case .manualLog:
            .asset(ImageNames.addManualLogV5)
        case .searchMeal:
            .asset(ImageNames.addSearchMealV5)
        case .imageSearch:
            .asset(ImageNames.addImageSearchV5)
        case .describeMeal:
            .asset(ImageNames.addDescribeV5)
        case .scanBarcode:
            .asset(ImageNames.addScanBarcodeV5)
        case .importRecipe:
            .asset(ImageNames.addImportRecipeV5)
        case .createRecipe:
            .asset(ImageNames.addCreateRecipeV5)
        case .savedMeals:
            .asset(ImageNames.addSavedMealsV5)
        case .logWeight:
            .asset(ImageNames.addLogWeightV5)
        case .logActivity:
            .asset(ImageNames.addLogActivityV5)
        case .logWater:
            .asset(ImageNames.addLogWaterV5)
        case .logCycle:
            .asset(ImageNames.menstrualMainV5)
        case .lighthouse:
            .asset(ImageNames.lighthouseV5)
        case .uploadDocument:
            .asset(ImageNames.vaultTabIconUnselectedV5)
        case .startExercise:
            .symbol(HealthWidgetKindV5.exercise.systemImage, tint: HealthWidgetKindV5.exercise.tint)
        }
    }
}

struct TabPlusOverlayView: View {
    @Bindable var viewModel: TabPlusOverlayViewModel
    @State private var overlayOpacity: Double = 0
    @State private var isClosing = false
    @State private var pendingCloseWorkItem: DispatchWorkItem?
    private class Constants {
        static let iconSize: CGFloat = 34
        static let itemRowHeight: CGFloat = 34 + .spacing5x
        static let closeButtonSize: CGFloat = 26
        static let closeButtonContainerSize: CGFloat = 40
        static let defaultCollapsedItemsCount = 5
        static let customiseIconSize: CGFloat = 29
        static let tapTargetSize: CGFloat = 44
        static let menuTopAnchorId = "tabPlusMenuTopAnchor"
        static let collapsedViewportExtraPadding: CGFloat = .spacing3x
        static let customiseTopPadding: CGFloat = .spacing8x
        static let expandedMenuTopGap: CGFloat = 0
        static let chevronBottomPadding: CGFloat = .spacing6x
        static let menuToChevronSpacing: CGFloat = .spacing12x + .spacing8x

        static let expandCollapseAnimationDuration: TimeInterval = 0.25
        static let menuRepositionAnimationDuration: TimeInterval = 0.25
        static let closeFadeDuration: TimeInterval = 0.25
    }

    var body: some View {
        ZStack {
            VStack(spacing: .spacing0x) {
                TabPlusView(
                    viewModel: viewModel,
                    onCloseTapped: handleCloseTapped
                )
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .opacity(overlayOpacity)
        .ignoresSafeArea(edges: .all)
        .onAppear {
            pendingCloseWorkItem?.cancel()
            pendingCloseWorkItem = nil
            overlayOpacity = 0
            isClosing = false
            withAnimation(.easeIn(duration: Constants.closeFadeDuration)) {
                overlayOpacity = 1
            }
            viewModel.handleOnAppear()
        }
        .onChange(of: viewModel.shouldClose) { _, shouldClose in
            if shouldClose {
                viewModel.shouldClose = false
                handleCloseTapped()
            }
        }
        .onDisappear {
            pendingCloseWorkItem?.cancel()
            pendingCloseWorkItem = nil
            viewModel.handleOnDisappear()
        }
    }

    private func handleCloseTapped() {
        guard !isClosing else { return }
        isClosing = true
        viewModel.didStartClose = true
        BrightHaptic.medium.play()
        withAnimation(.easeOut(duration: Constants.closeFadeDuration)) {
            overlayOpacity = 0
        }
        pendingCloseWorkItem?.cancel()
        let closeWorkItem = DispatchWorkItem {
            viewModel.didTapClose = true
        }
        pendingCloseWorkItem = closeWorkItem
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Constants.closeFadeDuration))
            if !closeWorkItem.isCancelled {
                closeWorkItem.perform()
            }
        }
    }

    struct TabPlusView: View {
        @Bindable var viewModel: TabPlusOverlayViewModel
        let onCloseTapped: () -> Void
        @State private var isExpanded = true
        @State private var isShowingCustomiseMenuSheet = false
        @State private var shouldShowCustomiseMenuOnboarding = false
        @State private var isShowingExpandedItems = true
        @State private var menuItemsHeight: CGFloat = .zero
        @State private var containerHeight: CGFloat = .zero
        @State private var customiseButtonHeight: CGFloat = .zero
        @State private var menuTopSpacerHeight: CGFloat = .zero
        @State private var isPositionAnimating = false
        @State private var viewportHeightOverride: CGFloat?
        @State private var collapsedMenuItemsHeight: CGFloat = .zero
        @State private var scrollToTopToken = 0
        @State private var showExpandButton = false

        private var expandedItems: [TabPlusItem] {
            TabPlusMenuConfigurationStore.activeItems()
        }

        private var collapsedItemsCount: Int {
            min(Constants.defaultCollapsedItemsCount, expandedItems.count)
        }

        private var visibleItems: [TabPlusItem] {
            expandedItems
        }

        private var expandedTopInset: CGFloat {
            Constants.customiseTopPadding
                + customiseButtonHeight
                + Constants.expandedMenuTopGap
        }

        private var bottomInsetForMenu: CGFloat {
            Constants.chevronBottomPadding
                + Constants.tapTargetSize
                + Constants.menuToChevronSpacing
        }

        private var expandedViewportHeight: CGFloat {
            let rawHeight = containerHeight - expandedTopInset - bottomInsetForMenu
            return max(.zero, roundToCompleteItems(rawHeight) - Constants.itemRowHeight)
        }

        private var collapsedViewportHeight: CGFloat {
            let itemCount: CGFloat = 5
            return itemCount * Constants.iconSize + (itemCount - 1) * .spacing5x
        }

        private func roundToCompleteItems(_ height: CGFloat) -> CGFloat {
            let rowHeight = Constants.itemRowHeight
            let itemCount = floor(height / rowHeight)
            guard itemCount > 0 else { return max(.zero, height) }
            return itemCount * Constants.iconSize + (itemCount - 1) * .spacing5x
        }

        private func collapsedTopSpacer(for viewportHeight: CGFloat) -> CGFloat {
            max(.zero, containerHeight - bottomInsetForMenu - viewportHeight)
        }

        var body: some View {
            GeometryReader { geo in
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Color.defaultOverlayDim
                        }
                        .ignoresSafeArea()
                        .onTapGesture {
                            onCloseTapped()
                        }

                    if showExpandButton {
                        customiseButton
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(.top, Constants.customiseTopPadding)
                            .zIndex(3)
                    }

                    menuItemsContainer(in: geo.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .zIndex(2)

                    if showExpandButton {
                        expandCollapseButton
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(.bottom, Constants.chevronBottomPadding)
                            .zIndex(4)
                    }

                    collapsedMenuItemsMeasureView
                }
                .safeAreaPadding([.top, .bottom])
                .onAppear {
                    containerHeight = geo.size.height
                    isExpanded = LocalStorage.tabPlusMenuIsExpanded
                    isShowingExpandedItems = isExpanded
                    recomputeMenuPosition(animated: false)
                    withAnimation(.easeOut(duration: Constants.closeFadeDuration)) {
                        showExpandButton = true
                    }
                }
                .onChange(of: geo.size.height) { _, newValue in
                    containerHeight = newValue
                    if !isPositionAnimating {
                        recomputeMenuPosition(animated: false)
                    }
                }
            }
            .sheet(isPresented: $isShowingCustomiseMenuSheet) {
                CustomiseMenuFlowSheet(
                    shouldShowOnboarding: shouldShowCustomiseMenuOnboarding,
                    onDismiss: { isShowingCustomiseMenuSheet = false }
                )
                .ignoresSafeArea()
            }
            .onChange(of: isShowingCustomiseMenuSheet) { _, isShowing in
                if !isShowing {
                    viewModel.applyMenuConfigToVisibilityFlags()
                    recomputeMenuPosition(animated: false)
                }
            }
        }

        private var customiseButton: some View {
            Button {
                shouldShowCustomiseMenuOnboarding = !LocalStorage.didViewCustomiseMenuOnboarding
                isShowingCustomiseMenuSheet = true
            } label: {
                HStack(spacing: .spacing3x) {
                    BrightText(
                        "Customise",
                        size: .subheading,
                        color: .textColor.opacity(.mediumOpacity)
                    )
                    Image(ImageNames.movementsTop)
                        .resizable()
                        .scaledToFit()
                        .frame(width: Constants.customiseIconSize, height: Constants.customiseIconSize)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .modifier(
                    SizeReader(didReadSize: { size in
                        let newHeight = size.height
                        if customiseButtonHeight != newHeight {
                            customiseButtonHeight = newHeight
                            if isExpanded, !isPositionAnimating {
                                recomputeMenuPosition(animated: false)
                            }
                        }
                    })
                )
            }
            .buttonStyle(.plain)
            .frame(minWidth: Constants.tapTargetSize, minHeight: Constants.tapTargetSize, alignment: .trailing)
            .padding(.trailing, .spacing4x)
            .contentShape(Rectangle())
            .transition(.move(edge: .trailing))
        }

        private var menuItems: some View {
            VStack(spacing: .spacing5x) {
                VStack(spacing: .spacing5x) {
                    ForEach(visibleItems) { item in
                        ItemView(
                            isShowing: viewModel.isShowing(item),
                            title: titleOverride(for: item),
                            icon: item.icon,
                            onTap: { viewModel.handleItemTapped(item) }
                        )
                    }
                }
            }
            .modifier(
                SizeReader(didReadSize: { size in
                    let newHeight = size.height
                    if menuItemsHeight != newHeight {
                        menuItemsHeight = newHeight
                        if !isPositionAnimating {
                            recomputeMenuPosition(animated: false)
                        }
                    }
                })
            )
        }

        private var collapsedMenuItemsMeasureView: some View {
            VStack(spacing: .spacing5x) {
                VStack(spacing: .spacing5x) {
                    ForEach(Array(expandedItems.prefix(collapsedItemsCount))) { item in
                        ItemView(
                            isShowing: viewModel.isShowing(item),
                            title: titleOverride(for: item),
                            icon: item.icon,
                            onTap: nil
                        )
                    }
                }
            }
            .modifier(
                SizeReader(didReadSize: { size in
                    let newHeight = size.height
                    if collapsedMenuItemsHeight != newHeight {
                        collapsedMenuItemsHeight = newHeight
                    }
                })
            )
            .hidden()
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }

        private func menuItemsContainer(in size: CGSize) -> some View {
            VStack(spacing: .spacing0x) {
                Spacer()
                    .frame(height: menuTopSpacerHeight)
                    .allowsHitTesting(false)

                ScrollViewReader { proxy in
                    menuScrollView(proxy: proxy, size: size)
                }
            }
        }

        @ViewBuilder
        private func menuScrollView(proxy: ScrollViewProxy, size: CGSize) -> some View {
            if #available(iOS 16.4, *) {
                baseMenuScrollView(proxy: proxy, size: size)
                    .scrollBounceBehavior(.always)
            } else {
                baseMenuScrollView(proxy: proxy, size: size)
            }
        }

        private func baseMenuScrollView(proxy: ScrollViewProxy, size: CGSize) -> some View {
            let viewportHeight = max(.zero, viewportHeightOverride ?? scrollViewportHeight(in: size))
            return ScrollView(showsIndicators: false) {
                VStack(spacing: .spacing0x) {
                    Color.clear
                        .frame(height: 1)
                        .id(Constants.menuTopAnchorId)

                    Spacer(minLength: .zero)

                    menuItems
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(minHeight: viewportHeight, alignment: .bottomTrailing)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .frame(height: viewportHeight)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.02),
                        .init(color: .black, location: 0.98),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onCloseTapped()
            }
            .onChange(of: scrollToTopToken) { _, _ in
                withAnimation(.none) {
                    proxy.scrollTo(Constants.menuTopAnchorId, anchor: .top)
                }
            }
        }

        private func scrollViewportHeight(in size: CGSize) -> CGFloat {
            if !isExpanded {
                return collapsedViewportHeight
            }

            return expandedViewportHeight
        }

        private var expandCollapseButton: some View {
            BrightRoundButton(
                systemImage: "chevron.up",
                size: .large,
                imageRotation: .degrees(isExpanded ? 180 : 0),
                onTapCallback: { toggleExpanded() }
            )
            .animation(.easeInOut(duration: Constants.expandCollapseAnimationDuration), value: isExpanded)
            .frame(width: 60, height: 60)
            .padding(.trailing, .spacing3x + .spacing05x)
            .contentShape(Rectangle())
            .transition(.move(edge: .trailing))
        }

        private func toggleExpanded() {
            BrightHaptic.light.play()
            LocalStorage.tabPlusMenuIsExpanded = !isExpanded
            if isExpanded {
                scrollToTopToken += 1
                isShowingExpandedItems = true

                let fromHeight = expandedViewportHeight
                let toHeight = collapsedViewportHeight

                viewportHeightOverride = fromHeight
                let targetTopSpacer = collapsedTopSpacer(for: toHeight)

                isPositionAnimating = true
                withAnimation(.easeInOut(duration: Constants.expandCollapseAnimationDuration)) {
                    isExpanded = false
                    isShowingExpandedItems = false
                    viewportHeightOverride = toHeight
                    menuTopSpacerHeight = targetTopSpacer
                }

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(Constants.expandCollapseAnimationDuration))
                    isPositionAnimating = false
                    viewportHeightOverride = nil
                    recomputeMenuPosition(animated: false)
                }
            } else {
                scrollToTopToken += 1
                let fromHeight = collapsedViewportHeight
                let toHeight = expandedViewportHeight
                let targetTopSpacer = containerHeight - bottomInsetForMenu - toHeight

                viewportHeightOverride = fromHeight

                isPositionAnimating = true
                withAnimation(.easeInOut(duration: Constants.expandCollapseAnimationDuration)) {
                    isExpanded = true
                    isShowingExpandedItems = true
                    viewportHeightOverride = toHeight
                    menuTopSpacerHeight = targetTopSpacer
                }

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(Constants.expandCollapseAnimationDuration))
                    isPositionAnimating = false
                    viewportHeightOverride = nil
                    recomputeMenuPosition(animated: false)
                }
            }
        }

        private func recomputeMenuPosition(
            animated: Bool,
            overrideExpanded: Bool? = nil,
            overrideViewportHeight: CGFloat? = nil
        ) {
            let expanded = overrideExpanded ?? isExpanded
            let viewportHeight: CGFloat = {
                if let overrideViewportHeight { return overrideViewportHeight }
                if expanded {
                    return expandedViewportHeight
                }
                return collapsedViewportHeight
            }()

            let targetTopSpacer = containerHeight - bottomInsetForMenu - viewportHeight

            if animated {
                isPositionAnimating = true
                withAnimation(.easeInOut(duration: Constants.menuRepositionAnimationDuration)) {
                    menuTopSpacerHeight = targetTopSpacer
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(Constants.menuRepositionAnimationDuration))
                    isPositionAnimating = false
                }
            } else {
                menuTopSpacerHeight = targetTopSpacer
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

    struct ItemView: View {
        let isShowing: Bool
        let title: String
        let icon: BrightRowV5Icon
        let onTap: (() -> Void)?

        var body: some View {
            VStack {
                if isShowing {
                    HStack {
                        Spacer()
                        Button(action: { onTap?() }) {
                            Item(title: title, icon: icon)
                        }
                    }
                    .transition(.move(edge: .trailing))
                }
            }
            .frame(height: Constants.iconSize)
        }
    }

    struct Item: View {
        let title: String
        let icon: BrightRowV5Icon

        var body: some View {
            HStack(spacing: .spacing3x) {
                BrightText(
                    title,
                    size: .subheading,
                    color: .textColor.opacity(.mediumOpacity)
                )
                image
                    .frame(width: Constants.iconSize)
            }
            .padding(.trailing, .spacing4x)
        }

        @ViewBuilder
        private var image: some View {
            switch icon {
            case let .asset(name), let .template(name):
                Image(name)
                    .resizable()
                    .scaledToFit()
            case let .symbol(name, tint):
                Image(systemName: name)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(tint)
            }
        }
    }

    struct TabBottomView: View {
        let onCloseTapped: (() -> Void)?
        let isXRotated: Bool

        var body: some View {
            HStack {
                BrightRoundButton(systemImage: "xmark") { onCloseTapped?() }
                    .rotationEffect(isXRotated ? .degrees(-45) : .zero)
                    .frame(
                        width: Constants.closeButtonContainerSize,
                        height: Constants.closeButtonContainerSize
                    )
                    .padding(.top, 8)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .top
                    )
            }
            .frame(height: 49)
            .safeAreaPadding(.bottom)
        }
    }
}
