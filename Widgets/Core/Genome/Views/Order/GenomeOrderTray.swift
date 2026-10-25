//
//  GenomeOrderTray.swift
//  Widgets
//

import SwiftUI

// Ordering on Genome's Summary while there's nothing ordered, the way Atlas's region tray
// works: the order sheet itself, peeking its top above the bottom until it's drawn up.
struct GenomeOrderTray: View {
    @Bindable var viewModel: GenomeOrderViewModel
    let isExpanded: Bool
    let expand: () -> Void
    let collapse: () -> Void
    let dismiss: () -> Void

    var body: some View {
        sheet
    }

    // The order sheet as it was, with Atlas's pinned ✕ in place of a nav bar.
    private var sheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing0x) {
                    BrightPlaceholderViewV5(
                        image: ImageNames.genomeOrderDnaHeroV5,
                        title: "Order your genome test",
                        subtitle: "Bright has partnered with The Genome Computer Company to provide streamlined access to a Whole Genome Sequence test.",
                        fillsViewport: false
                    )
                    .padding(.bottom, .spacing8x)

                    GenomeOrderIncludedList()
                }
                .padding(.top, .spacing8x)
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(!isExpanded)
            // While it's peeking, the whole of it is the way to draw it up.
            .overlay {
                if !isExpanded {
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture(perform: expand)
                }
            }
            // Folds it down when drawn up; puts it away until Summary is next opened when peeking.
            .overlay(alignment: .topTrailing) {
                BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: isExpanded ? collapse : dismiss)
                    .padding(.top, .spacing3x)
                    .padding(.trailing, .spacing3x)
            }
            .brightBottomButtonV5 {
                GenomeOrderPurchaseButton(viewModel: viewModel)
                    .opacity(isExpanded ? .opaque : .zero)
                    .allowsHitTesting(isExpanded)
                    .animation(.brightEaseInOut, value: isExpanded)
            }
            .toolbar(.hidden, for: .navigationBar)
            // Clear, so the sheet's own background shows through.
            .containerBackground(.clear, for: .navigation)
            .navigationDestination(isPresented: $viewModel.showingCheckout) {
                BrightCheckoutViewV5(item: viewModel.checkoutItem, onPay: viewModel.handlePay)
                    .navigationDestination(isPresented: $viewModel.showingConfirmation) {
                        GenomeOrderConfirmationView(viewModel: viewModel)
                    }
            }
        }
        .environment(\.colorScheme, .dark)
    }
}
