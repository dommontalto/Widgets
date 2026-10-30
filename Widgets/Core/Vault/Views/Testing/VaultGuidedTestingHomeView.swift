//
//  VaultGuidedTestingHomeView.swift
//  Widgets
//
//  Created by Dom Montalto on 17/9/2026.
//

import SwiftUI

struct VaultGuidedTestingHomeView: View {
    let onOrder: (VaultTestOrder) -> Void

    @State private var selectedPage = 0
    @State private var showingMap = false
    @State private var showingCart = false
    @State private var selectedTest: VaultClinicTest?
    @State private var selectedCategory: VaultTestCategory?

    private let catalog = LabCatalog.shared

    // One page per region, Australia first.
    private let regions: [LabRegion] = [.au, .us]

    private var region: LabRegion {
        regions[selectedPage]
    }

    var body: some View {
        BrightSwipePageViewV5(
            pages: regions.map { SwipePage(title: $0.shortTitle, systemImage: $0.systemImage) },
            fakeLargeTitle: "Labs",
            backgroundColor: .defaultBackground,
            selectedIndex: $selectedPage
        ) { page in
            lab(regions[page])
        }
        .toolbar {
            if region == .au {
                ToolbarItem(placement: .topBarTrailing) {
                    LabCentresMapButton { showingMap = true }
                }
                if #available(iOS 26, *) {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    LabCartButton { showingCart = true }
                }
            }
        }
        .navigationDestination(isPresented: $showingMap) {
            LabCollectionCentresMapView { order in
                showingMap = false
                onOrder(order)
            }
        }
        .navigationDestination(isPresented: $showingCart) {
            if let clinic = catalog.clinic(for: .au) {
                LabCartView(clinic: clinic, isSheet: false) { order in
                    showingCart = false
                    onOrder(order)
                }
            }
        }
        .navigationDestination(item: $selectedTest) { test in
            if let clinic = catalog.clinic(for: region) {
                VaultTestDetailView(
                    test: test,
                    clinic: clinic,
                    isSheet: false,
                    style: region.provider == .junction ? VaultPanelTile.styles(for: clinic.tests)[test.id] : nil,
                    onOrder: order
                )
            }
        }
        .navigationDestination(item: $selectedCategory) { category in
            VaultTestCategoryView(category: category, onOrder: order)
        }
        .task {
            guard LabOrdering.isAvailable else { return }
            await catalog.select(region)
        }
        .onChange(of: selectedPage) {
            Task { await catalog.select(region) }
        }
    }

    // MARK: - Lab

    @ViewBuilder
    private func lab(_ region: LabRegion) -> some View {
        if let clinic = catalog.clinic(for: region) {
            BrightCardGridV5(spacing: .spacing3x) {
                switch region.provider {
                case .junction:
                    let styles = VaultPanelTile.styles(for: clinic.tests)
                    ForEach(clinic.tests) { test in
                        VaultPanelTile(test: test, style: styles[test.id] ?? VaultTestCategory.all[0]) {
                            selectedTest = test
                        }
                    }
                case .eirly:
                    ForEach(clinic.categories) { category in
                        VaultTestCategoryTile(category: category, fillsWidth: true, clinic: clinic) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, .spacing3x)
            .padding(.top, .spacing3x)
            .padding(.bottom, .spacing10x)
        } else if catalog.region != region || catalog.isLoading {
            BrightProgressViewV5()
                .containerRelativeFrame(.vertical)
        } else {
            BrightPlaceholderViewV5(
                systemImage: "testtube.2",
                title: "No tests available",
                subtitle: "\(region.provider.title) tests will appear here once they're available."
            )
        }
    }

    private func order(_ order: VaultTestOrder) {
        selectedTest = nil
        selectedCategory = nil
        onOrder(order)
    }
}

// A single lab panel as a tile, wearing a category's artwork.
struct VaultPanelTile: View {
    let test: VaultClinicTest
    let style: VaultTestCategory
    let onTap: () -> Void

    var body: some View {
        BrightTileV5(
            test.name,
            subtitle: "\(test.included.count) \(test.included.count == 1 ? "test" : "tests")",
            backgroundImage: style.tileName,
            fillsWidth: true,
            onTap: onTap
        ) {
            VaultTestCategoryIcon(category: style, symbolSize: .standout1)
        }
    }

    // Each panel gets its own artwork: its first category not yet taken, else any unused one.
    static func styles(for tests: [VaultClinicTest]) -> [String: VaultTestCategory] {
        var unused = VaultTestCategory.all
        var styles: [String: VaultTestCategory] = [:]
        for test in tests {
            if let index = unused.firstIndex(where: { test.categoryIds.contains($0.id) }) {
                styles[test.id] = unused.remove(at: index)
            }
        }
        for test in tests where styles[test.id] == nil {
            let fallback = test.categoryIds.first.flatMap { id in VaultTestCategory.all.first { $0.id == id } }
            styles[test.id] = unused.isEmpty ? fallback : unused.removeFirst()
        }
        return styles
    }
}

// MARK: - Delivery track

struct VaultOrderDeliveryTrack: View {
    let progress: Double

    @State private var trackWidth: CGFloat = .spacing0x

    var body: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "shippingbox")
                .font(.standard(size: .heading, weight: .light))
                .foregroundStyle(Color.semiLightTextColor)

            Capsule()
                .fill(Color.textColor.opacity(.ultraLowOpacity))
                .frame(height: Constants.height)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    trackWidth = width
                }
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.defaultGreen)
                        .frame(width: trackWidth * min(max(progress, 0), 1))
                }

            Image(systemName: "house")
                .font(.standard(size: .heading, weight: .light))
                .foregroundStyle(Color.semiLightTextColor)
        }
        .animation(.brightEaseInOut, value: progress)
    }

    private enum Constants {
        static let height: CGFloat = .spacing105x
    }
}

