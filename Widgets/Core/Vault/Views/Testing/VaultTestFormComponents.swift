//
//  VaultTestFormComponents.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import SwiftUI

struct VaultFormField: View {
    let placeholder: String
    @Binding var text: String
    var systemImage: String?
    var keyboardType: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .words

    var body: some View {
        HStack(spacing: .spacing2x) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.standard(size: .heading, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)
            }

            TextField(placeholder, text: $text)
                .font(.standard(size: .body1, weight: .regular))
                .foregroundStyle(Color.textColor)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(capitalization)
                .dynamicTypeSize(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .modifier(VaultFormFieldBackground())
    }
}

struct VaultCountryField: View {
    let placeholder: String
    @Binding var country: VaultCountry?

    var body: some View {
        VaultCountryMenu(country: countrySelection, showsDialCodes: false) {
            HStack(spacing: .spacing2x) {
                if let country {
                    BrightText("\(country.flag)  \(country.name)", size: .body1, weight: .regular)
                } else {
                    BrightText(placeholder, size: .body1, color: .lightTextColor, weight: .regular)
                }

                Spacer(minLength: .spacing2x)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.standard(size: .body1, weight: .regular))
                    .foregroundStyle(Color.semiLightTextColor)
            }
            .modifier(VaultFormFieldBackground())
        }
    }

    private var countrySelection: Binding<VaultCountry> {
        Binding(
            get: { country ?? .default },
            set: { country = $0 }
        )
    }
}

struct VaultPhoneField: View {
    let placeholder: String
    @Binding var number: String
    @Binding var country: VaultCountry

    var body: some View {
        HStack(spacing: .spacing2x) {
            BrightText(country.dialCode, size: .body1, color: .lightTextColor, weight: .regular)
                .monospacedDigit()

            TextField(placeholder, text: $number)
                .font(.standard(size: .body1, weight: .regular))
                .foregroundStyle(Color.textColor)
                .keyboardType(.phonePad)
                .dynamicTypeSize(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)

            VaultCountryMenu(country: $country) {
                HStack(spacing: .spacing1x) {
                    BrightText(country.flag, size: .body1)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.standard(size: .body1, weight: .regular))
                        .foregroundStyle(Color.semiLightTextColor)
                }
                .contentShape(Rectangle())
            }
        }
        .modifier(VaultFormFieldBackground())
    }
}

struct VaultCountryMenu<Content: View>: View {
    @Binding var country: VaultCountry
    var showsDialCodes = true
    @ViewBuilder let label: () -> Content

    var body: some View {
        Menu {
            ForEach(VaultCountry.all) { option in
                Button {
                    country = option
                } label: {
                    Label {
                        Text(title(for: option))
                    } icon: {
                        if option == country {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .brightHaptic(.light, trigger: country)
    }

    private func title(for option: VaultCountry) -> String {
        guard showsDialCodes else { return "\(option.flag)  \(option.name)" }
        return "\(option.flag)  \(option.name)  \(option.dialCode)"
    }
}

struct VaultFormToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: .spacing2x) {
            BrightText(title, size: .body1, weight: .regular)

            Spacer(minLength: .spacing2x)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.defaultGreen)
                .brightHaptic(.light, trigger: isOn)
        }
        .padding(.horizontal, .spacing2x)
    }
}

struct VaultFormFieldBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, .spacing3x)
            .frame(height: Constants.height)
            .background(Color.defaultSheetModalCards)
            .clipShape(.capsule)
    }

    private enum Constants {
        static let height: CGFloat = .spacing8x
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @State var country: VaultCountry? = .default
    @Previewable @State var phoneCountry = VaultCountry.default
    @Previewable @State var isOn = false

    VStack(spacing: .spacing2x) {
        VaultCountryField(placeholder: "Country/Region", country: $country)
        VaultFormField(placeholder: "First name", text: $text)
        VaultFormField(placeholder: "Search for address", text: $text, systemImage: "magnifyingglass")
        VaultPhoneField(placeholder: "Phone", number: $text, country: $phoneCountry)
        VaultFormToggleRow(title: "Use as my default address", isOn: $isOn)
    }
    .padding(.spacing3x)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultSheetBackground)
}
