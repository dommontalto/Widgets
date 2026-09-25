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

    @State private var sortOrder = VaultTestingSortOrder.proximity
    @State private var selectedCategory: VaultTestCategory?
    @State private var showingMap = false

    private var clinics: [VaultTestingClinic] {
        sortOrder.sorted(VaultTestingClinic.demo)
    }

    var body: some View {
        BrightSwipePageView(
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
                Button {
                    showingMap = true
                } label: {
                    Label("Map", systemImage: "map")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .navigationDestination(isPresented: $showingMap) {
            VaultClinicsMapView(clinics: clinics, onSelectClinic: onSelectClinic)
        }
        .navigationDestination(item: $selectedCategory) { category in
            VaultTestCategoryView(category: category, sortOrder: sortOrder, onSelectClinic: onSelectClinic)
        }
    }

    // MARK: - Explore

    private var explore: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            VaultTestBrowse(blur: true) { selectedCategory = $0 }
                .padding(.top, .spacing3x)

            BrightWidgetTitle(icon: .symbol("location"), title: "All Clinics Near Me") {
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
        .brightHaptic(.light, trigger: sortOrder)
    }

    // MARK: - My Orders

    @ViewBuilder
    private var myOrders: some View {
        if orders.isEmpty {
            BrightPlaceholderView(
                systemImage: "shippingbox",
                title: "No orders yet",
                subtitle: "Tests you order will show up here with their status."
            )
        } else {
            VStack(spacing: .spacing3x) {
                ForEach(orders) { order in
                    orderCard(order)
                }
            }
            .padding(.spacing3x)
            .padding(.bottom, .spacing10x)
        }
    }

    private func orderCard(_ order: VaultTestOrder) -> some View {
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

            BrightDivider()

            if let delivery = order.delivery {
                BrightText(delivery.status, size: .body1, weight: .regular)

                VaultOrderDeliveryTrack(progress: delivery.progress)
            } else {
                if let address = order.address {
                    orderDetail("mappin.and.ellipse", address)
                }

                if let scheduledAt = order.scheduledAt {
                    orderDetail("clock", scheduledAt.formatted(.brightTimestamp))
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
        .contentShape(Rectangle())
        .onTapGesture { onSelectOrder(order) }
    }

    private func orderDetail(_ systemImage: String, _ title: String) -> some View {
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

            BrightDivider()

            HStack(spacing: .spacing1x) {
                Image(systemName: "pencil.and.list.clipboard")
                    .font(.standard(size: .body1, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)

                BrightText("Services", size: .body1, color: .semiLightTextColor, weight: .regular)
            }

            FlowLayout(spacing: .spacing1x) {
                ForEach(clinic.services, id: \.self) { service in
                    BrightChip(
                        title: service,
                        tint: .defaultBlue,
                        fill: .defaultBlue.opacity(.veryMinimalOpacity)
                    )
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
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
            onSelectOrder: { _ in }
        )
    }
}

struct VaultTestBrowse: View {
    var blur = false
    let onSelect: (VaultTestCategory) -> Void

    var body: some View {
        BrightWidgetTitle(icon: .symbol("square.grid.2x2"), title: "Lab Tests Nearby") {
            BrightTileRow(blur: blur) {
                ForEach(VaultTestCategory.demo) { category in
                    BrightTile(
                        category.name,
                        subtitle: "\(VaultTestingClinic.count(offering: category.id)) clinics",
                        backgroundImage: category.backgroundName
                    ) {
                        onSelect(category)
                    } icon: {
                        VaultTestCategoryIcon(category: category, symbolSize: .standout1)
                    }
                }
            }
        }
    }
}
