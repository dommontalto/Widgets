//
//  BrightImpactWidget.swift
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

nonisolated struct CycleTrackingImpactItem: Identifiable, Codable {
    var id = UUID()
    let text: String
    let isPositive: Bool
}

nonisolated struct CycleTrackingImpactData: Codable {
    let items: [CycleTrackingImpactItem]
    let description: String?
}

struct BrightImpactWidget: View {
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
                    BrightDivider()

                    BrightText(
                        description,
                        size: .body1
                    )
                }
            }
            .padding(.spacing3x)
            .modifier(CardModifier(color: cardColor))
        }
    }

    private var header: some View {
        HStack(spacing: .spacing2x) {
            Image(type.imageName)

            BrightText(
                title ?? type.title,
                size: .subheading,
                color: .textColor
            )

            Spacer()
        }
    }

    private func itemRow(_ item: CycleTrackingImpactItem) -> some View {
        HStack(spacing: .spacing2x) {
            Image(item.isPositive ? ImageNames.cycleTrackingTickV5 : ImageNames.cycleTrackingExclamationV5)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.itemIconSize, height: Constants.itemIconSize)

            BrightText(
                item.text,
                size: .body1
            )

            Spacer()
        }
    }

    private class Constants {
        static let itemIconSize: CGFloat = 24
    }
}

#Preview {
    ScrollView {
        VStack(spacing: .spacing4x) {
            BrightImpactWidget(
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
