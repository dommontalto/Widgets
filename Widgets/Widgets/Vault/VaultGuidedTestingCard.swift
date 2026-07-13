//
//  VaultGuidedTestingCard.swift
//  Widgets
//
//  Created by Dom Montalto on 8/7/2026.
//

import SwiftUI

struct VaultGuidedTestingCard: View {
    var onTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            banner
            footer
        }
        .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
        .onTapGesture { onTap() }
    }

    private var banner: some View {
        Color.clear
            .frame(height: 160)
            .background {
                Image(ImageNames.vaultGuidedTestingBannerV5)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .overlay {
            HStack(spacing: .spacing105x) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(.white)

                BrightText("Guided Testing", size: .huge3, color: .white)
            }
            .blendMode(.overlay)
        }
    }

    private var footer: some View {
        HStack(spacing: .spacing2x) {
            BrightText(
                "Order or book a test today and bring your results onto the app.",
                size: .body2,
                color: .semiLightTextColor
            )
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: .spacing2x)

            Image(systemName: "chevron.forward.circle")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color.textColor)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cards)
    }
}

#Preview {
    VaultGuidedTestingCard()
        .padding(.spacing3x)
        .background(Color.bG.ignoresSafeArea())
}
