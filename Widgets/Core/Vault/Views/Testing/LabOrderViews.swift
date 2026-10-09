//
//  LabOrderViews.swift
//  Widgets
//

import SwiftUI

struct LabOrderCard: View {
    let order: LabOrder
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .top, spacing: .spacing2x) {
                VaultClinicLogo()

                Spacer(minLength: .spacing0x)

                HStack(spacing: .spacing1x) {
                    Image(systemName: order.availability.systemImage)
                        .font(.standard(size: .body1, weight: .light))

                    BrightText(order.availability.rawValue, size: .body1, weight: .regular)
                }
            }

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(order.providerName, size: .subheading, color: .semiLightTextColor, weight: .regular)

                BrightText(order.labTest.name ?? Constants.fallbackName, size: .body1, color: .lightTextColor)
            }

            BrightDividerV5()

            BrightText(order.statusLabel, size: .body1, color: order.isFailed ? .defaultRed : .textColor, weight: .regular)

            if !order.isFailed {
                VaultOrderDeliveryTrack(progress: order.progress)
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5())
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    fileprivate enum Constants {
        static let fallbackName = "Lab test"
    }
}

struct LabOrderSheet: View {
    @State private var order: LabOrder
    let onChange: (LabOrder) -> Void

    @State private var results: LabResults?
    @State private var shownURL: URL?
    @State private var isSimulating = false

    private let service: LabOrdersServiceProtocol = LabOrdersMockService()

    init(order: LabOrder, onChange: @escaping (LabOrder) -> Void) {
        _order = State(initialValue: order)
        self.onChange = onChange
    }

