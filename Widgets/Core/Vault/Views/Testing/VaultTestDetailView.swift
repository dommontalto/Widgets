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
    let onOrder: (VaultTestOrder) -> Void

    @State private var selectedType: VaultTestAvailability
    @State private var showingPayment = false

    init(test: VaultClinicTest, clinic: VaultTestingClinic, onOrder: @escaping (VaultTestOrder) -> Void) {
        self.test = test
        self.clinic = clinic
        self.onOrder = onOrder
        _selectedType = State(initialValue: test.type)
    }

    var body: some View {
        BrightPageView(horizontalPadding: .spacing0x, backgroundColor: .defaultSheetBackground) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing3x) {
                    header
                    includedTitle
                    includedCard
                    typeCard
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
            VaultTestPaymentView(test: test, type: selectedType, clinic: clinic) { order in
                showingPayment = false
                onOrder(order)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            BrightText(test.name, size: .standout1, weight: .regular)

            BrightText(test.detail, size: .body1, color: .lightTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, .spacing2x)
    }

    private var includedTitle: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "checklist")
                .font(.standard(size: .heading, weight: .light))

            BrightText("What's included", size: .body1, color: .semiLightTextColor, weight: .regular)
        }
        .padding(.leading, .spacing2x)
    }

    private var includedCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            ForEach(test.included, id: \.self) { item in
                HStack(spacing: .spacing1x) {
                    Image(systemName: "checkmark.rectangle.stack")
                        .font(.standard(size: .body1, weight: .light))
                        .foregroundStyle(Color.semiLightTextColor)

                    BrightText(item, size: .body1, color: .semiLightTextColor, weight: .regular)
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private var typeCard: some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: selectedType.systemImage)
                .font(.standard(size: .heading, weight: .light))
                .foregroundStyle(Color.semiLightTextColor)
                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))

            BrightText("Test Type", size: .body1, weight: .regular)

            Spacer(minLength: .spacing0x)

            typeMenu
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .defaultSheetModalCards))
        .animation(.brightEaseInOut, value: selectedType)
        .brightHaptic(.light, trigger: selectedType)
    }

    private var typeMenu: some View {
        Menu {
            ForEach(test.availability) { availability in
                Button {
                    selectedType = availability
                } label: {
                    Label {
                        Text(availability.rawValue)
                    } icon: {
                        if availability == selectedType {
                            Image(systemName: "checkmark")
                        } else {
                            Image(systemName: availability.systemImage)
                        }
                    }
                }
            }
        } label: {
            BrightPillButton(selectedType.rawValue, buttonSize: .small) {}
                .allowsHitTesting(false)
        }
    }
}

#Preview {
    NavigationStack {
        VaultTestDetailView(test: VaultTestingClinic.demo[0].tests[0], clinic: VaultTestingClinic.demo[0]) { _ in }
    }
}
