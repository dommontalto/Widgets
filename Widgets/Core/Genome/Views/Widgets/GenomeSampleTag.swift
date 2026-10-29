//
//  GenomeSampleTag.swift
//  Widgets
//

import SwiftUI

struct GenomeSampleTag: View {
    var body: some View {
        BrightText("SAMPLE", size: .body5, color: .lightTextColor, weight: .medium)
            .padding(.horizontal, .spacing1x)
            .padding(.vertical, .spacing05x)
            .overlay(Capsule().strokeBorder(Color.textColor.opacity(.ultraLowOpacity)))
            .accessibilityLabel("Sample data")
    }
}

#Preview {
    GenomeSampleTag()
        .padding()
}
