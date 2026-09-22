//
//  VaultAddAddressSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import SwiftUI

struct VaultAddAddressSheet: View {
    let onSave: (VaultShippingAddress) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var country: VaultCountry? = .default
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var company = ""
    @State private var street = ""
    @State private var unit = ""
    @State private var suburb = ""
    @State private var state = ""
    @State private var postcode = ""
    @State private var phone = ""
    @State private var phoneCountry = VaultCountry.default
    @State private var isDefault = false
    @State private var nudge = 0

    private var isComplete: Bool {
        ![firstName, lastName, street, suburb, state, postcode].contains { trim($0).isEmpty }
    }

    var body: some View {
        BrightPageSheetView(horizontalPadding: .spacing0x) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing2x) {
                    BrightText(Constants.title, size: .standout1, weight: .regular)
                        .padding(.bottom, .spacing2x)

                    VaultCountryField(placeholder: Constants.countryPlaceholder, country: $country)

                    VaultFormField(placeholder: Constants.firstNamePlaceholder, text: $firstName)

                    VaultFormField(placeholder: Constants.lastNamePlaceholder, text: $lastName)

                    VaultFormField(placeholder: Constants.companyPlaceholder, text: $company)

                    VaultFormField(
                        placeholder: Constants.streetPlaceholder,
                        text: $street,
                        systemImage: "magnifyingglass"
                    )
                    .padding(.top, .spacing2x)

                    VaultFormField(placeholder: Constants.unitPlaceholder, text: $unit)

                    VaultFormField(placeholder: Constants.suburbPlaceholder, text: $suburb)

                    VaultFormField(placeholder: Constants.statePlaceholder, text: $state)

                    VaultFormField(
                        placeholder: Constants.postcodePlaceholder,
                        text: $postcode,
                        keyboardType: .numberPad
                    )

                    VaultPhoneField(
                        placeholder: Constants.phonePlaceholder,
                        number: $phone,
                        country: $phoneCountry
                    )

                    VaultFormToggleRow(title: Constants.defaultTitle, isOn: $isDefault)
                        .padding(.top, .spacing2x)
                }
                .brightWiggle(trigger: nudge)
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
            VaultShippingAddress(
                id: UUID().uuidString,
                name: "\(trim(firstName)) \(trim(lastName))",
                street: streetLine
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
    VaultAddAddressSheet { _ in }
}
