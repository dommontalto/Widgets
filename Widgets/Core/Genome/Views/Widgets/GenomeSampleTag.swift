//
//  GenomeSampleTag.swift
//  Widgets
//

import SwiftUI

struct GenomeSampleTag: View {
    var body: some View {
        BrightStatus(status: "Sample")
            .accessibilityLabel("Sample data")
    }
}

#Preview {
    GenomeSampleTag()
        .padding()
}
