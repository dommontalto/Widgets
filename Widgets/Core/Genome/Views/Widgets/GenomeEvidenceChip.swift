import SwiftUI

/// How strong the science behind a genome result is, in the evidence colours (as web and the category sheet's dot).
/// Not BrightStatus: that's the lab-range chip, where "HIGH" and "LOW" are red and read as a bad result.
struct GenomeEvidenceChip: View {
    let level: GenomeEvidenceLevel

    var body: some View {
        BrightText(level.label.uppercased(), size: .body3, color: level.color, weight: .light)
            .padding(.spacing1x)
            .background(level.color.opacity(.minimalOpacity), in: Capsule())
    }
}

#Preview {
    VStack {
        GenomeEvidenceChip(level: .high)
        GenomeEvidenceChip(level: .moderate)
        GenomeEvidenceChip(level: .low)
        GenomeEvidenceChip(level: .exploratory)
    }
}
