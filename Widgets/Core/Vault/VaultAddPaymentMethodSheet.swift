//
//  VaultAddPaymentMethodSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import SwiftUI

struct VaultAddPaymentMethodSheet: View {
    let onSave: (VaultPaymentMethod) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var number = ""
    @State private var expiry = ""
    @State private var securityCode = ""
    @State private var name = ""
    @State private var billing: VaultShippingAddress?
    @State private var isDefault = false
    @State private var isAddingAddress = false
    @State private var nudge = 0

    private var isComplete: Bool {
        ![number, expiry, securityCode, name].contains { trim($0).isEmpty }
    }

    var body: some View {
        BrightPageSheetView(horizontalPadding: .spacing0x) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing2x) {
                    BrightText(Constants.title, size: .standout1, weight: .regular)
                        .padding(.bottom, .spacing2x)

                    VaultFormField(
                        placeholder: Constants.numberPlaceholder,
                        text: $number,
                        keyboardType: .numberPad,
                        capitalization: .never
                    )

                    VaultFormField(
                        placeholder: Constants.expiryPlaceholder,
                        text: $expiry,
                        keyboardType: .numbersAndPunctuation,
                        capitalization: .never
                    )

                    VaultFormField(
                        placeholder: Constants.securityPlaceholder,
                        text: $securityCode,
                        keyboardType: .numberPad,
                        capitalization: .never
                    )

                    VaultFormField(placeholder: Constants.namePlaceholder, text: $name)

                    billingCard
                        .padding(.top, .spacing2x)

                    VaultFormToggleRow(title: Constants.defaultTitle, isOn: $isDefault)
                        .padding(.top, .spacing2x)
                }
                .brightWiggle(trigger: nudge)
                .padding(.horizontal, .spacing3x)
                .padding(.bottom, .spacing12x)
            }
            .scrollIndicators(.hidden)
            .sheet(isPresented: $isAddingAddress) {
                VaultAddAddressSheet { billing = $0 }
            }
        }
        .overlay(alignment: .bottom) {
            BrightPillButton(Constants.saveTitle, buttonSize: .large, onTapCallback: save)
                .padding(.bottom, .spacing4x)
        }
    }

    private var billingCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(Constants.billingTitle, size: .body1, color: .semiLightTextColor, weight: .regular)

            BrightDivider()

            Button {
                isAddingAddress = true
            } label: {
                HStack(spacing: .spacing2x) {
                    BrightRoundButton(systemImage: "plus", haptic: nil)
                        .allowsHitTesting(false)

                    if let billing {
                        VStack(alignment: .leading, spacing: .spacing05x) {
                            BrightText(billing.name, size: .body1, weight: .regular)

                            BrightText(billing.street, size: .body1, color: .lightTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        BrightText(Constants.addAddressTitle, size: .body1, color: .lightTextColor)
                    }

                    Spacer(minLength: .spacing2x)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private func save() {
        guard isComplete else {
            nudge += 1
            return
        }

        onSave(
            VaultPaymentMethod(
                id: UUID().uuidString,
                name: trim(name),
                markName: ImageNames.paymentMastercardV5,
                markSize: Constants.markSize,
                last4: last4,
                billing: billing.map { "\($0.name), \($0.street)" }
            )
        )
        dismiss()
    }

    private var last4: String? {
        let digits = number.filter(\.isNumber)
        guard digits.count >= Constants.last4Count else { return nil }
        return String(digits.suffix(Constants.last4Count))
    }

    private func trim(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private enum Constants {
        static let title = "Add Payment Method"
        static let saveTitle = "Save Card"
        static let billingTitle = "Bill to"
        static let addAddressTitle = "Add an address"
        static let defaultTitle = "Use as my default payment method"
        static let numberPlaceholder = "Card Number"
        static let expiryPlaceholder = "Expiry date (MM/YY)"
        static let securityPlaceholder = "Security Code"
        static let namePlaceholder = "Name on card"
        static let markSize = CGSize(width: 35, height: 22)
        static let last4Count = 4
    }
}

#Preview {
    VaultAddPaymentMethodSheet { _ in }
}
