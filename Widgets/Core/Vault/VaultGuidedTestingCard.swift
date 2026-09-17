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
        VStack(spacing: .spacing0x) {
            banner
            footer
        }
        .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
        .onTapGesture { onTap() }
    }

    private var banner: some View {
        Color.clear
            .frame(height: Constants.bannerHeight)
            .background {
                Image(ImageNames.vaultGuidedTestingBannerV5)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .overlay {
                HStack(spacing: .spacing105x) {
                    Image(systemName: "heart.text.square")
                        .font(.standard(size: .standout2, weight: .light))
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
                size: .body1,
                color: .semiLightTextColor
            )
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: .spacing2x)

            Image(systemName: "chevron.forward.circle")
                .font(.standard(size: .heading, weight: .light))
                .foregroundStyle(Color.textColor)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.defaultCards)
    }

    private enum Constants {
        static let bannerHeight: CGFloat = 160
    }
}

#Preview {
    VaultGuidedTestingCard()
        .padding(.spacing3x)
        .background(Color.defaultBackground.ignoresSafeArea())
}
