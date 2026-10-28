import SwiftUI

// GEN-DEMO: sample results must never read as the person's own, so every screen showing them carries this.
struct GenomeDemoBanner: View {
    var text: String?

    static let fallback = "Demo data: sample results from Bright's demo genome, not your DNA."

    var body: some View {
        HStack(alignment: .top, spacing: .spacing2x) {
            GenomeDemoChip()
            BrightText(text ?? Self.fallback, size: .body3, color: .defaultAmber)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.defaultAmber.opacity(.minimalOpacity), in: RoundedRectangle(cornerRadius: .spacing2x))
        .accessibilityElement(children: .combine)
    }
}

struct GenomeDemoChip: View {
    var body: some View {
        BrightText("DEMO", size: .body3, color: .defaultAmber, weight: .semibold)
            .padding(.horizontal, .spacing1x)
            .padding(.vertical, .spacing05x)
            .background(Color.defaultAmber.opacity(.minimalOpacity), in: Capsule())
            .accessibilityLabel("Demo data")
    }
}

#Preview {
    VStack {
        GenomeDemoBanner()
        GenomeDemoChip()
    }
    .padding()
}