    var body: some View {
        BrightPageSheetViewV5(
            horizontalPadding: .spacing0x,
            trailing: {
                ToolbarItem(placement: .topBarTrailing) {
                    #if DEBUG
                    Button("Simulate", systemImage: "ladybug", action: simulate)
                        .disabled(isSimulating || order.isReady || order.isFailed)
                    #endif
                }
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing3x) {
                        header
                        statusCard

                        if order.isEirly, !order.isReady, !order.isFailed {
                            ForEach(order.eirlyReferrals) { referral in
                                referralCard(referral)
                            }
                        }

                        if order.isReady {
                            resultsCard
                        }
                    }
                    .padding(.horizontal, .spacing3x)
                    .padding(.bottom, .spacing12x)
                }
                .scrollIndicators(.hidden)
            }
        )
        .overlay(alignment: .bottom) {
            if let trackingURL = order.trackingURL, !order.isEirly, !order.isReady {
                BrightPillButton(Constants.trackTitle, systemImage: "box.truck.badge.clock", buttonSize: .large) {
                    shownURL = trackingURL
                }
                .padding(.bottom, .spacing4x)
            }
        }
        .sheet(isPresented: urlShown) {
            if let shownURL {
                SafariView(url: shownURL) { self.shownURL = nil }
                    .ignoresSafeArea()
            }
        }
        .task { await refresh() }
        .task(id: order.isReady) {
            guard order.isReady, results == nil else { return }
            do {
                results = try await service.getResults(id: order.id)
            } catch {
                Log("Labs: results load failed – \(error)")
                results = LabResults(results: [], missingResults: nil)
            }
        }
    }

    private var urlShown: Binding<Bool> {
        Binding(
            get: { shownURL != nil },
            set: { if !$0 { shownURL = nil } }
        )
    }

    private func referralTitle(_ referral: LabOrder.Referral) -> String {
        guard !referral.kit else { return Constants.kitTitle }
        let clinicReferrals = order.eirlyReferrals.filter { !$0.kit }
        guard clinicReferrals.count > 1, let index = clinicReferrals.firstIndex(of: referral) else {
            return Constants.referralTitle
        }
        return "\(Constants.referralTitle) \(index + 1)"
    }

    private func referralDetail(_ referral: LabOrder.Referral) -> String {
        if referral.kit { return Constants.kitDetail }
        return referral.referralURL == nil ? Constants.referralPending : Constants.referralDetail
    }

    private func referralCard(_ referral: LabOrder.Referral) -> some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: referral.kit ? "shippingbox" : "mappin.and.ellipse")
                .font(.standard(size: .heading, weight: .light))
                .foregroundStyle(Color.semiLightTextColor)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(referralTitle(referral), size: .body1, weight: .regular)

                BrightText(referralDetail(referral), size: .body3, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: .spacing0x)

            if !referral.kit, let url = referral.referralURL {
                BrightPillButton(Constants.referralButton, systemImage: "doc.text", buttonSize: .small) {
                    shownURL = url
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText(order.labTest.name ?? LabOrderCard.Constants.fallbackName, size: .standout1, weight: .regular)

            BrightText("\(order.providerName) · \(order.availability.rawValue)", size: .subheading, weight: .regular)

            if let placedAt = order.placedAt {
                BrightText(placedAt.formatted(.brightDate), size: .body1, color: .lightTextColor)
            }
        }
        .padding(.top, .spacing2x)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(order.statusLabel, size: .subheading, color: order.isFailed ? .defaultRed : .textColor, weight: .regular)

            if order.isFailed {
                BrightText(Constants.failedDetail, size: .body1, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VaultOrderDeliveryTrack(progress: order.progress)

                BrightText("Step \(order.completedSteps) of \(order.totalSteps)", size: .body1, color: .lightTextColor)
                    .monospacedDigit()
            }

            if let totalText = order.totalText {
                BrightDividerV5()

                HStack(spacing: .spacing2x) {
                    BrightText(Constants.totalTitle, size: .body1, weight: .regular)

                    Spacer(minLength: .spacing2x)

                    BrightText(totalText, size: .body1, weight: .regular)
                        .monospacedDigit()
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))
    }

    @ViewBuilder
    private var resultsCard: some View {
        if let results {
            VStack(alignment: .leading, spacing: .spacing2x) {
                BrightText(Constants.resultsTitle, size: .subheading, weight: .regular)

                if results.results.isEmpty {
                    BrightText(Constants.noResults, size: .body1, color: .lightTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if results.missingResults?.isEmpty == false {
                    BrightText(Constants.missingResults, size: .body1, color: .lightTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(Array(results.results.enumerated()), id: \.element.id) { index, biomarker in
                    resultRow(biomarker, isLast: index == results.results.count - 1)
                }
            }
            .padding(.spacing3x)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))
        } else {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity)
        }
    }

    private func resultRow(_ biomarker: LabResults.Biomarker, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing2x) {
                BrightText(biomarker.name, size: .body1, color: .semiLightTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: .spacing2x)

                BrightText(biomarker.valueText, size: .body1, color: biomarker.isFlagged ? .defaultOrange : .textColor, weight: .regular)
                    .monospacedDigit()
            }

            if !isLast {
                BrightDividerV5()
            }
        }
    }

    private func refresh() async {
        do {
            order = try await service.getOrder(id: order.id)
            onChange(order)
        } catch {
            Log("Labs: order refresh failed – \(error)")
        }
    }

    private func simulate() {
        isSimulating = true
        Task {
            defer { isSimulating = false }
            do {
                order = try await service.simulate(id: order.id)
                onChange(order)
            } catch {
                Log("Labs: simulate failed – \(error)")
            }
        }
    }

    private enum Constants {
        static let trackTitle = "Track Kit"
        static let referralTitle = "Pathology referral"
        static let referralButton = "Referral"
        static let referralDetail = "Take your referral to a collection centre. We've also emailed it to you."
        static let referralPending = "We're preparing your referral. It'll be emailed to you and appear here."
        static let kitTitle = "At-home kit"
        static let kitDetail = "Your kit is posted to your address. Follow the instructions inside to collect your sample."
        static let missingResults = "Some results are still on their way. They'll appear here once the lab sends them."
        static let totalTitle = "Total"
        static let resultsTitle = "Results"
        static let noResults = "Your results are ready but couldn't be loaded. Try again shortly."
        static let failedDetail = "We couldn't place this order with the lab. If you were charged, we'll refund you."
    }
}
