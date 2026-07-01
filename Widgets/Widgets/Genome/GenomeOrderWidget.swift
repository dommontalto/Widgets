//
//  GenomeOrderWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct GenomeOrderWidget: View {
    var body: some View {
        Image(ImageNames.genomeOrderV5)
            .resizable()
            .scaledToFit()
            .modifier(CardModifier())
    }
}

#Preview {
    GenomeOrderWidget()
        .padding(.spacing3x)
        .background(Color.bG.ignoresSafeArea())
}
