//
//  GenomeCategorySheet.swift
//  Widgets
//

import SwiftUI

struct GenomeCategorySheet: View {
    let category: GenomeCategory
    var dataMarkers: [GenomeDataMarker] = []

    @State private var detail: GenomeCategoryDetail?
    @State private var selectedMarker: GenomeDataMarker?

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
        BrightPageSheetViewV5 {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing3x) {
                    header

                    if let percentileBar = detail?.percentileBar {
                        GenomePercentileBarWidget(data: percentileBar)
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
            .scrollIndicators(.hidden)
        }
        .brightMiniSheetV5(isPresented: markerShown) {
            if let marker = selectedMarker {
                GenomeGeneMiniSheet(marker: marker) { selectedMarker = nil }
            }
        }
        .onAppear {
            detail = GenomeDemo.categoryDetail(id: category.id)
        }
    }

    private var markerShown: Binding<Bool> {
        Binding(
            get: { selectedMarker != nil },
            set: { if !$0 { selectedMarker = nil } }
        )
    }

    private var header: some View {
        HStack(spacing: .spacing2x) {
            Image(category.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: .spacing5x, height: .spacing5x)
            BrightText(category.title, size: .standout3)
        }
    }

    private func section(title: String, markers: [GenomeCategoryMarker]) -> some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightText(title, size: .standout2)
                .padding(.leading, .spacing2x)
            ForEach(markers) { marker in
                Button {
                    selectedMarker = dataMarkers.first { $0.canonicalName == marker.canonicalName }
                } label: {
                    GenomeCategoryMarkerRow(marker: marker)
                }
                .buttonStyle(.plain)
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
        .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))
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
