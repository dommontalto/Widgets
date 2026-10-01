//
//  BrightAddAddressSheetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import SwiftUI

struct BrightAddAddressSheetV5: View {
    let onSave: (BrightShippingAddress) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var country: BrightCountry? = .default
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var company = ""
    @State private var street = ""
    @State private var unit = ""
    @State private var suburb = ""
    @State private var state = ""
    @State private var postcode = ""
    @State private var phone = ""
    @State private var phoneCountry = BrightCountry.default
    @State private var isDefault = false
    @State private var nudge = 0

    private var isComplete: Bool {
        ![firstName, lastName, street, suburb, state, postcode].contains { trim($0).isEmpty }
    }

    var body: some View {
        BrightPageSheetViewV5(horizontalPadding: .spacing0x) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing2x) {
                    BrightText(Constants.title, size: .standout1, weight: .regular)
                        .padding(.bottom, .spacing2x)

                    BrightCountryFieldV5(placeholder: Constants.countryPlaceholder, country: $country)

                    BrightTextFieldV5(
                        Constants.firstNamePlaceholder,
                        editingText: $firstName,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )

                    BrightTextFieldV5(
                        Constants.lastNamePlaceholder,
                        editingText: $lastName,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )

                    BrightTextFieldV5(
                        Constants.companyPlaceholder,
                        editingText: $company,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )

                    BrightTextFieldV5(
                        Constants.streetPlaceholder,
                        editingText: $street,
                        systemImage: "magnifyingglass",
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )
                    .padding(.top, .spacing2x)

                    BrightTextFieldV5(
                        Constants.unitPlaceholder,
                        editingText: $unit,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )

                    BrightTextFieldV5(
                        Constants.suburbPlaceholder,
                        editingText: $suburb,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )

                    BrightTextFieldV5(
                        Constants.statePlaceholder,
                        editingText: $state,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )

                    BrightTextFieldV5(
                        Constants.postcodePlaceholder,
                        editingText: $postcode,
                        keyboardType: .numberPad,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )

                    BrightPhoneFieldV5(
                        placeholder: Constants.phonePlaceholder,
                        number: $phone,
                        country: $phoneCountry
                    )

                    BrightFormToggleRowV5(title: Constants.defaultTitle, isOn: $isDefault)
                        .padding(.top, .spacing2x)
                }
                .brightWiggleV5(trigger: nudge)
                .padding(.horizontal, .spacing3x)
                .padding(.bottom, .spacing12x)
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .bottom) {
            BrightPillButton(Constants.saveTitle, buttonSize: .large, onTapCallback: save)
                .padding(.bottom, .spacing4x)
        }
    }

    private func save() {
        guard isComplete else {
            nudge += 1
            return
        }

        onSave(
            BrightShippingAddress(
                id: UUID().uuidString,
                name: "\(trim(firstName)) \(trim(lastName))",
                street: streetLine,
                line1: trim(street),
                line2: trim(unit).isEmpty ? nil : trim(unit),
                city: trim(suburb),
                state: trim(state),
                postalCode: trim(postcode),
                countryCode: (country ?? .default).code,
                phone: trim(phone).isEmpty ? nil : "\(phoneCountry.dialCode)\(trim(phone))",
                isDefault: isDefault
            )
        )
        dismiss()
    }

    private func trim(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var streetLine: String {
        let line = [trim(unit), trim(street)].filter { !$0.isEmpty }.joined(separator: "/")
        let region = [trim(suburb), trim(state), trim(postcode)].filter { !$0.isEmpty }.joined(separator: " ")
        let country = (country ?? .default).code
        return [line, region, country].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private enum Constants {
        static let title = "Add Address"
        static let saveTitle = "Save Address"
        static let defaultTitle = "Use as my default address"
        static let countryPlaceholder = "Country/Region"
        static let firstNamePlaceholder = "First name"
        static let lastNamePlaceholder = "Last Name"
        static let companyPlaceholder = "Company (optional)"
        static let streetPlaceholder = "Search for address"
        static let unitPlaceholder = "Apartments, suite, etc. (optional)"
        static let suburbPlaceholder = "Suburb"
        static let statePlaceholder = "State/territory"
        static let postcodePlaceholder = "Postcode"
        static let phonePlaceholder = "Phone"
    }
}

#Preview {
    BrightAddAddressSheetV5 { _ in }
}
