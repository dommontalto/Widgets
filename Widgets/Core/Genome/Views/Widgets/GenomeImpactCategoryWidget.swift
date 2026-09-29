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
        .disabled(!category.isInteractive)
    }

    private var builtCard: some View {
        BrightCardGridItem(category.title, subtitle: "\(category.markerCount) markers") {
            Image(category.imageName)
                .resizable()
                .frame(width: .spacing6x, height: .spacing6x)
        } titleAccessory: {
            if category.categoryState == .partial {
                Circle()
                    .fill(Color.defaultYellow)
                    .frame(width: .spacing1x, height: .spacing1x)
            }
        }
    }

    private var pendingCard: some View {
        BrightCardGridItem(category.title, subtitle: "\(category.markerCount) markers") {
            RoundedRectangle(cornerRadius: .cornerRadius10)
                .fill(Color.defaultMainGrey.opacity(.lowOpacity))
                .frame(width: .spacing6x, height: .spacing6x)
        }
        .redacted(reason: .placeholder)
    }
}

// MARK: - Widget

struct GenomeImpactCategoryWidget: View {
    let categories: [GenomeCategory]
    var onSelect: (GenomeCategory) -> Void = { _ in }

    var body: some View {
        BrightCardGrid {
            ForEach(categories) { category in
                GenomeCategoryCard(category: category) { onSelect(category) }
            }
        }
    }
}
