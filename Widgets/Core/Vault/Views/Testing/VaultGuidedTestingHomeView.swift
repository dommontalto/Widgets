//
//  VaultGuidedTestingHomeView.swift
//  Widgets
//
//  Created by Dom Montalto on 17/9/2026.
//

import SwiftUI

struct VaultGuidedTestingHomeView: View {
    let orders: [VaultTestOrder]
    @Binding var selectedPage: Int
    let onSelectClinic: (VaultTestingClinic) -> Void
    let onSelectOrder: (VaultTestOrder) -> Void

    let onOrder: (VaultTestOrder) -> Void

    @State private var sortOrder = VaultTestingSortOrder.proximity
    @State private var showingMap = false
    @State private var showingCart = false

    private let catalog = LabCatalog.shared

    private var clinics: [VaultTestingClinic] {
        sortOrder.sorted(VaultTestingClinic.all)
    }

    var body: some View {
        BrightSwipePageViewV5(
            pages: [
                SwipePage(title: "Explore", systemImage: "sparkle.magnifyingglass"),
                SwipePage(title: "My Orders", systemImage: "shippingbox"),
            ],
            fakeLargeTitle: "Guided Testing",
            backgroundColor: .defaultBackground,
            selectedIndex: $selectedPage
        ) { page in
            if page == 0 {
                explore
            } else {
                myOrders
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                LabRegionMenu()
            }
            if catalog.region == .au {
                ToolbarItem(placement: .topBarTrailing) {
                    LabCartButton { showingCart = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    LabCentresMapButton { showingMap = true }
                }
            }
        }
        .navigationDestination(isPresented: $showingMap) {
            LabCollectionCentresMapView()
        }
        .navigationDestination(isPresented: $showingCart) {
            if let clinic = catalog.clinic(for: .au) {
                LabCartView(clinic: clinic, isSheet: false) { order in
                    showingCart = false
                    onOrder(order)
                }
            }
        }
    }

    // MARK: - Explore

    private var explore: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            VaultTestBrowse(blur: true, onOrder: onOrder)
                .padding(.top, .spacing3x)

            BrightWidgetTitleV5(icon: .symbol("location"), title: "All Clinics Near Me") {
                sortMenu
                    .padding(.trailing, .spacing3x)
            } content: {
                VStack(spacing: .spacing3x) {
                    ForEach(clinics) { clinic in
                        VaultClinicCard(clinic: clinic) { onSelectClinic(clinic) }
                    }
                }
                .padding(.horizontal, .spacing3x)
            }
        }
        .padding(.bottom, .spacing10x)
        .animation(.brightEaseInOut, value: sortOrder)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(VaultTestingSortOrder.allCases) { order in
                Button {
                    sortOrder = order
                } label: {
                    Label {
                        Text(order.rawValue)
                    } icon: {
                        if order == sortOrder {
                            Image(systemName: "checkmark")
                        } else {
                            Image(systemName: order.systemImage)
                        }
                    }
                }
            }
        } label: {
            BrightPillButton(sortOrder.rawValue, systemImage: "line.3.horizontal.decrease", buttonSize: .small) {}
                .allowsHitTesting(false)
        }
        .brightHapticV5(.light, trigger: sortOrder)
    }

    // MARK: - My Orders

    @ViewBuilder
    private var myOrders: some View {
        if orders.isEmpty {
            BrightPlaceholderViewV5(
                systemImage: "shippingbox",
                title: "No orders yet",
                subtitle: "Tests you order will show up here with their status."
            )
        } else {
            VStack(spacing: .spacing3x) {
                ForEach(orders) { order in
                    VaultOrderCard(order: order) { onSelectOrder(order) }
                }
            }
            .padding(.spacing3x)
            .padding(.bottom, .spacing10x)
        }
    }
}

// MARK: - Order card

struct VaultOrderCard: View {
    let order: VaultTestOrder
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .top, spacing: .spacing2x) {
                VaultClinicLogo()

                Spacer(minLength: .spacing0x)

                HStack(spacing: .spacing1x) {
                    Image(systemName: order.type.systemImage)
                        .font(.standard(size: .body1, weight: .light))

                    BrightText(order.type.rawValue, size: .body1, weight: .regular)
                }
            }

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(order.clinic.name, size: .subheading, color: .semiLightTextColor, weight: .regular)

                BrightText(order.test.name, size: .body1, color: .lightTextColor)
            }

            BrightDividerV5()

            if let delivery = order.delivery {
                BrightText(delivery.status, size: .body1, weight: .regular)

                VaultOrderDeliveryTrack(progress: delivery.progress)
            } else {
                if let address = order.address {
                    detail("mappin.and.ellipse", address)
                }

                if let scheduledAt = order.scheduledAt {
                    detail("clock", scheduledAt.formatted(.brightTimestamp))
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5())
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private func detail(_ systemImage: String, _ title: String) -> some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: systemImage)
                .font(.standard(size: .body1, weight: .light))
                .foregroundStyle(Color.semiLightTextColor)

            BrightText(title, size: .body1, weight: .regular)
                .fixedSize(horizontal: false, vertical: true)
        }
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

// MARK: - Clinic card

struct VaultClinicCard: View {
    let clinic: VaultTestingClinic
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .top) {
                VaultClinicLogo()

                Spacer(minLength: .spacing0x)

                BrightPillButton("Find out more", buttonSize: .small, onTapCallback: onTap)
            }

            BrightText(clinic.name, size: .body1, color: .semiLightTextColor, weight: .regular)

            BrightText(clinic.address, size: .body1, color: .lightTextColor)

            BrightDividerV5()

            HStack(spacing: .spacing1x) {
                Image(systemName: "pencil.and.list.clipboard")
                    .font(.standard(size: .body1, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)

                BrightText("Services", size: .body1, color: .semiLightTextColor, weight: .regular)
            }

            FlowLayout(spacing: .spacing1x) {
                ForEach(clinic.services, id: \.self) { service in
                    BrightChipV5(
                        title: service,
                        tint: .defaultBlue,
                        fill: .defaultBlue.opacity(.veryMinimalOpacity)
                    )
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5())
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
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
    @Previewable @State var page = 0

    NavigationStack {
        VaultGuidedTestingHomeView(
            orders: [],
            selectedPage: $page,
            onSelectClinic: { _ in },
            onSelectOrder: { _ in },
            onOrder: { _ in }
        )
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
            BrightWidgetTitleV5(icon: .symbol("square.grid.2x2"), title: "Guided Testing", onTap: { showsAllCategories = true }) {
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
    let onTap: () -> Void

    private var count: Int {
        VaultTestingClinic.testCount(in: category.id)
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
        BrightPageViewV5(title: "Guided Testing") {
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
            Label("Region", systemImage: catalog.region?.systemImage ?? "globe")
                .labelStyle(.iconOnly)
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
