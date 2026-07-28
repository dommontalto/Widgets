//
//  GenomeOrderWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct GenomeOrderWidget: View {
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 156)
            .background {
                Image(ImageNames.genomeOrderBackgroundV5)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 10, opaque: true)
            }
            .overlay {
                content
            }
            .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
            .modifier(CardModifier(clipContent: false))
    }

    private var content: some View {
        VStack(spacing: .spacing2x) {
            Image(ImageNames.genomeOrderDnaIconV5)

            BrightText(
                "Don’t have genetic data available?\nOrder your testing kit today.",
                size: .body1,
                color: .white
            )
            .multilineTextAlignment(.center)
        }
        .blendMode(.overlay)
        .padding(.spacing4x)
    }
}

#Preview {
    GenomeOrderWidget()
        .padding(.spacing3x)
        .background(Color.bG.ignoresSafeArea())
}
