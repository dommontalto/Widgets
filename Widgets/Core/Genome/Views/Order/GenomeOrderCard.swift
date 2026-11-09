//
//  GenomeOrderCard.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct GenomeOrderCard: View {
    let status: GenomeOrderStatus
    var order: GenomeOrderInfo?
    var onSeeResults: (() -> Void)?

    @Environment(\.openURL) private var openURL

    private var isFailed: Bool { status == .failed || status == .cancelled }
    private var isReady: Bool { status == .ready }
    private var statusLabel: String { order?.statusLabel ?? status.displayTitle }
    private var completedSteps: Int { order?.completedSteps ?? status.completedSteps }
    private var totalSteps: Int { order?.totalSteps ?? Constants.defaultSteps }

    private var statusText: String {
        if isFailed { return "\(statusLabel) · \(Constants.contactPrompt)" }
        if isReady, onSeeResults != nil { return "\(statusLabel) · \(Constants.resultsPrompt)" }
        guard let eta = order?.eta, !isReady else { return statusLabel }
        return "\(statusLabel) · ETA \(eta)"
    }

    private var progress: Double {
        guard !isReady else { return 1 }
        return totalSteps > 0 ? Double(completedSteps) / Double(totalSteps) : 0
    }

    var body: some View {
        BrightOrderStatusV5(
            title: Constants.title,
            fulfilment: BrightOrderFulfilment(systemImage: Constants.fulfilmentSymbol, title: Constants.fulfilmentTitle),
            status: BrightOrderProgress(text: statusText, progress: progress, isFailed: isFailed),
            onTap: handleTap
        ) {
            GenomeOrderBadge()
        }
    }

    private func handleTap() {
        if isReady {
            onSeeResults?()
        } else if isFailed {
            let subject = "DNA order — \(status.displayTitle)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "mailto:\(Constants.supportEmail)?subject=\(subject)") {
                openURL(url)
            }
        }
    }

    private enum Constants {
        static let title = "Genome test"
        static let fulfilmentSymbol = "cross.case"
        static let fulfilmentTitle = "At Home Kit"
        static let defaultSteps = 4
        static let contactPrompt = "Tap to contact us"
        static let resultsPrompt = "Tap to see them"
        static let supportEmail = "hello@thebrightapp.xyz"
    }
}

#Preview {
    VStack(spacing: .spacing3x) {
        GenomeOrderCard(status: .shipping)
        GenomeOrderCard(status: .ready) {}
        GenomeOrderCard(status: .failed)
    }
    .padding(.spacing3x)
    .background(Color.defaultBackground.ignoresSafeArea())
}
