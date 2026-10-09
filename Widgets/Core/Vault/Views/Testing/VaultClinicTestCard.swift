//
//  VaultClinicTestCard.swift
//  Widgets
//

import SwiftUI

struct VaultClinicTestCard: View {
    let test: VaultClinicTest
    var color: Color = .defaultSheetModalCards
    let onTap: () -> Void

    private let cart = LabCart.shared

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing105x) {
                Image(systemName: test.type.systemImage)
                    .font(.standard(size: .heading, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)

                BrightText(test.name, size: .heading, color: .semiLightTextColor, weight: .regular)

                Spacer(minLength: .spacing0x)

                BrightRoundButton(systemImage: "chevron.right", size: .small, onTapCallback: onTap)
            }

            HStack(spacing: .spacing1x) {
                ForEach(test.availability) { availability in
                    BrightChipV5(
                        title: availability.rawValue,
                        tint: availability.tint,
                        fill: availability.tint.opacity(.veryMinimalOpacity)
                    )
                }

                if cart.contains(test) {
                    BrightChipV5(
                        title: "In Cart",
                        systemImage: "cart.fill",
                        tint: .defaultGreen,
                        fill: Color.defaultGreen.opacity(.veryMinimalOpacity)
                    )
                }

                Spacer(minLength: .spacing0x)

                BrightText(test.priceText, size: .body1, weight: .regular)
                    .monospacedDigit()
            }

            BrightDividerV5()

            BrightText(test.detail, size: .body1, color: .lightTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5(color: color))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
