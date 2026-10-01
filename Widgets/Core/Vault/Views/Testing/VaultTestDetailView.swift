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
    let onOrder: (VaultTestOrder) -> Void

    @State private var selectedType: VaultTestAvailability
    @State private var showingPayment = false

    private var cardColor: Color {
        isSheet ? .defaultSheetModalCards : .defaultCards
    }

    init(
        test: VaultClinicTest,
        clinic: VaultTestingClinic,
        isSheet: Bool = true,
        onOrder: @escaping (VaultTestOrder) -> Void
    ) {
        self.test = test
        self.clinic = clinic
        self.isSheet = isSheet
        self.onOrder = onOrder
        _selectedType = State(initialValue: test.type)
    }

    var body: some View {
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
        .overlay(alignment: .bottom) {
            BrightPillButton("Order", systemImage: "cart.badge.plus", buttonSize: .large) {
                showingPayment = true
            }
            .padding(.bottom, .spacing4x)
        }
        .navigationDestination(isPresented: $showingPayment) {
            BrightCheckoutViewV5(item: test.checkoutItem(type: selectedType, clinic: clinic)) { details in
                showingPayment = false
                onOrder(VaultTestOrder(test: test, clinic: clinic, type: selectedType, details: details))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(test.name, size: .standout3, weight: .regular)

            BrightText(test.detail, size: .body1, color: .lightTextColor)
                .lineSpacing(.lineSpacingMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, .spacing2x)
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
                    HStack(spacing: .spacing1x) {
                        Image(systemName: "checkmark.circle")
                            .font(.standardSFPro(size: .standout3, weight: .light))
                            .foregroundStyle(Color.defaultGreen)

                        BrightText(item, size: .body1, color: .semiLightTextColor)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("Test Type", size: .body1, color: .semiLightTextColor, weight: .regular)
                .padding(.leading, .spacing1x)

            VStack(spacing: .spacing0x) {
                ForEach(test.availability) { availability in
                    typeRow(availability, isLast: availability == test.availability.last)
                }
            }
            .padding(.horizontal, .spacing3x)
            .padding(.vertical, .spacing105x)
            .modifier(BrightCardModifierV5(color: cardColor, cornerRadius: .cornerRadius24))
        }
    }

    private func typeRow(_ availability: VaultTestAvailability, isLast: Bool) -> some View {
        VStack(spacing: .spacing0x) {
            Button {
                selectedType = availability
            } label: {
                HStack(spacing: .spacing1x) {
                    Image(systemName: availability.systemImage)
                        .font(.standardSFPro(size: .body1, weight: .regular))
                        .foregroundStyle(Color.textColor)
                        .frame(width: Constants.iconSize, height: Constants.iconSize)
                        .background(isSheet ? Color.defaultSheetBackground : Color.defaultBackground, in: Circle())

                    BrightText(availability.rawValue, size: .body1)

                    Spacer(minLength: .spacing0x)

                    BrightTickV5(isTicked: availability == selectedType)
                }
                .padding(.vertical, .spacing2x)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isLast {
                BrightDividerV5()
            }
        }
    }

    private enum Constants {
        static let iconSize: CGFloat = 32
    }
}

#Preview {
    NavigationStack {
        VaultTestDetailView(test: VaultTestingClinic.demo[0].tests[0], clinic: VaultTestingClinic.demo[0]) { _ in }
    }
}
