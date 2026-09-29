//
//  GenomeOrderStatusWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct GenomeOrderStatusWidget: View {
    let status: GenomeOrderStatus
    var order: GenomeOrderInfo?
    var onSeeResults: (() -> Void)?

    @Environment(\.openURL) private var openURL

    private var isFailed: Bool { status == .failed || status == .cancelled }
    private var isReady: Bool { status == .ready }
    private var statusLabel: String { order?.statusLabel ?? status.displayTitle }
    private var statusColor: Color { isFailed ? .defaultRed : isReady ? .defaultGreen : .defaultSkyBlue }
    private var etaText: String? { isFailed || isReady ? nil : order?.eta.map { "ETA: \($0)" } }
    private var completedSteps: Int { order?.completedSteps ?? status.completedSteps }
    private var totalSteps: Int { order?.totalSteps ?? 4 }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            headerRow
            statusSection
            if isFailed {
                failedSection
            } else {
                progressBar
                    .padding(.bottom, .spacing1x)

                if isReady, let onSeeResults {
                    BrightPillButton("See results", systemImage: "arrow.right", onTapCallback: onSeeResults)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, .spacing1x)
                }
            }
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    // MARK: Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: .spacing2x) {
                Image(ImageNames.genomeDnaV5)

                BrightText("Genome", size: .body1)
            }
            Spacer()

            if let etaText {
                HStack(spacing: .spacing1x) {
                    Image(ImageNames.genomeClockV5)

                    BrightText(etaText, size: .body3, color: Color.lightTextColor)
                }
            }
        }
    }

    // MARK: Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText("Status", size: .body3, color: Color.lightTextColor)
            BrightText(statusLabel, size: .heading, color: statusColor)
        }
    }

    // MARK: Failed

    private var failedSection: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightText("Something went wrong with your order. Get in touch and we'll help sort it out.", size: .body3, color: Color.lightTextColor)
                .fixedSize(horizontal: false, vertical: true)

            BrightPillButton("Contact us", systemImage: "envelope") {
                let subject = "Genome order — \(status.displayTitle)"
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: "mailto:hello@thebrightapp.xyz?subject=\(subject)") {
                    openURL(url)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.bottom, .spacing1x)
    }

    // MARK: Progress Bar

    private var progressColor: Color { isReady ? .defaultGreen : .defaultSkyBlue }

    private var progressBar: some View {
        HStack(spacing: .spacing1x) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i < completedSteps ? progressColor : progressColor.opacity(.minimalOpacity))
                    .frame(height: 9)
            }
        }
    }
}

#Preview {
    GenomeOrderStatusWidget(status: .ordered)
        .padding(.spacing3x)
        .background(Color.defaultBackground.ignoresSafeArea())
}
