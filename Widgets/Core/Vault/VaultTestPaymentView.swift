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
                    total
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
        card(.shipTo) {
            VaultSwipeList(items: addresses, onDelete: remove) { address in
                selectableRow(isSelected: selectedAddress == address.id) {
                    selectedAddress = address.id
                } label: {
                    VStack(alignment: .leading, spacing: .spacing05x) {
                        BrightText(address.name, size: .body1)

                        BrightText(address.street, size: .body1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            BrightDivider()

            addRow(Constants.addAddressTitle) { isAddingAddress = true }
        }
    }

    // MARK: - Shipping

    private var shippingCard: some View {
        card(.shipping) {
            ForEach(Array(shipping.enumerated()), id: \.element.id) { index, option in
                selectableRow(isSelected: selectedShipping == option.id) {
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
    }

    // MARK: - Service location

    private var locationCard: some View {
        card(.location) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(clinic.name, size: .body1, weight: .regular)

                BrightText(clinic.address, size: .body1, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Payment

    private var paymentCard: some View {
        card(.payment) {
            VaultSwipeList(items: methods, onDelete: remove) { method in
                selectableRow(isSelected: selectedPayment == method.id) {
                    selectedPayment = method.id
                } label: {
                    methodLabel(method)
                }
            }

            BrightDivider()

            addRow(Constants.addCardTitle) { isAddingCard = true }
        }
    }

    private func methodLabel(_ method: VaultPaymentMethod) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                BrightText(method.name, size: .body1, weight: .regular)
                    .lineLimit(1)

                if let last4 = method.last4 {
                    HStack(spacing: .spacing05x) {
                        Image(systemName: "ellipsis")
                            .font(.standard(size: .body1, weight: .regular))

                        BrightText(last4, size: .body1, weight: .regular)
                            .monospacedDigit()
                    }
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
                    .truncationMode(.tail)
            }
        }
    }

    // MARK: - Total

    private var total: some View {
        HStack(spacing: .spacing2x) {
            BrightText(Constants.totalTitle, size: .standout3, weight: .regular)

            Spacer(minLength: .spacing2x)

            BrightChip(title: Constants.currency, tint: .defaultBlue, fill: .defaultBlue.opacity(.veryMinimalOpacity))

            BrightText(test.priceText, size: .standout3, weight: .regular)
                .monospacedDigit()
        }
        .padding(.horizontal, .spacing2x)
        .padding(.top, .spacing1x)
    }

    // MARK: - Card scaffolding

    private func card<Content: View>(
        _ section: Section,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            headerLabel(section)

            BrightDivider()

            content()
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
        .brightWiggle(trigger: nudges[section, default: 0])
    }

    private func headerLabel(_ section: Section) -> some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: section.systemImage)
                .font(.standard(size: .heading, weight: .light))

            BrightText(section.title, size: .body1, color: .semiLightTextColor, weight: .regular)

            Spacer(minLength: .spacing2x)

            Image(systemName: "chevron.down")
                .font(.standard(size: .body1, weight: .regular))
                .foregroundStyle(Color.semiLightTextColor)
        }
    }

    private func selectableRow<Label: View>(
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
        static let addAddressTitle = "Add an address"
        static let addCardTitle = "Add a card"
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

// MARK: - Swipe-to-delete list

private struct VaultSwipeList<Item: Identifiable, Row: View>: View {
    let items: [Item]
    let onDelete: (Item) -> Void
    @ViewBuilder let row: (Item) -> Row

    @State private var heights = [Item.ID: CGFloat]()

    var body: some View {
        List {
            ForEach(items) { item in
                row(item)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        heights[item.id] = height
                    }
                    .listRowInsets(EdgeInsets(
                        top: .spacing0x,
                        leading: .spacing0x,
                        bottom: .spacing0x,
                        trailing: .spacing0x
                    ))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation(.brightSnappy) { onDelete(item) }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.defaultRed)
                    }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(.spacing3x)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .contentMargins(.vertical, .spacing0x, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, VaultSwipeListConstants.minRowHeight)
        .frame(height: listHeight)
        .animation(.brightSnappy, value: listHeight)
    }

    private var listHeight: CGFloat {
        let rows = items.reduce(CGFloat.spacing0x) { total, item in
            total + max(heights[item.id] ?? VaultSwipeListConstants.minRowHeight, VaultSwipeListConstants.minRowHeight)
        }
        return rows + CGFloat(max(items.count - 1, 0)) * .spacing3x
    }
}

private enum VaultSwipeListConstants {
    static let minRowHeight: CGFloat = .spacing6x
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
