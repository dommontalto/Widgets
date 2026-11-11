//
//  GenomeImpactCategoryWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

// MARK: - Card

private struct GenomeCategoryCard: View {
    let category: GenomeCategory
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            if category.categoryState == .pending {
                pendingCard
            } else {
                builtCard
            }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(category.isInteractive && category.markerCount > 0)
    }

    private var builtCard: some View {
        BrightCardGridItemV5(category.title, value: "\(category.markerCount)", unit: markersUnit) {
            Image(category.imageName)
                .resizable()
                .scaledToFit()
        } titleAccessory: {
            if category.categoryState == .partial {
                Circle()
                    .fill(Color.defaultYellow)
                    .frame(width: .spacing1x, height: .spacing1x)
            }
        }
    }

    private var markersUnit: String {
        category.markerCount == 1 ? "marker" : "markers"
    }

    private var pendingCard: some View {
        BrightCardGridItemV5(category.title, value: "\(category.markerCount)", unit: markersUnit) {
            Circle()
                .fill(Color.defaultMainGrey.opacity(.lowOpacity))
                .aspectRatio(1, contentMode: .fit)
        }
        .redacted(reason: .placeholder)
    }
}

// MARK: - Widget

struct GenomeImpactCategoryWidget: View {
    let categories: [GenomeCategory]
    var onSelect: (GenomeCategory) -> Void = { _ in }

    var body: some View {
        BrightCardGridV5 {
            ForEach(categories) { category in
                GenomeCategoryCard(category: category) { onSelect(category) }
            }
        }
    }
}
