//
//  GenomeOrderConfirmationView.swift
//  Widgets
//

import SwiftUI

struct GenomeOrderConfirmationView: View {
    @Bindable var viewModel: GenomeOrderViewModel

    var body: some View {
        BrightPageViewV5(backgroundColor: .defaultSheetBackground) {
            switch viewModel.confirmationState {
            case .confirming, nil:
                VStack(spacing: .spacing2x) {
                    ProgressView()
                        .controlSize(.large)
                        .padding(.bottom, .spacing1x)

                    BrightText("Confirming your order…", size: .subheading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .confirmed:
                BrightPlaceholderViewV5(
                    image: ImageNames.genomeV5,
                    title: "Your order is confirmed",
                    subtitle: "Your kit is on its way. We'll email you tracking details."
                )

            case .pendingWebhook:
                BrightPlaceholderViewV5(
                    image: ImageNames.genomeV5,
                    title: "Payment received",
                    subtitle: "We've received your payment — we'll email you when your kit ships."
                )
            }
        }
        .brightBottomButtonV5 {
            if viewModel.confirmationState != .confirming {
                BrightPillButton("Done", buttonSize: .large) {
                    viewModel.showingOrderSheet = false
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
