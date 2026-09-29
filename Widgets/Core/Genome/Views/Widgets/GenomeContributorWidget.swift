//
//  GenomeContributorWidget.swift
//  Widgets
//

import SwiftUI

struct GenomeContributorWidget: View {
    let contributors: [GenomeContributor]
    var cardColor: Color = .defaultCards
    var onSelect: (GenomeContributor) -> Void = { _ in }

    var body: some View {
        VStack(spacing: .spacing2x) {
            ForEach(contributors) { contributor in
                Button {
                    onSelect(contributor)
                } label: {
                    GenomeContributorRow(contributor: contributor, cardColor: cardColor)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct GenomeContributorRow: View {
    let contributor: GenomeContributor
    let cardColor: Color

    var body: some View {
        HStack(alignment: .center, spacing: .spacing3x) {
            VStack(alignment: .leading, spacing: .spacing1x) {
                HStack(spacing: .spacing2x) {
                    Image(contributor.imageName)
                        .resizable()
                        .frame(width: 24, height: 24)
                    BrightText(contributor.gene, size: .body1)
                }
                BrightText(contributor.subtitle, size: .body2, color: Color.lightTextColor)
            }

            Spacer()

            BrightText(contributor.scoreText, size: .heading, color: contributor.scoreColor)
                .monospacedDigit()
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: cardColor))
    }
}
