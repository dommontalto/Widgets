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

    @State private var sortOrder = VaultTestingSortOrder.proximity
    @State private var selectedCategory: VaultTestCategory?
    @State private var showingMap = false

    private let categories = VaultTestCategory.demo

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
            BrightText("Testing Categories", size: .heading, weight: .regular)
                .padding(.horizontal, .spacing3x)
                .padding(.top, .spacing3x)

            categoryRow

            HStack(spacing: .spacing2x) {
                Image(systemName: "location")
                    .font(.standard(size: .heading, weight: .light))

                BrightText("All Clinics Near Me", size: .body1, color: .semiLightTextColor, weight: .regular)

                Spacer(minLength: .spacing2x)

                sortMenu
            }
            .padding(.leading, .spacing5x)
            .padding(.trailing, .spacing3x)
            .padding(.top, .spacing2x)

            VStack(spacing: .spacing3x) {
                ForEach(clinics) { clinic in
                    VaultClinicCard(clinic: clinic) { onSelectClinic(clinic) }
                }
            }
            .padding(.horizontal, .spacing3x)
        }
        .padding(.bottom, .spacing10x)
        .animation(.brightEaseInOut, value: sortOrder)
    }

    private var categoryRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing2x) {
                ForEach(categories) { category in
                    VaultTestCategoryCard(
                        category: category,
                        clinicCount: VaultTestingClinic.count(offering: category.id)
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
        .mask {
            HStack(spacing: .spacing0x) {
                LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                    .frame(width: Constants.leadingFade)

                Color.black

                LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: Constants.edgeFade)
            }
        }
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
            HStack(spacing: .spacing105x) {
                Image(systemName: order.test.type.systemImage)
                    .font(.standard(size: .heading, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)

                BrightText(order.test.name, size: .heading, color: .semiLightTextColor, weight: .regular)

                Spacer(minLength: .spacing0x)

                BrightChip(title: "Processing", tint: .defaultBlue, fill: .defaultBlue.opacity(.veryMinimalOpacity))
            }

            BrightText(order.clinic.name, size: .body1, weight: .regular)

            BrightText("Ordered \(order.placedAt.formatted(.brightTimestamp))", size: .body1, color: .lightTextColor)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }

    private enum Constants {
        static let edgeFade: CGFloat = .spacing6x
        // Matches the row's content margin, so the first card is untouched at rest.
        static let leadingFade: CGFloat = .spacing3x
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

// MARK: - Category card

private struct VaultTestCategoryCard: View {
    let category: VaultTestCategory
    let clinicCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: .spacing0x) {
                VaultTestCategoryIcon(category: category, symbolSize: .standout1)
                    .foregroundStyle(.white)
                    .blendMode(.overlay)
                    .frame(width: .spacing6x, height: .spacing6x)

                Spacer(minLength: .spacing0x)

                BrightText(category.name, size: .subheading, color: .white, weight: .regular)

                BrightText("\(clinicCount) clinics", size: .body1, color: .white)
                    .blendMode(.overlay)
            }
            .padding(.horizontal, .spacing3x)
            .padding(.vertical, .spacing2x)
            .frame(width: Constants.width, height: Constants.height, alignment: .leading)
            .background {
                Image(category.backgroundName)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(Constants.backgroundOverscan)
                    .blur(radius: Constants.backgroundBlur)
            }
            .overlay(Color.white.opacity(.ultraLowOpacity))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous)
                    .strokeBorder(Color.black.opacity(.minimalOpacity), lineWidth: Constants.stroke)
            }
            .contentShape(RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private enum Constants {
        static let width: CGFloat = 159
        static let height: CGFloat = 107
        static let stroke: CGFloat = 0.5
        static let backgroundBlur: CGFloat = 8
        // Blur feathers the image's edges, so it runs past the clip.
        static let backgroundOverscan: CGFloat = 1.2
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
        VaultGuidedTestingHomeView(orders: [], selectedPage: $page, onSelectClinic: { _ in })
    }
}
