//
//  CardsView.swift
//  Widgets
//

import SwiftUI

struct CardsView: View {
    @State private var wallet = BrightCardWallet()
    @State private var isLoading = true

    var body: some View {
        BrightPageViewV5(title: Constants.title, scrollableTitle: false, horizontalPadding: .spacing0x) {
            content
        }
        .task {
            await wallet.load()
            isLoading = false
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if wallet.cards.isEmpty {
            BrightPlaceholderViewV5(
                systemImage: "creditcard",
                title: Constants.emptyTitle,
                subtitle: Constants.emptySubtitle
            )
        } else {
            List {
                ForEach(wallet.cards) { card in
                    row(card)
                        .listRowBackground(Color.defaultCards)
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await wallet.remove(card) }
                            } label: {
                                Label(Constants.deleteTitle, systemImage: "trash")
                            }
                            .tint(.defaultRed)
                        }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .animation(.brightSnappy, value: wallet.cards.map(\.id))
        }
    }

    private func row(_ card: CardData) -> some View {
        HStack(spacing: .spacing2x) {
            mark(card)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText("\(card.brandName) •••• \(card.last4)", size: .body1, weight: .regular)

                BrightText("Expires \(card.expiry)", size: .body1, color: .lightTextColor)
            }

            Spacer(minLength: .spacing2x)
        }
        .padding(.vertical, .spacing1x)
    }

    @ViewBuilder
    private func mark(_ card: CardData) -> some View {
        if let markName = card.markName {
            Image(markName)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.markSize.width, height: Constants.markSize.height)
        } else {
            Image(systemName: "creditcard")
                .font(.standardSFPro(size: .body1, weight: .regular))
                .foregroundStyle(Color.lightTextColor)
                .frame(width: Constants.markSize.width, height: Constants.markSize.height)
        }
    }

    private enum Constants {
        static let title = "Cards"
        static let deleteTitle = "Delete"
        static let emptyTitle = "No saved cards"
        static let emptySubtitle = "Tick Save this card when you pay and it will be ready for your next order."
        static let markSize = CGSize(width: 35, height: 22)
    }
}

#Preview {
    NavigationStack {
        CardsView()
    }
}
