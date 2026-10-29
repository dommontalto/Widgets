//
//  BrightCohortRowV5.swift
//  Widgets
//

import SwiftUI

struct BrightCohortRowV5: View {
    @Binding var gender: String
    @Binding var ageRange: String

    static let genderOptions = ["men", "women"]
    static let ageOptions = ["18-24", "25-34", "35-44", "45-54", "55-64", "65+"]

    var body: some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: "person.3.sequence.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.textColor, Color.lightTextColor, Color.textColor.opacity(.semiLowOpacity))
                .font(.standardSFPro(size: .subheading2, weight: .regular))

            BrightText("Cohort:", size: .body2, color: .semiLightTextColor, weight: .regular)
                .lineLimit(1)

            menu(selection: $gender, options: Self.genderOptions) { $0 == "women" ? "Female" : "Male" }

            menu(selection: $ageRange, options: Self.ageOptions) { $0.replacingOccurrences(of: "-", with: "–") }
        }
    }

    private func menu(selection: Binding<String>, options: [String], title: @escaping (String) -> String) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button {
                    selection.wrappedValue = option
                } label: {
                    Label {
                        Text(title(option))
                    } icon: {
                        if option == selection.wrappedValue {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            BrightText(title(selection.wrappedValue), size: .body4, weight: .regular)
                .contentTransition(.numericText())
                .lineLimit(1)
                .padding(.horizontal, .spacing105x)
                .frame(height: BrightButtonSizes.small.rawValue)
                .modifier(BrightGlassEffectV5(shape: .capsule))
                .contentShape(Capsule())
                .animation(.brightBouncy, value: selection.wrappedValue)
        }
        .buttonStyle(.plain)
        .brightHapticV5(.light, trigger: selection.wrappedValue)
    }
}

#Preview {
    BrightCohortRowV5(gender: .constant("men"), ageRange: .constant("25-34"))
        .padding()
        .background(Color.defaultBackground)
}
