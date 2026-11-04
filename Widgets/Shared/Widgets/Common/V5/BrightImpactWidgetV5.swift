//
//  BrightImpactWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 31/7/2026.
//

import SwiftUI

nonisolated enum CycleTrackingImpactType: String, Codable {
    case summary
    case why
    case what
    case how

    var title: String {
        switch self {
        case .summary: "Summary for today"
        case .why: "Why you feel the way you do"
        case .what: "What to do differently"
        case .how: "How normal are your symptoms"
        }
    }

    var imageName: String {
        switch self {
        case .summary: ImageNames.cycleTrackingMainSummaryV5
        case .why: ImageNames.cycleTrackingFeelV5
        case .what: ImageNames.cycleTrackingDifferentlyV5
        case .how: ImageNames.cycleTrackingMainSymptomsV5
        }
    }
}

// Lighthouse's per-signal status. A signal with none falls back to `isPositive`.
nonisolated enum BrightImpactStatus: String, Codable {
    case onTrack = "on_track"
    case watch
    case attention
    // "Too early to tell": the label says so; a neutral icon has no design yet, so the slot stays empty.
    case neutral

    init(status: String?, ok: Bool?) {
        switch status {
        case "on_track": self = .onTrack
        case "watch": self = .watch
        case "attention": self = .attention
        case "too_early": self = .neutral
        default: self = ok.map { $0 ? .onTrack : .attention } ?? .neutral
        }
    }
}

nonisolated struct CycleTrackingImpactItem: Identifiable, Codable {
    var id = UUID()
    let text: String
    let isPositive: Bool
    var status: BrightImpactStatus?
}

nonisolated struct CycleTrackingImpactData: Codable {
    let items: [CycleTrackingImpactItem]
    let description: String?
    // The server's per-card title; the type's own title otherwise.
    var title: String?
}

struct BrightImpactWidgetV5: View {
    let type: CycleTrackingImpactType
    var title: String?
    var data: CycleTrackingImpactData?
    var cardColor: Color = .defaultCards

    var body: some View {
        if let data {
            VStack(alignment: .leading, spacing: .spacing3x) {
                header

                VStack(alignment: .leading, spacing: .spacing2x) {
                    ForEach(data.items) { item in
                        itemRow(item)
                    }
                }

                if let description = data.description {
                    BrightDividerV5()

                    BrightText(
                        description,
                        size: .body1
                    )
                }
            }
            .padding(.spacing3x)
            .modifier(BrightCardModifierV5(color: cardColor))
        }
    }

    private var header: some View {
        HStack(spacing: .spacing2x) {
            Image(type.imageName)

            BrightText(
                title ?? data?.title ?? type.title,
                size: .subheading,
                color: .textColor
            )

            Spacer()
        }
    }

    private func itemRow(_ item: CycleTrackingImpactItem) -> some View {
        HStack(spacing: .spacing2x) {
            itemIcon(item.status ?? (item.isPositive ? .onTrack : .attention))
                .frame(width: Constants.itemIconSize, height: Constants.itemIconSize)

            BrightText(
                item.text,
                size: .body1
            )

            Spacer()
        }
    }

    @ViewBuilder
    private func itemIcon(_ status: BrightImpactStatus) -> some View {
        switch status {
        case .onTrack: Image(ImageNames.cycleTrackingTickV5).resizable().aspectRatio(contentMode: .fit)
        case .watch: Image(ImageNames.warningDiamondYellowV4).resizable().aspectRatio(contentMode: .fit)
        case .attention: Image(ImageNames.cycleTrackingExclamationV5).resizable().aspectRatio(contentMode: .fit)
        case .neutral: Color.clear
        }
    }

    private class Constants {
        static let itemIconSize: CGFloat = 24
    }
}

#Preview {
    ScrollView {
        VStack(spacing: .spacing4x) {
            BrightImpactWidgetV5(
                type: .summary,
                data: CycleTrackingImpactData(
                    items: [
                        CycleTrackingImpactItem(text: "Develops lower body strength", isPositive: true),
                        CycleTrackingImpactItem(text: "Requires good form and technique", isPositive: false),
                    ],
                    description: nil
                )
            )
        }
        .padding(.spacing4x)
    }
    .background(Color.defaultBackground)
}
