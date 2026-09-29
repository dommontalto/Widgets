//
//  BrightCheckoutView.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import SwiftUI

struct BrightCheckoutView: View {
    let item: BrightCheckoutItem
    let payment: BrightCheckoutPayment
    let isPaying: Bool
    let onPay: (BrightCheckoutDetails) -> Void

    @State private var addressBook = BrightAddressBook()
    @State private var methods = [BrightPaymentMethod.applePay]
    @State private var selectedAddress: BrightShippingAddress.ID?
    @State private var selectedShipping: BrightShippingOption.ID?
    @State private var selectedPayment: BrightPaymentMethod.ID?
    @State private var isAddingAddress = false
    @State private var isAddingCard = false
    @State private var nudges = [Section: Int]()

    private let shipping = [BrightShippingOption.standard]

    init(
        item: BrightCheckoutItem,
        payment: BrightCheckoutPayment = .demo,
        isPaying: Bool = false,
        onPay: @escaping (BrightCheckoutDetails) -> Void
    ) {
        self.item = item
        self.payment = payment
        self.isPaying = isPaying
        self.onPay = onPay
    }

    enum Section: Hashable {
        case shipTo
        case shipping
        case location
        case payment

        var title: String {
            switch self {
            case .shipTo: "Ship to"
            case .shipping: "Shipping"
            case .location: "Service Location"
            case .payment: "Payment"
            }
        }

        var systemImage: String {
            switch self {
            case .shipTo, .location: "mappin.and.ellipse"
            case .shipping: "shippingbox"
            case .payment: "creditcard"
            }
        }
    }

    private var blocking: Section? {
        if item.fulfilment.needsAddress {
            if selectedAddress == nil { return .shipTo }
            if item.fulfilment.needsShipping, selectedShipping == nil { return .shipping }
        }
        return hasPayment ? nil : .payment
    }

    private var hasPayment: Bool {
        switch payment {
        case .demo: selectedPayment != nil
        case let .external(option, _): option != nil
        }
    }

    var body: some View {
        BrightPageView(
            title: Constants.title,
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultSheetBackground
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing3x) {
                    header

                    switch item.fulfilment {
                    case .shipped, .delivered:
                        shipToCard
                    case let .inPerson(name, address):
                        locationCard(name: name, address: address)
                    }

                    if item.fulfilment.needsShipping {
                        shippingCard
                    }

                    paymentCard
                    totalCard
                }
                .padding(.horizontal, .spacing3x)
                .padding(.bottom, .spacing12x)
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .bottom) {
            Group {
                if isPaying {
                    ProgressView()
                        .controlSize(.large)
                } else {
                    BrightPillButton(Constants.payTitle, systemImage: "arrow.right", buttonSize: .large, onTapCallback: pay)
                }
            }
            .padding(.bottom, .spacing4x)
            .animation(.brightEaseInOut, value: isPaying)
        }
        .sheet(isPresented: $isAddingAddress) {
            BrightAddAddressSheet { address in
                Task {
                    if let saved = await addressBook.add(address) {
                        selectedAddress = saved.id
                    }
                }
            }
        }
        .task {
            await addressBook.loadIfNeeded()
            if selectedAddress == nil {
                selectedAddress = addressBook.defaultAddress?.id
            }
        }
        .sheet(isPresented: $isAddingCard) {
            BrightAddPaymentMethodSheet { method in
                methods.append(method)
                selectedPayment = method.id
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            BrightText(item.title, size: .standout1, weight: .regular)

            if let subtitle = item.subtitle {
                HStack(spacing: .spacing1x) {
                    if let systemImage = item.systemImage {
                        Image(systemName: systemImage)
                            .font(.standard(size: .subheading, weight: .light))
                    }

                    BrightText(subtitle, size: .subheading, weight: .regular)
                }
            }

            BrightText(item.detail, size: .body1, color: .lightTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, .spacing2x)
    }

    // MARK: - Ship to

    private var shipToCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionTitle(.shipTo)

            BrightDivider()

            ForEach(addressBook.addresses) { address in
                optionRow(isSelected: selectedAddress == address.id) {
                    selectedAddress = address.id
                } label: {
                    VStack(alignment: .leading, spacing: .spacing05x) {
                        BrightText(address.name, size: .body1)

                        BrightText(address.street, size: .body1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .contextMenu { removeButton { remove(address) } }

                BrightDivider()
            }

            addRow(Constants.addAddressTitle) { isAddingAddress = true }
        }
        .modifier(SectionCard(nudge: nudges[.shipTo, default: 0]))
    }

    // MARK: - Shipping

    private var shippingCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionTitle(.shipping)

            BrightDivider()

            ForEach(Array(shipping.enumerated()), id: \.element.id) { index, option in
                optionRow(isSelected: selectedShipping == option.id) {
                    selectedShipping = option.id
                } label: {
                    VStack(alignment: .leading, spacing: .spacing05x) {
                        BrightText(option.name, size: .body1, weight: .regular)

                        BrightText(option.detail, size: .body1, color: .lightTextColor)
                    }
                }

                if index < shipping.count - 1 {
                    BrightDivider()
                }
            }
        }
        .modifier(SectionCard(nudge: nudges[.shipping, default: 0]))
    }

    // MARK: - Service location

    private func locationCard(name: String, address: String) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionTitle(.location)

