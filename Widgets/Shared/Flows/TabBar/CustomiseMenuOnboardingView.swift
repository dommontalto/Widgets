//
//  CustomiseMenuOnboardingView.swift
//  Widgets
//
//  Created by Amin Zabihi on 30/12/2025.
//

import SwiftUI

struct CustomiseMenuOnboardingView: View {
    @Bindable var viewModel: CustomiseMenuOnboardingViewModel

    var body: some View {
        BrightPageViewV5(
            horizontalPadding: .spacing0x,
            content: { content }
        )
        .brightBottomButtonV5 {
            BrightPillButton("Continue", buttonSize: .large) {
                viewModel.handleContinueTapped()
            }
        }
    }

    private var content: some View {
        VStack(spacing: .spacing0x) {
            VStack {
                Image(ImageNames.templateIcon)
                    .padding(.bottom, .spacing2x)
            }
            .frame(maxWidth: .infinity)

            BrightText(
                viewModel.title,
                size: .standout2,
                color: .semiLightTextColor
            )
            .padding(.top, .spacing2x)

            BrightText(
                viewModel.subtitle,
                size: .body2,
                color: .lightTextColor
            )
            .multilineTextAlignment(.center)
            .lineSpacing(.lineSpacingMedium)
            .padding(.horizontal, .spacing3x)
            .padding(.top, .spacing3x)
        }
        .padding(.top, Constants.topContentPadding)
    }
}

private enum Constants {
    static let topContentPadding: CGFloat = 160
}
