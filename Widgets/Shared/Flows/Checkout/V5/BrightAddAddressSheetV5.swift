//
//  BrightAddAddressSheetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import MapKit
import SwiftUI

struct BrightAddAddressSheetV5: View {
    // Set to edit a saved address: the fields start filled in and saving
    // keeps its id.
    var editing: BrightShippingAddress?
    var countryCode: String?
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
    @State private var nudges: [RequiredField: Int] = [:]
    @State private var didPrefill = false
    @State private var addressSearch = AddressSearchCompleter()
    @State private var pickedStreet: String?

    private enum RequiredField: CaseIterable {
        case firstName
        case lastName
        case street
        case suburb
        case state
        case postcode
    }

    private func value(of field: RequiredField) -> String {
        switch field {
        case .firstName: firstName
        case .lastName: lastName
        case .street: street
        case .suburb: suburb
        case .state: state
        case .postcode: postcode
        }
    }

    private var missingFields: [RequiredField] {
        RequiredField.allCases.filter { trim(value(of: $0)).isEmpty }
    }

    var body: some View {
        BrightPageSheetViewV5(horizontalPadding: .spacing0x) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing2x) {
                    BrightText(editing == nil ? Constants.title : Constants.editTitle, size: .standout1, weight: .regular)
                        .padding(.bottom, .spacing2x)

                    BrightCountryFieldV5(placeholder: Constants.countryPlaceholder, country: $country)

                    BrightTextFieldV5(
                        Constants.firstNamePlaceholder,
                        editingText: $firstName,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )
                    .brightWiggleV5(trigger: nudges[.firstName, default: 0])

                    BrightTextFieldV5(
                        Constants.lastNamePlaceholder,
                        editingText: $lastName,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )
                    .brightWiggleV5(trigger: nudges[.lastName, default: 0])

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
                    .brightWiggleV5(trigger: nudges[.street, default: 0])
                    .padding(.top, .spacing2x)

                    if !addressSearch.suggestions.isEmpty {
                        suggestionList
                    }

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
                    .brightWiggleV5(trigger: nudges[.suburb, default: 0])

                    BrightTextFieldV5(
                        Constants.statePlaceholder,
                        editingText: $state,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )
                    .brightWiggleV5(trigger: nudges[.state, default: 0])

                    BrightTextFieldV5(
                        Constants.postcodePlaceholder,
                        editingText: $postcode,
                        keyboardType: .numberPad,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )
                    .brightWiggleV5(trigger: nudges[.postcode, default: 0])

                    BrightPhoneFieldV5(
                        placeholder: Constants.phonePlaceholder,
                        number: $phone,
                        country: $phoneCountry
                    )

                    BrightFormToggleRowV5(title: Constants.defaultTitle, isOn: $isDefault)
                        .padding(.top, .spacing2x)
                }
                .padding(.horizontal, .spacing3x)
                .padding(.bottom, .spacing12x)
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .bottom) {
            BrightPillButton(Constants.saveTitle, buttonSize: .large, onTapCallback: save)
                .padding(.bottom, .spacing4x)
        }
        .onAppear(perform: prefill)
        .onChange(of: street) { _, query in
            guard query != pickedStreet else { return }
            addressSearch.update(query: query)
        }
        .animation(.brightSnappy, value: addressSearch.suggestions)
    }

    private var suggestionList: some View {
        VStack(spacing: .spacing0x) {
            ForEach(Array(addressSearch.suggestions.enumerated()), id: \.offset) { offset, suggestion in
                suggestionRow(suggestion)

                if offset != addressSearch.suggestions.count - 1 {
                    BrightDividerV5()
                        .padding(.horizontal, .spacing3x)
                }
            }
        }
        .padding(.vertical, .spacing1x)
        .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))
        .transition(.blurReplace)
    }

    private func suggestionRow(_ suggestion: MKLocalSearchCompletion) -> some View {
        Button {
            select(suggestion)
        } label: {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(suggestion.title, size: .body1)
                    .lineLimit(1)

                if !suggestion.subtitle.isEmpty {
                    BrightText(suggestion.subtitle, size: .body1, color: .lightTextColor)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .spacing3x)
            .padding(.vertical, .spacing105x)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func select(_ suggestion: MKLocalSearchCompletion) {
        addressSearch.clear()
        Task {
            guard let item = try? await MKLocalSearch(request: MKLocalSearch.Request(completion: suggestion))
                .start().mapItems.first else { return }
            fill(from: item.placemark, fallbackStreet: suggestion.title)
        }
    }

    private func fill(from placemark: MKPlacemark, fallbackStreet: String) {
        let line = [placemark.subThoroughfare, placemark.thoroughfare].compactMap(\.self).joined(separator: " ")
        pickedStreet = line.isEmpty ? fallbackStreet : line
        street = pickedStreet ?? ""
        suburb = placemark.locality ?? suburb
        state = placemark.administrativeArea ?? state
        postcode = placemark.postalCode ?? postcode
        if let code = placemark.isoCountryCode, let match = BrightCountry.all.first(where: { $0.code == code }) {
            country = match
        }
    }

    private func prefill() {
        guard !didPrefill else { return }
        didPrefill = true
        if let countryCode, let match = BrightCountry.all.first(where: { $0.code == countryCode }) {
            country = match
            phoneCountry = match
        }
        guard let editing else { return }

        let names = editing.name.split(separator: " ", maxSplits: 1).map(String.init)
        firstName = names.first ?? ""
        lastName = names.count > 1 ? names[1] : ""
        street = editing.line1
        pickedStreet = editing.line1
        unit = editing.line2 ?? ""
        suburb = editing.city
        state = editing.state ?? ""
        postcode = editing.postalCode
        country = BrightCountry.all.first { $0.code == editing.countryCode } ?? .default
        isDefault = editing.isDefault

        // Phone is stored with its dial code in front; split it back out,
        // trying the longest codes first so +61 doesn't match as +6.
        if let phone = editing.phone {
            let match = BrightCountry.all
                .sorted { $0.dialCode.count > $1.dialCode.count }
                .first { phone.hasPrefix($0.dialCode) }
            phoneCountry = match ?? .default
            self.phone = match.map { String(phone.dropFirst($0.dialCode.count)) } ?? phone
        }
    }

    private func save() {
        let missing = missingFields
        guard missing.isEmpty else {
            for field in missing {
                nudges[field, default: 0] += 1
            }
            return
        }

        onSave(
            BrightShippingAddress(
                id: editing?.id ?? UUID().uuidString,
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
        static let editTitle = "Edit Address"
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

@Observable
private final class AddressSearchCompleter: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()

    var suggestions: [MKLocalSearchCompletion] = []

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func update(query: String) {
        let fragment = query.trimmingCharacters(in: .whitespaces)
        guard !fragment.isEmpty else {
            clear()
            return
        }
        completer.queryFragment = fragment
    }

    func clear() {
        completer.cancel()
        suggestions = []
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = Array(completer.results.prefix(5))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}

#Preview {
    BrightAddAddressSheetV5 { _ in }
}
