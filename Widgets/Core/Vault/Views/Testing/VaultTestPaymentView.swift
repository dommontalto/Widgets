//
//  VaultTestPaymentView.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import SwiftUI

struct VaultTestPaymentView: View {
    let test: VaultClinicTest
    let type: VaultTestAvailability
    let clinic: VaultTestingClinic
    let onPay: (VaultTestOrder) -> Void

    @State private var addresses = VaultShippingAddress.demo
    @State private var methods = VaultPaymentMethod.demo
    @State private var selectedAddress: VaultShippingAddress.ID?
    @State private var selectedShipping: VaultShippingOption.ID?
    @State private var selectedPayment: VaultPaymentMethod.ID?
    @State private var isAddingAddress = false
    @State private var isAddingCard = false
    @State private var nudges = [Section: Int]()

    private let shipping = VaultShippingOption.demo

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
        if type.needsAddress {
            if selectedAddress == nil { return .shipTo }
            if type.needsShipping, selectedShipping == nil { return .shipping }
        }
        return selectedPayment == nil ? .payment : nil
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

                    if type.needsAddress {
                        shipToCard
                    } else {
                        locationCard
                    }

                    if type.needsShipping {
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
            BrightPillButton(Constants.payTitle, systemImage: "arrow.right", buttonSize: .large, onTapCallback: pay)
                .padding(.bottom, .spacing4x)
        }
        .sheet(isPresented: $isAddingAddress) {
            VaultAddAddressSheet { address in
                addresses.append(address)
                selectedAddress = address.id
            }
        }
        .sheet(isPresented: $isAddingCard) {
            VaultAddPaymentMethodSheet { method in
                methods.append(method)
                selectedPayment = method.id
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            BrightText(test.name, size: .standout1, weight: .regular)

            HStack(spacing: .spacing1x) {
                Image(systemName: type.systemImage)
                    .font(.standard(size: .subheading, weight: .light))

                BrightText(type.rawValue, size: .subheading, weight: .regular)
            }

            BrightText(test.detail, size: .body1, color: .lightTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, .spacing2x)
    }

    // MARK: - Ship to

    private var shipToCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionTitle(.shipTo)

            BrightDivider()

            ForEach(addresses) { address in
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

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionTitle(.location)

            BrightDivider()

            BrightText(clinic.name, size: .body1, weight: .regular)

            BrightText(clinic.address, size: .body1, color: .lightTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .modifier(SectionCard(nudge: nudges[.location, default: 0]))
    }

    // MARK: - Payment

    private var paymentCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionTitle(.payment)

            BrightDivider()

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
        }
        .modifier(SectionCard(nudge: nudges[.payment, default: 0]))
    }

    private func methodLabel(_ method: VaultPaymentMethod) -> some View {
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

                Image(method.markName)
                    .resizable()
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

            BrightChip(title: Constants.currency, tint: .defaultBlue, fill: .defaultBlue.opacity(.veryMinimalOpacity))

            BrightText(test.priceText, size: .body1, weight: .regular)
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

    private func remove(_ address: VaultShippingAddress) {
        addresses.removeAll { $0.id == address.id }
        if selectedAddress == address.id {
            selectedAddress = nil
        }
    }

    private func remove(_ method: VaultPaymentMethod) {
        methods.removeAll { $0.id == method.id }
        if selectedPayment == method.id {
            selectedPayment = nil
        }
    }

    private func pay() {
        guard let blocking else {
            onPay(order)
            return
        }

        nudges[blocking, default: 0] += 1
    }

    private var order: VaultTestOrder {
        VaultTestOrder(
            number: VaultTestOrder.newNumber(),
            test: test,
            clinic: clinic,
            type: type,
            placedAt: .now,
            scheduledAt: type.needsShipping ? nil : Constants.scheduledAt,
            address: type.needsAddress ? addresses.first { $0.id == selectedAddress }?.street : clinic.address,
            delivery: type.needsShipping ? Constants.delivery : nil,
            paymentMethod: methods.first { $0.id == selectedPayment }
        )
    }

    private enum Constants {
        static let title = "Review and Purchase"
        static let payTitle = "Pay"
        static let totalTitle = "Total"
        static let currency = "AUD"
        static let mask = "•••"
        static let addAddressTitle = "Add an address"
        static let addCardTitle = "Add a card"
        static let removeTitle = "Remove"
        static let appointmentDays = 2
        static let deliveryDays = 3
        static let startingProgress = 0.25

        static var scheduledAt: Date {
            Calendar.autoupdatingCurrent.date(byAdding: .day, value: appointmentDays, to: .now) ?? .now
        }

        static var delivery: VaultTestDelivery {
            let arrives = Calendar.autoupdatingCurrent.date(byAdding: .day, value: deliveryDays, to: .now) ?? .now
            return VaultTestDelivery(arrivesOn: arrives, progress: startingProgress)
        }
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
        VaultTestPaymentView(
            test: VaultTestingClinic.demo[0].tests[0],
            type: .atHomeKit,
            clinic: VaultTestingClinic.demo[0]
        ) { _ in }
    }
}
