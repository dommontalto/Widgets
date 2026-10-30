//
//  VaultTestDetailView.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import SwiftUI

struct VaultTestDetailView: View {
    let test: VaultClinicTest
    let clinic: VaultTestingClinic
    let isSheet: Bool
    let style: VaultTestCategory?
    let onOrder: (VaultTestOrder) -> Void

    @State private var selectedType: VaultTestAvailability
    @State private var showingPayment = false
    @State private var showingCart = false
    @State private var pull: CGFloat = 0

    private let cart = LabCart.shared
    private let catalog = LabCatalog.shared

    private var cardColor: Color {
        isSheet ? .defaultSheetModalCards : .defaultCards
    }

    init(
        test: VaultClinicTest,
        clinic: VaultTestingClinic,
        isSheet: Bool = true,
        style: VaultTestCategory? = nil,
        onOrder: @escaping (VaultTestOrder) -> Void
    ) {
        self.test = test
        self.clinic = clinic
        self.isSheet = isSheet
        self.style = style
        self.onOrder = onOrder
        _selectedType = State(initialValue: test.type)
    }

    var body: some View {
        page
            .brightBottomButtonV5 {
                orderButton
            }
            .navigationDestination(isPresented: $showingPayment) {
                if test.labTestId != nil {
                    LabPatientDetailsView(tests: [test], clinic: clinic, onOrder: onOrder)
                } else {
                    BrightCheckoutViewV5(item: test.checkoutItem(type: selectedType, clinic: clinic)) { details in
                        showingPayment = false
                        onOrder(VaultTestOrder(test: test, clinic: clinic, type: selectedType, details: details))
                    }
                }
            }
            .navigationDestination(isPresented: $showingCart) {
                LabCartView(clinic: clinic, isSheet: isSheet, onOrder: onOrder)
            }
            .brightHapticV5(trigger: cart.items.count) { old, new in
                new > old ? .success : .light
            }
    }

    @ViewBuilder
    private var page: some View {
        if let style {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing3x) {
                    VaultTestHero(
                        category: style,
                        title: test.name,
                        subtitle: "\(test.included.count) \(test.included.count == 1 ? "test" : "tests")",
                        pull: pull
                    )

                    VStack(alignment: .leading, spacing: .spacing3x) {
                        detail
                        price
                        BrightDividerV5()
                        included
                        BrightDividerV5()
                        typeSection
                    }
                    .padding(.horizontal, .spacing3x)
                }
                .padding(.bottom, .spacing12x)
            }
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, offset in
                pull = max(0, -offset)
            }
            .brightSoftScrollEdgesV5()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.defaultBackground.ignoresSafeArea())
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        } else {
            BrightPageViewV5(
                horizontalPadding: .spacing0x,
                backgroundColor: isSheet ? .defaultSheetBackground : .defaultBackground
            ) {
                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing3x) {
                        header
                        BrightDividerV5()
                        included
                        BrightDividerV5()
                        typeSection
                    }
                    .padding(.horizontal, .spacing3x)
                    .padding(.bottom, .spacing12x)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    @ViewBuilder
    private var orderButton: some View {
        if let provider = test.labProvider, !catalog.canOrder(provider) {
            BrightPillButton(Constants.comingSoon, systemImage: "clock", buttonSize: .large) {}
                .disabled(true)
                .opacity(.lowOpacity)
        } else {
            availableOrderButton
        }
    }

    @ViewBuilder
    private var availableOrderButton: some View {
        switch test.labProvider {
        case .junction, nil:
            BrightPillButton("Order", systemImage: "cart.badge.plus", buttonSize: .large) {
                showingPayment = true
            }
        case .eirly:
            if cart.contains(test) || cart.isFull {
                BrightPillButton("View Cart", systemImage: "cart", buttonSize: .large) {
                    showingCart = true
                }
            } else {
                BrightPillButton("Add to Cart", systemImage: "cart.badge.plus", buttonSize: .large) {
                    cart.add(test)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(test.name, size: .standout3, weight: .regular)
            detail
            price
        }
        .padding(.top, .spacing2x)
    }

    private var detail: some View {
        BrightText(test.detail, size: .body1, color: .lightTextColor)
            .lineSpacing(.lineSpacingMedium)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var price: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
            BrightText(test.priceText, size: .subheading1, weight: .regular)
                .monospacedDigit()

            if let note = test.priceNote {
                BrightText(note, size: .body1, color: .lightTextColor)
            }
        }
    }

    private var included: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightText("What’s included?", size: .body1, color: .semiLightTextColor, weight: .regular)

            LazyVGrid(
                columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
                alignment: .leading,
                spacing: .spacing105x
            ) {
                ForEach(test.included, id: \.self) { item in
                    HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                        Image(systemName: "checkmark.circle")
                            .font(.standardSFPro(size: .standout3, weight: .light))
                            .foregroundStyle(Color.defaultGreen)

                        BrightText(item, size: .body1, color: .semiLightTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var typeSection: some View {
        BrightRowGroupV5(header: "Test Type", color: cardColor) {
            ForEach(test.availability) { availability in
                BrightRowV5(
                    availability.rawValue,
                    icon: .symbol(availability.systemImage),
                    trailing: .tick(availability == selectedType)
                ) {
                    selectedType = availability
                }
            }
        }
    }

    private enum Constants {
        static let comingSoon = "Coming soon"
    }
}

#Preview {
    NavigationStack {
        VaultTestDetailView(test: VaultTestingClinic.demo[0].tests[0], clinic: VaultTestingClinic.demo[0]) { _ in }
    }
}
