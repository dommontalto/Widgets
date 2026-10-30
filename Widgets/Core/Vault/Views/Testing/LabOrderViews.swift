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

            BrightText(order.headline.title, size: .body1, color: order.isFailed ? .defaultRed : .textColor, weight: .regular)

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
    @State private var resultsFailed = false
    @State private var shownURL: URL?
    @State private var isSimulating = false
    @State private var isOpeningReport = false
    @State private var reportFailed = false
    @State private var showingHelp = false

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

                        if order.hasResults {
                            resultsCard
                        }

                        helpCard
                    }
                    .padding(.horizontal, .spacing3x)
                    .padding(.bottom, .spacing12x)
                }
                .scrollIndicators(.hidden)
            }
        )
        .overlay(alignment: .bottom) {
            if let trackingURL = order.trackingURL, !order.isEirly, !order.hasResults {
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
        .sheet(isPresented: $showingHelp) {
            LabOrderHelpSheet(prefill: "\(Constants.helpPrefill) \(order.reference): ")
        }
        .task { await refresh() }
        .task(id: order.status) {
            await loadResults()
            await waitWhilePlacing()
        }
    }

    private func loadResults() async {
        guard order.hasResults else { return }
        resultsFailed = false
        do {
            results = try await service.getResults(id: order.id)
        } catch {
            Log("Labs: results load failed – \(error)")
            resultsFailed = results == nil
        }
    }

    // Paid but not yet with the lab: the Stripe webhook places it within seconds.
    private func waitWhilePlacing() async {
        for _ in 0..<Constants.placingPolls where order.status == "placing" || order.status == "awaiting_payment" {
            try? await Task.sleep(for: .seconds(Constants.placingPollSeconds))
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    private func openReport() {
        isOpeningReport = true
        reportFailed = false
        Task {
            defer { isOpeningReport = false }
            do {
                shownURL = URL(string: try await service.getResultsPDF(id: order.id).url)
            } catch {
                Log("Labs: lab report link failed – \(error)")
                reportFailed = true
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
            BrightText(order.headline.title, size: .subheading, color: order.isFailed ? .defaultRed : .textColor, weight: .regular)

            if order.isFailed {
                BrightText(order.headline.detail ?? Constants.failedDetail, size: .body1, color: .lightTextColor)
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
                HStack(spacing: .spacing2x) {
                    BrightText(Constants.resultsTitle, size: .subheading, weight: .regular)

                    Spacer(minLength: .spacing2x)

                    if results.pdfAvailable {
                        BrightPillButton(Constants.reportButton, systemImage: "doc.text", buttonSize: .small, isLoading: isOpeningReport) {
                            openReport()
                        }
                    }
                }

                if let notice = results.criticalNotice {
                    BrightText(notice, size: .body1, weight: .regular)
                        .fixedSize(horizontal: false, vertical: true)
                }

                BrightText(note(for: results), size: .body3, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                if reportFailed {
                    BrightText(Constants.reportFailed, size: .body3, color: .defaultRed)
                }

                ForEach(Array(results.markers.enumerated()), id: \.offset) { index, biomarker in
                    resultRow(biomarker, isLast: index == results.markers.count - 1 && results.missing.isEmpty)
                }

                ForEach(Array(results.missing.enumerated()), id: \.offset) { index, missing in
                    missingRow(missing, isPartial: results.isPartial, isLast: index == results.missing.count - 1)
                }

                BrightText(Constants.disclaimer, size: .body4, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.spacing3x)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))
        } else if resultsFailed {
            HStack(spacing: .spacing2x) {
                BrightText(Constants.noResults, size: .body1, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: .spacing2x)

                BrightPillButton(Constants.retryTitle, systemImage: "arrow.clockwise", buttonSize: .small) {
                    Task { await loadResults() }
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
            HStack(alignment: .firstTextBaseline, spacing: .spacing2x) {
                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(biomarker.name, size: .body1, color: .semiLightTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    if let range = biomarker.rangeText {
                        BrightText("\(Constants.rangeTitle) \(range)", size: .body4, color: .lightTextColor)
                            .monospacedDigit()
                    }
                }

                Spacer(minLength: .spacing2x)

                VStack(alignment: .trailing, spacing: .spacing05x) {
                    BrightText(biomarker.valueText, size: .body1, color: biomarker.isFlagged ? .defaultOrange : .textColor, weight: .regular)
                        .monospacedDigit()

                    if biomarker.needsPromptAttention {
                        BrightText(Constants.promptAttention, size: .body4, color: .defaultOrange)
                    }
                }
            }

            if !isLast {
                BrightDividerV5()
            }
        }
    }

    private func note(for results: LabResults) -> String {
        if results.markers.isEmpty {
            return results.isPartial ? Constants.nothingYet : Constants.noneMeasured
        }
        return results.isPartial ? Constants.partialNote : Constants.savedNote
    }

    private func missingRow(_ missing: LabResults.Missing, isPartial: Bool, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing2x) {
                BrightText(missing.name, size: .body1, color: .semiLightTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: .spacing2x)

                BrightText(Self.missingReason(missing.reason, isPartial: isPartial), size: .body3, color: .lightTextColor)
            }

            if !isLast {
                BrightDividerV5()
            }
        }
    }

    // An unknown reason reads "With the lab" while results are still coming in.
    private static func missingReason(_ reason: String?, isPartial: Bool) -> String {
        switch reason {
        case "pending": Constants.pendingReason
        case "quantity_not_sufficient_failure": Constants.notEnoughSample
        case "collection_process_failure", "drop_off_failure": Constants.collectionProblem
        default: isPartial ? Constants.pendingReason : Constants.notMeasured
        }
    }

    private var helpCard: some View {
        HStack(spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText("\(Constants.orderTitle) \(order.reference)", size: .body1, weight: .regular)
                    .monospacedDigit()

                BrightText(Constants.helpDetail, size: .body3, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: .spacing2x)

            BrightPillButton(Constants.helpTitle, systemImage: "questionmark.circle", buttonSize: .small) {
                showingHelp = true
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))
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
        static let partialNote = "Some results are back and saved in your Vault. The rest will appear here as the lab sends them."
        static let savedNote = "Saved in your Vault, from your Bright lab order."
        static let reportButton = "Lab report"
        static let rangeTitle = "Range"
        static let retryTitle = "Try again"
        static let pendingReason = "With the lab"
        static let notEnoughSample = "Not enough sample"
        static let collectionProblem = "Collection problem"
        static let notMeasured = "Couldn't be measured"
        static let orderTitle = "Order"
        static let helpTitle = "Get help"
        static let helpDetail = "Questions about this order or your results? Bright support will help."
        static let helpPrefill = "Lab order"
        static let placingPolls = 40
        static let placingPollSeconds = 3.0
        static let totalTitle = "Total"
        static let resultsTitle = "Results"
        static let noResults = "Your results couldn't be loaded."
        static let nothingYet = "Your results aren't back yet. They'll appear here as the lab sends them."
        static let noneMeasured = "The lab couldn't measure these tests. Get help below and we'll arrange what's next."
        static let reportFailed = "Couldn't open the lab's report. Try again in a moment."
        static let promptAttention = "Needs prompt attention"
        static let disclaimer = "Results are for information only and aren't a diagnosis. Talk to a clinician about anything flagged."
        static let failedDetail = "We couldn't place this order with the lab. If you were charged, we'll refund you."
    }
}

// Stands in for the iOS app's Report an issue sheet: the question is written but goes nowhere.
private struct LabOrderHelpSheet: View {
    @State var prefill: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        BrightPageSheetViewV5(title: "Ask a question") {
            VStack(alignment: .leading, spacing: .spacing3x) {
                TextField("Your question", text: $prefill, axis: .vertical)
                    .font(.standard(size: .body1, weight: .regular))
                    .lineLimit(5...10)
                    .padding(.spacing2x)
                    .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))

                BrightText("We'll reply by email, usually within a day.", size: .body3, color: .lightTextColor)
            }
            .padding(.top, .spacing2x)
        }
        .brightBottomButtonV5 {
            BrightPillButton("Send", systemImage: "paperplane", buttonSize: .large) {
                dismiss()
            }
        }
    }
}
