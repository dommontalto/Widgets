//
//  GenomeImpactContributor.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct GenomeImpactContributorWidget: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: .spacing2x), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: .spacing2x) {
            ForEach(GenomeCategory.all) { category in
                GenomeCategoryCard(category: category)
            }
        }
    }
}

private struct GenomeCategoryCard: View {
    let category: GenomeCategory

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            Image(category.imageName)
                .resizable()
                .frame(width: 20, height: 20)

            BrightText(category.title, size: .body1)
            BrightText("\(category.markerCount) markers", size: .body4, color: Color.lightTextColor)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }
}

#Preview {
    ScrollView {
        GenomeImpactContributorWidget()
            .padding(.spacing3x)
    }
    .background(Color.bG.ignoresSafeArea())
}
