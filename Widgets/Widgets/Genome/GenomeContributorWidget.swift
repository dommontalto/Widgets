//
//  GenomeContributorWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

// MARK: - Row

private struct GenomeContributorRow: View {
    let contributor: GenomeContributor

    var body: some View {
        HStack(alignment: .center, spacing: .spacing3x) {
            VStack(alignment: .leading, spacing: .spacing1x) {
                HStack(spacing: .spacing2x) {
                    Image(contributor.imageName)
                        .resizable()
                        .frame(width: 24, height: 24)
                    BrightText(contributor.gene, size: .body1, weight: .regular)
                }
                BrightText(contributor.subtitle, size: .body4, color: Color.lightTextColor, weight: .regular)
            }

            Spacer()

            BrightText(contributor.scoreText, size: .body1, color: contributor.scoreColor, weight: .medium)
                .monospacedDigit()
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }
}

// MARK: - Widget

struct GenomeContributorWidget: View {
    var body: some View {
        VStack(spacing: .spacing2x) {
            ForEach(GenomeContributor.data) { contributor in
                GenomeContributorRow(contributor: contributor)
            }
        }
    }
}

#Preview {
    ScrollView {
        GenomeContributorWidget()
            .padding(.spacing3x)
    }
    .background(Color.bG.ignoresSafeArea())
}