            BrightDivider()

            BrightText(name, size: .body1, weight: .regular)

            BrightText(address, size: .body1, color: .lightTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .modifier(SectionCard(nudge: nudges[.location, default: 0]))
    }

    // MARK: - Payment

    private var paymentCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionTitle(.payment)

            BrightDivider()

            switch payment {
            case .demo:
                ForEach(methods) { method in
                    optionRow(isSelected: selectedPayment == method.id) {
                        selectedPayment = method.id
                    } label: {
                        methodLabel(method)
                    }
                    .contextMenu { removeButton { remove(method) } }

                    BrightDivider()
                }

                addRow(Constants.addCardTitle) { isAddingCard = true }
            case let .external(option, choose):
                if let option {
                    optionRow(isSelected: true, select: choose) {
                        methodLabel(option)
                    }

                    BrightDivider()
                }

                addRow(option == nil ? Constants.choosePaymentTitle : Constants.changePaymentTitle, action: choose)
            }
        }
        .modifier(SectionCard(nudge: nudges[.payment, default: 0]))
    }

    private func methodLabel(_ method: BrightPaymentMethod) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                BrightText(method.name, size: .body1, weight: .regular)
                    .lineLimit(1)

                if let last4 = method.last4 {
                    BrightText("\(Constants.mask) \(last4)", size: .body1, weight: .regular)
                        .monospacedDigit()
                        .fixedSize()
                }

                Spacer(minLength: .spacing1x)

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
            }

            if let billing = method.billing {
                BrightText(billing, size: .body1, color: .lightTextColor)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Total

    private var totalCard: some View {
        HStack(spacing: .spacing2x) {
            BrightText(Constants.totalTitle, size: .body1, weight: .regular)

            Spacer(minLength: .spacing2x)

            BrightChip(title: item.currency, tint: .defaultBlue, fill: .defaultBlue.opacity(.veryMinimalOpacity))

            BrightText(item.priceText, size: .body1, weight: .regular)
                .monospacedDigit()
        }
        .modifier(SectionCard(nudge: 0))
    }

    // MARK: - Rows

    private func sectionTitle(_ section: Section) -> some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: section.systemImage)
                .font(.standard(size: .heading, weight: .light))
                .foregroundStyle(Color.semiLightTextColor)

            BrightText(section.title, size: .body1, color: .semiLightTextColor, weight: .regular)

            Spacer(minLength: .spacing2x)
        }
    }

    private func optionRow<Label: View>(
        isSelected: Bool,
        select: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) -> some View {
        Button(action: select) {
            HStack(spacing: .spacing2x) {
                label()

                Spacer(minLength: .spacing2x)

                BrightTick(isTicked: isSelected)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func addRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: .spacing2x) {
                BrightRoundButton(systemImage: "plus", haptic: nil)
                    .allowsHitTesting(false)

                BrightText(title, size: .body1, color: .lightTextColor)

                Spacer(minLength: .spacing2x)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func removeButton(_ action: @escaping () -> Void) -> some View {
        Button(role: .destructive) {
            withAnimation(.brightSnappy) { action() }
        } label: {
            Label(Constants.removeTitle, systemImage: "trash")
        }
        .tint(.defaultRed)
    }

    // MARK: - Actions

    private func remove(_ address: BrightShippingAddress) {
        if selectedAddress == address.id {
            selectedAddress = nil
        }
        Task { await addressBook.remove(address) }
    }

    private func remove(_ method: BrightPaymentMethod) {
        methods.removeAll { $0.id == method.id }
        if selectedPayment == method.id {
            selectedPayment = nil
        }
    }

    private func pay() {
        guard let blocking else {
            onPay(details)
            return
        }

        nudges[blocking, default: 0] += 1
    }

    private var details: BrightCheckoutDetails {
        let paymentMethod: BrightPaymentMethod? = switch payment {
        case .demo: methods.first { $0.id == selectedPayment }
        case let .external(option, _): option
        }
        return BrightCheckoutDetails(
            address: item.fulfilment.needsAddress ? addressBook.addresses.first { $0.id == selectedAddress } : nil,
            shipping: item.fulfilment.needsShipping ? shipping.first { $0.id == selectedShipping } : nil,
            paymentMethod: paymentMethod
        )
    }

    private enum Constants {
        static let title = "Review and Purchase"
        static let payTitle = "Pay"
        static let totalTitle = "Total"
        static let mask = "•••"
        static let addAddressTitle = "Add an address"
        static let addCardTitle = "Add a card"
        static let choosePaymentTitle = "Choose a payment method"
        static let changePaymentTitle = "Change payment method"
        static let removeTitle = "Remove"
    }
}

private struct SectionCard: ViewModifier {
    let nudge: Int

    func body(content: Content) -> some View {
        content
            .padding(.spacing3x)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(CardModifier(color: .defaultSheetModalCards))
            .brightWiggle(trigger: nudge)
    }
}

#Preview {
    NavigationStack {
        BrightCheckoutView(
            item: BrightCheckoutItem(
                title: "Biological Age Panel",
                subtitle: "At Home Kit",
                systemImage: "shippingbox",
                detail: "An epigenetic read of biological age alongside the bloods that explain the number",
                priceText: "$499.99",
                currency: "AUD",
                fulfilment: .shipped
            )
        ) { _ in }
    }
}
