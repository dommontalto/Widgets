//
//  BrightReceiptSheetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import SwiftUI

struct BrightReceiptSheetV5: View {
    let order: VaultTestOrder

    var body: some View {
        BrightPageSheetViewV5(horizontalPadding: .spacing0x) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing3x) {
                    header
                    detailsCard
                    totalCard
                }
                .padding(.horizontal, .spacing3x)
                .padding(.bottom, .spacing12x)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText(Constants.title, size: .standout1, weight: .regular)

            BrightText(order.reference, size: .subheading, weight: .regular)

            BrightText(order.placedAt.formatted(.brightDate), size: .body1, color: .lightTextColor)
        }
        .padding(.top, .spacing2x)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            labelledRow(Constants.clinicTitle) {
                BrightText(order.clinic.name, size: .body1, weight: .regular)
            }

            BrightDividerV5()

            labelledRow(Constants.testTitle) {
                BrightText(order.test.name, size: .body1, weight: .regular)
            }

            BrightDividerV5()

            labelledRow(Constants.typeTitle) {
                HStack(spacing: .spacing1x) {
                    Image(systemName: order.type.systemImage)
                        .font(.standard(size: .body1, weight: .light))
                        .foregroundStyle(Color.semiLightTextColor)

                    BrightText(order.type.rawValue, size: .body1, weight: .regular)
                }
            }

            BrightDividerV5()

            BrightText(order.test.detail, size: .body1, color: .lightTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))
    }

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing2x) {
                BrightText(Constants.totalTitle, size: .body1, weight: .regular)

                Spacer(minLength: .spacing2x)

                BrightChipV5(title: order.test.currency, tint: .defaultBlue, fill: .defaultBlue.opacity(.veryMinimalOpacity))

                BrightText(order.test.priceText, size: .body1, weight: .regular)
                    .monospacedDigit()
            }

            BrightDividerV5()

            BrightText(Constants.paymentTitle, size: .body1, weight: .regular)

            if let method = order.paymentMethod {
                HStack(spacing: .spacing2x) {
                    Group {
                        if let markImage = method.markImage {
                            Image(uiImage: markImage)
                                .resizable()
                        } else {
                            Image(method.markName)
                                .resizable()
                        }
                    }
                    .scaledToFit()
                    .frame(width: method.markSize.width, height: method.markSize.height)

                    BrightText(maskedNumber(method), size: .body1, weight: .regular)
                        .monospacedDigit()

                    Spacer(minLength: .spacing2x)
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))
    }

    private func labelledRow<Value: View>(
        _ title: String,
        @ViewBuilder value: () -> Value
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText(title, size: .body1, color: .lightTextColor)

            value()
        }
    }

    private func maskedNumber(_ method: BrightPaymentMethod) -> String {
        guard let last4 = method.last4 else { return method.name }
        return "\(Constants.mask) \(Constants.mask) \(Constants.mask) \(last4)"
    }

    private enum Constants {
        static let title = "Receipt"
        static let clinicTitle = "Clinic"
        static let testTitle = "Test"
        static let typeTitle = "Type"
        static let totalTitle = "Total"
        static let paymentTitle = "Payment method"
        static let mask = "••••"
    }
}

#Preview {
    BrightReceiptSheetV5(
        order: VaultTestOrder(
            number: "162371",
            test: VaultTestingClinic.demo[0].tests[0],
            clinic: VaultTestingClinic.demo[0],
            type: .atHomeKit,
            placedAt: .now,
            paymentMethod: .applePay
        )
    )
}
