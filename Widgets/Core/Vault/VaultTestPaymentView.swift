//
//  VaultTestPaymentView.swift
//  Widgets
//
//  Created by Dom Montalto on 17/9/2026.
//

import SwiftUI

struct VaultTestPaymentView: View {
    let test: VaultClinicTest
    let type: VaultTestAvailability
    let clinic: VaultTestingClinic
    let onPay: () -> Void

    @State private var collapsed = Set<Section>()
    @State private var selectedAddress: VaultShippingAddress.ID?
    @State private var selectedShipping: VaultShippingOption.ID?
    @State private var selectedPayment: VaultPaymentMethod.ID?
    @State private var nudges = [Section: Int]()

    private let addresses = VaultShippingAddress.demo
    private let shipping = VaultShippingOption.demo
    private let methods = VaultPaymentMethod.demo

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

        var isCollapsible: Bool {
            switch self {
            case .location, .payment: false
            case .shipTo, .shipping: true
            }
        }
    }

    private var isShipped: Bool {
        type != .inPerson
    }

    private var blocking: Section? {
        if isShipped {
            if selectedAddress == nil { return .shipTo }
            if selectedShipping == nil { return .shipping }
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

                    if isShipped {
                        shipToCard
                        shippingCard
                    } else {
                        locationCard
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
            ForEach(Array(addresses.enumerated()), id: \.element.id) { index, address in
                selectableRow(isSelected: selectedAddress == address.id) {
                    selectedAddress = address.id
                } label: {
                    VStack(alignment: .leading, spacing: .spacing05x) {
                        BrightText(address.name, size: .body1)

                        BrightText(address.street, size: .body1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if index < addresses.count - 1 {
                    BrightDivider()
                }
            }

            BrightDivider()

            addRow(Constants.addAddressTitle)
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
            ForEach(Array(methods.enumerated()), id: \.element.id) { index, method in
                selectableRow(isSelected: selectedPayment == method.id) {
                    selectedPayment = method.id
                } label: {
                    methodLabel(method)
                }

                if index < methods.count - 1 {
                    BrightDivider()
                }
            }

            BrightDivider()

            addRow(Constants.addCardTitle)
        }
    }

    private func methodLabel(_ method: VaultPaymentMethod) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                BrightText(method.name, size: .body1, weight: .regular)

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
            sectionHeader(section)

            if isExpanded(section) {
                BrightDivider()

                content()
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
        .brightWiggle(trigger: nudges[section, default: 0])
    }

    @ViewBuilder
    private func sectionHeader(_ section: Section) -> some View {
        if section.isCollapsible {
            Button {
                withAnimation(.brightSnappy) { toggle(section) }
            } label: {
                headerLabel(section, showsChevron: true)
            }
            .buttonStyle(.plain)
            .brightHaptic(.light, trigger: collapsed)
        } else {
            headerLabel(section, showsChevron: false)
        }
    }

    private func headerLabel(_ section: Section, showsChevron: Bool) -> some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: section.systemImage)
                .font(.standard(size: .heading, weight: .light))

            BrightText(section.title, size: .body1, color: .semiLightTextColor, weight: .regular)

            Spacer(minLength: .spacing2x)

            if showsChevron {
                Image(systemName: collapsed.contains(section) ? "chevron.down" : "chevron.up")
                    .font(.standard(size: .body1, weight: .regular))
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
            }
        }
        .contentShape(Rectangle())
    }

    private func isExpanded(_ section: Section) -> Bool {
        !section.isCollapsible || !collapsed.contains(section)
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

    private func addRow(_ title: String) -> some View {
        HStack(spacing: .spacing2x) {
            BrightRoundButton(systemImage: "plus", haptic: nil)
                .allowsHitTesting(false)

            BrightText(title, size: .body1, color: .lightTextColor)

            Spacer(minLength: .spacing2x)
        }
    }

    // MARK: - Actions

    private func toggle(_ section: Section) {
        if collapsed.contains(section) {
            collapsed.remove(section)
        } else {
            collapsed.insert(section)
        }
    }

    private func pay() {
        guard let blocking else {
            onPay()
            return
        }

        withAnimation(.brightSnappy) { collapsed.remove(blocking) }
        nudges[blocking, default: 0] += 1
    }

    private enum Constants {
        static let title = "Review and Purchase"
        static let payTitle = "Pay"
        static let totalTitle = "Total"
        static let currency = "AUD"
        static let addAddressTitle = "Add an address"
        static let addCardTitle = "Add a card"
    }
}

#Preview {
    NavigationStack {
        VaultTestPaymentView(
            test: VaultTestingClinic.demo[0].tests[0],
            type: .atHome,
            clinic: VaultTestingClinic.demo[0]
        ) {}
    }
}