// MARK: - Category icon

struct VaultTestCategoryIcon: View {
    let category: VaultTestCategory
    let symbolSize: FontSizes

    @ViewBuilder
    var body: some View {
        if let iconName = category.iconName {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: category.systemImage)
                .font(.standard(size: symbolSize, weight: .medium))
        }
    }
}

// MARK: - Clinic logo

struct VaultClinicLogo: View {
    var body: some View {
        Circle()
            .fill(Color.defaultBlack)
            .frame(width: .spacing5x, height: .spacing5x)
            .overlay {
                Image(systemName: "circle.hexagongrid")
                    .font(.system(size: Constants.glyphSize, weight: .medium))
                    .foregroundStyle(.white)
            }
    }

    private enum Constants {
        static let glyphSize: CGFloat = 14
    }
}

#Preview {
    NavigationStack {
        VaultGuidedTestingHomeView { _ in }
    }
}

struct VaultTestBrowse: View {
    var blur = false
    let onOrder: (VaultTestOrder) -> Void

    @State private var showsAllCategories = false
    @State private var selectedCategory: VaultTestCategory?

    private var categories: [VaultTestCategory] {
        VaultTestCategory.offered
    }

    var body: some View {
        if !categories.isEmpty {
            BrightWidgetTitleV5(icon: .symbol("square.grid.2x2"), title: "Labs", onTap: { showsAllCategories = true }) {
                BrightTileRowV5(blur: blur) {
                    ForEach(categories) { category in
                        VaultTestCategoryTile(category: category) { selectedCategory = category }
                    }
                }
            }
            .navigationDestination(isPresented: $showsAllCategories) {
                VaultTestCategoriesView(onOrder: order)
            }
            .navigationDestination(item: $selectedCategory) { category in
                VaultTestCategoryView(category: category, onOrder: order)
            }
        }
    }

    private func order(_ order: VaultTestOrder) {
        showsAllCategories = false
        selectedCategory = nil
        onOrder(order)
    }
}

struct VaultTestCategoryTile: View {
    let category: VaultTestCategory
    var fillsWidth = false
    var clinic: VaultTestingClinic?
    let onTap: () -> Void

    private var count: Int {
        clinic?.count(in: category.id) ?? VaultTestingClinic.testCount(in: category.id)
    }

    var body: some View {
        BrightTileV5(
            category.name,
            subtitle: "\(count) \(count == 1 ? "test" : "tests")",
            backgroundImage: category.tileName,
            fillsWidth: fillsWidth,
            onTap: onTap
        ) {
            VaultTestCategoryIcon(category: category, symbolSize: .standout1)
        }
    }
}

// Every test category at once, laid out like Genome's categories.
struct VaultTestCategoriesView: View {
    let onOrder: (VaultTestOrder) -> Void

    @State private var selectedCategory: VaultTestCategory?

    var body: some View {
        BrightPageViewV5(title: "Labs") {
            BrightCardGridV5(spacing: .spacing3x) {
                ForEach(VaultTestCategory.offered) { category in
                    VaultTestCategoryTile(category: category, fillsWidth: true) { selectedCategory = category }
                }
            }
            .padding(.bottom, .spacing4x)
        }
        .navigationDestination(item: $selectedCategory) { category in
            VaultTestCategoryView(category: category) { order in
                selectedCategory = nil
                onOrder(order)
            }
        }
    }
}

struct LabRegionMenu: View {
    var showsTitle = false

    private let catalog = LabCatalog.shared

    var body: some View {
        Menu {
            ForEach(LabRegion.allCases) { region in
                Button {
                    Task { await catalog.select(region) }
                } label: {
                    Label {
                        Text(region.title)
                    } icon: {
                        if region == catalog.region {
                            Image(systemName: "checkmark")
                        } else {
                            Image(systemName: region.systemImage)
                        }
                    }
                }
            }
        } label: {
            if showsTitle {
                BrightPillButton(catalog.region?.title ?? "Region", systemImage: catalog.region?.systemImage ?? "globe", buttonSize: .small) {}
                    .allowsHitTesting(false)
            } else {
                Label("Region", systemImage: catalog.region?.systemImage ?? "globe")
                    .labelStyle(.iconOnly)
            }
        }
        .brightHapticV5(.light, trigger: catalog.region)
    }
}

struct LabCentresMapButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Collection Centres", systemImage: "map")
                .labelStyle(.iconOnly)
        }
    }
}
