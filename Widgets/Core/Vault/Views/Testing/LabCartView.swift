//
//  LabCartView.swift
//  Widgets
//

import SwiftUI

struct LabCartView: View {
    let clinic: VaultTestingClinic
    var isSheet = true
    let onOrder: (VaultTestOrder) -> Void

    @State private var quote: EirlyQuote?
    @State private var quoteFailed = false
    @State private var showingDetails = false

    private let cart = LabCart.shared
    private let service: LabOrdersServiceProtocol = LabOrdersMockService()

    private var cardColor: Color {
        isSheet ? .defaultSheetModalCards : .defaultCards
    }

    private var tests: [VaultClinicTest] {
        cart.items.map { item in
            clinic.tests.first { $0.labTestId == item.labTestId } ?? VaultClinicTest(
                id: item.testId,
                name: item.name,
                detail: "",
                categoryId: "",
                included: [item.name],
                availability: [.inPerson],
                price: item.price,
                currency: Constants.currency,
                labTestId: item.labTestId,
                labProvider: .eirly
            )
        }
    }

    var body: some View {
        BrightPageViewV5(
            title: Constants.title,
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: isSheet ? .defaultSheetBackground : .defaultBackground
        ) {
            if cart.items.isEmpty {
                BrightPlaceholderViewV5(
                    systemImage: "cart",
                    title: Constants.emptyTitle,
                    subtitle: Constants.emptySubtitle
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing3x) {
                        BrightText(Constants.subtitle, size: .body1, color: .lightTextColor)
                            .lineSpacing(.lineSpacingMedium)
                            .fixedSize(horizontal: false, vertical: true)

                        itemsCard
                        quoteCard
                    }
                    .padding(.horizontal, .spacing3x)
                    .padding(.bottom, .spacing12x)
                }
                .scrollIndicators(.hidden)
            }
        }
        .brightBottomButtonV5 {
            if !cart.items.isEmpty {
                BrightPillButton(
                    quote.map { "\(Constants.continueTitle) · \($0.totalText)" } ?? Constants.continueTitle,
                    systemImage: "arrow.right",
                    buttonSize: .large
                ) {
                    showingDetails = true
                }
            }
        }
        .navigationDestination(isPresented: $showingDetails) {
            LabPatientDetailsView(tests: tests, clinic: clinic) { order in
                cart.clear()
                onOrder(order)
            }
        }
        .animation(.brightSnappy, value: cart.items)
        .animation(.brightEaseInOut, value: quote)
        .task(id: cart.labTestIds) { await loadQuote() }
    }

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("\(cart.items.count) of \(LabCart.maxItems) tests", size: .body1, color: .lightTextColor)
                .monospacedDigit()

            ForEach(Array(cart.items.enumerated()), id: \.element.id) { index, item in
                VStack(alignment: .leading, spacing: .spacing2x) {
                    HStack(spacing: .spacing2x) {
                        BrightText(item.name, size: .body1, color: .semiLightTextColor)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: .spacing2x)

                        BrightRoundButton(systemImage: "xmark", size: .small) {
                            cart.remove(item)
                        }
                    }

                    if index < cart.items.count - 1 {
                        BrightDividerV5()
                    }
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5(color: cardColor))
    }

    @ViewBuilder
    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            if let quote {
                ForEach(Array(quote.lines.enumerated()), id: \.offset) { _, line in
                    priceRow(line.label, value: EirlyQuote.text(line.amount, currency: quote.currency))
                }

                BrightDividerV5()

                priceRow(Constants.totalTitle, value: quote.totalText, weight: .regular)
            } else if quoteFailed {
                BrightText(Constants.quoteError, size: .body1, color: .defaultRed)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5(color: cardColor))
    }

    private func priceRow(_ label: String, value: String, weight: Font.Weight = .light) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing2x) {
            BrightText(label, size: .body1, color: .semiLightTextColor, weight: weight)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: .spacing2x)

            BrightText(value, size: .body1, weight: weight)
                .monospacedDigit()
        }
    }

    private func loadQuote() async {
        let ids = cart.labTestIds
        quote = nil
        quoteFailed = false
        guard !ids.isEmpty else { return }
        do {
            let priced = try await service.getEirlyQuote(tests: ids)
            guard ids == cart.labTestIds else { return }
            quote = priced
        } catch {
            guard !Task.isCancelled else { return }
            Log("Labs: Eirly quote failed – \(error)")
            quoteFailed = true
        }
    }

    private enum Constants {
        static let title = "Cart"
        static let subtitle = "Collection and service fees are charged once per order, so add every test you want before you pay."
        static let emptyTitle = "Your cart is empty"
        static let emptySubtitle = "Add Australian pathology tests to order them together."
        static let continueTitle = "Continue"
        static let totalTitle = "Total (incl. GST)"
        static let quoteError = "Couldn't price these tests. Try again shortly."
        static let currency = "AUD"
    }
}

struct LabCartButton: View {
    let action: () -> Void

    private let cart = LabCart.shared

    var body: some View {
        Button(action: action) {
            Label("Cart (\(cart.items.count))", systemImage: cart.items.isEmpty ? "cart" : "cart.fill")
                .labelStyle(.iconOnly)
        }
    }
}
