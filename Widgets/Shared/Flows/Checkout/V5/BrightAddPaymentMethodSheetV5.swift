//
//  BrightAddPaymentMethodSheetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import SwiftUI

struct BrightAddPaymentMethodSheetV5: View {
    let onSave: (BrightPaymentMethod) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var number = ""
    @State private var expiry = ""
    @State private var securityCode = ""
    @State private var name = ""
    @State private var billing: BrightShippingAddress?
    @State private var isDefault = false
    @State private var isAddingAddress = false
    @State private var nudge = 0

    private var isComplete: Bool {
        ![number, expiry, securityCode, name].contains { trim($0).isEmpty }
    }

    var body: some View {
        BrightPageSheetViewV5(horizontalPadding: .spacing0x) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing2x) {
                    BrightText(Constants.title, size: .standout1, weight: .regular)
                        .padding(.bottom, .spacing2x)

                    BrightTextFieldV5(
                        Constants.numberPlaceholder,
                        editingText: $number,
                        keyboardType: .numberPad,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .never
                    )

                    BrightTextFieldV5(
                        Constants.expiryPlaceholder,
                        editingText: $expiry,
                        keyboardType: .numbersAndPunctuation,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .never
                    )

                    BrightTextFieldV5(
                        Constants.securityPlaceholder,
                        editingText: $securityCode,
                        keyboardType: .numberPad,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .never
                    )

                    BrightTextFieldV5(
                        Constants.namePlaceholder,
                        editingText: $name,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )

                    billingCard
                        .padding(.top, .spacing2x)

                    BrightFormToggleRowV5(title: Constants.defaultTitle, isOn: $isDefault)
                        .padding(.top, .spacing2x)
                }
                .brightWiggleV5(trigger: nudge)
                .padding(.horizontal, .spacing3x)
                .padding(.bottom, .spacing12x)
            }
            .scrollIndicators(.hidden)
            .sheet(isPresented: $isAddingAddress) {
                BrightAddAddressSheetV5 { billing = $0 }
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

            BrightDividerV5()

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
        .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))
    }

    private func save() {
        guard isComplete else {
            nudge += 1
            return
        }

        onSave(
            BrightPaymentMethod(
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
    BrightAddPaymentMethodSheetV5 { _ in }
}
