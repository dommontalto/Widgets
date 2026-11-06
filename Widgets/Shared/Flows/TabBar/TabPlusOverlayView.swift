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
            .template(ImageNames.lighthouseV5)
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
        static let closeButtonContainerSize: CGFloat = 40
        static let cardInset: CGFloat = .spacing4x
        static let menuWidthShare: CGFloat = 0.7
        static let menuHeightShare: CGFloat = 0.6
        static let menuBottomPadding: CGFloat = .spacing12x + .spacing4x
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
        @State private var isShowingCustomiseMenuSheet = false

        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        onCloseTapped()
                    }

                menu
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .containerRelativeFrame(.vertical) { length, _ in length * Constants.menuHeightShare }
                    .padding(.trailing, .spacing3x)
                    .padding(.bottom, Constants.menuBottomPadding)
            }
            .safeAreaPadding([.top, .bottom])
            .sheet(isPresented: $isShowingCustomiseMenuSheet) {
                CustomiseMenuFlowSheet(
                    onDismiss: { isShowingCustomiseMenuSheet = false }
                )
                .ignoresSafeArea()
            }
            .onChange(of: isShowingCustomiseMenuSheet) { _, isShowing in
                if !isShowing {
                    viewModel.applyMenuConfigToVisibilityFlags()
                }
            }
        }

        private var menu: some View {
            ViewThatFits(in: .vertical) {
                menuItems
                    .padding(.vertical, Constants.cardInset)
                    .padding(.leading, Constants.cardInset)
                    .fixedSize(horizontal: false, vertical: true)

                ScrollView(showsIndicators: false) {
                    menuItems
                }
                .contentMargins(.vertical, Constants.cardInset, for: .scrollContent)
                .contentMargins(.leading, Constants.cardInset, for: .scrollContent)
            }
            .containerRelativeFrame(.horizontal) { length, _ in length * Constants.menuWidthShare }
            .clipShape(.rect(cornerRadius: .cardCornerRadius))
            .modifier(BrightGlassEffectV5(shape: .roundedRect, cornerRadius: .cardCornerRadius, interactive: false))
        }

        private var menuItems: some View {
            VStack(spacing: .spacing5x) {
                ForEach(TabPlusMenuConfigurationStore.activeItems()) { item in
                    ItemView(
                        isShowing: viewModel.isShowing(item),
                        title: titleOverride(for: item),
                        icon: item.icon,
                        onTap: { viewModel.handleItemTapped(item) }
                    )
                }

                customiseButton
            }
        }

        private var customiseButton: some View {
            HStack {
                Spacer()
                Button {
                    isShowingCustomiseMenuSheet = true
                } label: {
                    Item(title: "Customise", icon: .asset(ImageNames.movementsTop))
                }
                .buttonStyle(.plain)
            }
            .frame(height: Constants.iconSize)
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
                BrightText(title, size: .heading)
                image
                    .frame(width: Constants.iconSize)
            }
            .padding(.trailing, .spacing4x)
        }

        @ViewBuilder
        private var image: some View {
            switch icon {
            case let .asset(name):
                Image(name)
                    .resizable()
                    .scaledToFit()
            case let .template(name):
                Image(name)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.textColor)
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
