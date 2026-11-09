//
//  BrightOrderStatusV5.swift
//  Widgets
//

import SwiftUI

struct BrightOrderFulfilment {
    let systemImage: String
    let title: String
}

struct BrightOrderProgress {
    let text: String
    var progress: Double?
    var isFailed = false
}

struct BrightOrderStatusV5<Badge: View, Details: View>: View {
    let title: String
    var price: String?
    var fulfilment: BrightOrderFulfilment?
    var status: BrightOrderProgress?
    var onTap: (() -> Void)?
    @ViewBuilder let badge: Badge
    @ViewBuilder let details: Details

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .top, spacing: .spacing2x) {
                badge

                Spacer(minLength: .spacing0x)

                if let fulfilment {
                    HStack(spacing: .spacing1x) {
                        Image(systemName: fulfilment.systemImage)
                            .font(.standard(size: .body1, weight: .regular))

                        BrightText(fulfilment.title, size: .body3)
                    }
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: .spacing2x) {
                BrightText(title, size: .subheading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: .spacing0x)

                if let price {
                    BrightText(price, size: .subheading)
                        .monospacedDigit()
                }
            }

            BrightDividerV5()

            if let status {
                BrightText(status.text, size: .body3, color: status.isFailed ? .defaultRed : .textColor)
                    .fixedSize(horizontal: false, vertical: true)

                if !status.isFailed, let progress = status.progress {
                    BrightOrderTrackV5(progress: progress)
                }
            }

            details
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5())
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

extension BrightOrderStatusV5 where Details == EmptyView {
    init(
        title: String,
        price: String? = nil,
        fulfilment: BrightOrderFulfilment? = nil,
        status: BrightOrderProgress?,
        onTap: (() -> Void)? = nil,
        @ViewBuilder badge: () -> Badge
    ) {
        self.title = title
        self.price = price
        self.fulfilment = fulfilment
        self.status = status
        self.onTap = onTap
        self.badge = badge()
        self.details = EmptyView()
    }
}

struct BrightOrderTrackV5: View {
    let progress: Double

    @State private var trackWidth: CGFloat = .spacing0x

    var body: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "shippingbox")
                .font(.standard(size: .heading, weight: .regular))
                .foregroundStyle(Color.semiLightTextColor)

            Capsule()
                .fill(Color.textColor.opacity(.ultraLowOpacity))
                .frame(height: Constants.height)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    trackWidth = width
                }
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.defaultGreen)
                        .frame(width: trackWidth * min(max(progress, 0), 1))
                }

            Image(systemName: "house")
                .font(.standard(size: .heading, weight: .regular))
                .foregroundStyle(Color.semiLightTextColor)
        }
        .animation(.brightEaseInOut, value: progress)
    }

    private enum Constants {
        static let height: CGFloat = .spacing105x
    }
}

#Preview {
    BrightOrderStatusV5(
        title: "Gut Biome Panel",
        price: "$49.99",
        fulfilment: .init(systemImage: "house", title: "At Home"),
        status: .init(text: "Delivered", progress: 1)
    ) {
        RoundedRectangle(cornerRadius: .squareCornerRadius, style: .continuous)
            .fill(Color.defaultPink)
            .frame(width: 46, height: 46)
    }
    .padding(.spacing3x)
    .background(Color.defaultBackground)
}
