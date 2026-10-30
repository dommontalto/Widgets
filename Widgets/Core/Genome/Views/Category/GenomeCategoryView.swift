//
//  GenomeCategoryView.swift
//  Widgets
//

import SwiftUI

struct GenomeCategoryView: View {
    let category: GenomeCategory
    var onSelectMarker: (String) -> Void = { _ in }

    @State private var detail: GenomeCategoryDetail?

    private var markers: [GenomeCategoryMarker] {
        detail?.markers ?? []
    }

    private var featured: [GenomeCategoryMarker] {
        markers.filter(\.isFeatured)
    }

    private var others: [GenomeCategoryMarker] {
        markers.filter { !$0.isFeatured }
    }


    var body: some View {
        BrightPageViewV5(title: category.title) {
            VStack(alignment: .leading, spacing: .spacing3x) {
                if let percentileBar = detail?.percentileBar {
                    BrightWaveWidgetV5(
                        title: "Genetic Risk Percentile",
                        fraction: Double(percentileBar.value) / 100,
                        emptySubtitle: "",
                        style: .genome
                    )

                    if let description = percentileBar.displayDescription {
                        BrightText(description, size: .body4, color: .lightTextColor, weight: .regular)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(.lineSpacingMedium)
                            .padding(.horizontal, .spacing1x)
                    }
                }

                if !featured.isEmpty {
                    section(title: "Leading contributors", markers: featured)
                }

                if !others.isEmpty {
                    section(title: "All markers", markers: others)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, .spacing3x)
        }
        .onAppear {
            detail = GenomeDemo.categoryDetail(id: category.id)
        }
    }

    private func section(title: String, markers: [GenomeCategoryMarker]) -> some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightText(title, size: .standout2)
                .padding(.leading, .spacing2x)
            VStack(spacing: .spacing2x) {
                ForEach(markers) { marker in
                    Button {
                        onSelectMarker(marker.canonicalName)
                    } label: {
                        GenomeCategoryMarkerRow(marker: marker)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct GenomeCategoryMarkerRow: View {
    let marker: GenomeCategoryMarker

    var body: some View {
        HStack(alignment: .center, spacing: .spacing3x) {
            VStack(alignment: .leading, spacing: .spacing1x) {
                HStack(spacing: .spacing2x) {
                    Image(marker.imageName)
                        .resizable()
                        .frame(width: 24, height: 24)
                    BrightText(marker.gene, size: .body1)
                }
                BrightText(marker.subtitle, size: .body4, color: .lightTextColor)
            }

            Spacer()

            trailing
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5())
    }

    private var trailing: some View {
        VStack(alignment: .trailing, spacing: .spacing1x) {
            if let scoreText = marker.scoreText {
                BrightText(scoreText, size: .subheading1, color: marker.scoreColor)
                    .monospacedDigit()
            }

            HStack(spacing: .spacing1x) {
                if let level = marker.evidenceLevel {
                    Circle()
                        .fill(GenomeEvidenceLevel(level).color)
                        .frame(width: 6, height: 6)
                }
                if !marker.rawValue.isEmpty {
                    BrightText(marker.rawValue, size: .body4, color: .lightTextColor)
                        .monospaced()
                }
            }
        }
    }
}
