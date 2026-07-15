//
//  GenomeOrderConfirmationSheet.swift
//  Widgets
//

import SwiftUI

struct GenomeOrderConfirmationSheet: View {
    enum ConfirmationState {
        case confirming
        case confirmed
        case pendingWebhook
    }

    @State private var state: ConfirmationState = .confirming
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        BrightPageSheetView(title: "Genome test") {
            VStack(spacing: .spacing0x) {
                switch state {
                case .confirming:
                    VStack(spacing: .spacing2x) {
                        ProgressView()
                            .controlSize(.large)
                            .padding(.bottom, .spacing2x)

                        BrightText("Confirming your order…", size: .subheading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .confirmed:
                    BrightPlaceholderView(
                        image: ImageNames.genomeV5,
                        title: "Your order is confirmed",
                        subtitle: "Your kit is on its way. We'll email you tracking details."
                    )

                case .pendingWebhook:
                    BrightPlaceholderView(
                        image: ImageNames.genomeV5,
                        title: "Payment received",
                        subtitle: "We've received your payment — we'll email you when your kit ships."
                    )
                }

                if state != .confirming {
                    BrightFullWidthButton("Done", color: .defaultGreen) {
                        dismiss()
                    }
                    .padding(.bottom, .spacing3x)
                }
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.brightEaseInOut) { state = .confirmed }
        }
    }

}

#Preview {
    GenomeOrderConfirmationSheet()
}
