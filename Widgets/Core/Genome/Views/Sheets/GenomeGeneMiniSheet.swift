//
//  GenomeGeneMiniSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 14/7/2026.
//

import SwiftUI

struct GenomeGeneMiniSheet: View {
    let marker: GenomeDataMarker
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            VStack(alignment: .leading, spacing: .spacing1x) {
                BrightText(marker.gene, size: .heading, color: marker.color)
                    .padding(.trailing, 52)

                if let level = marker.evidenceLevel {
                    BrightStatus(status: GenomeEvidenceLevel(level).label)
                }
            }

            if let result = marker.resultLabel ?? nonEmpty(marker.rawValue) {
                section(icon: "questionmark.circle", iconColor: marker.color,
                        title: "Your result", body: result)
            }

            if let meaning = marker.meaning {
                Divider().overlay(Color.white.opacity(.veryMinimalOpacity))

                section(icon: "person.fill", iconColor: .defaultCyan,
                        title: "What it means", body: meaning)
            }

            footer
        }
        .padding([.top, .horizontal], .spacing4x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)
                .padding(.top, .spacing3x)
                .padding(.trailing, .spacing3x)
        }
    }

    @ViewBuilder
    private var footer: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            if let rsid = marker.rsid {
                detailLine("Variant", rsid)
            }
            if let alleles = marker.alleles, !alleles.isEmpty {
                detailLine("Alleles", alleles.joined(separator: ", "))
            }
            if let populations = marker.validatedPopulations, !populations.isEmpty {
                detailLine("Validated in", populations.joined(separator: ", "))
            }
            if let basis = marker.evidenceBasis {
                detailLine("Source", basis)
            }
            if let sequence = marker.sequenceContext, sequence.available, let display = sequence.displaySequence {
                BrightText("Sequence", size: .body5, color: .lightTextColor)
                BrightText(display, size: .body4)
                    .monospaced()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func section(icon: String, iconColor: Color, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            Image(systemName: icon)
                .font(.standard(size: .standout3, weight: .semibold))
                .foregroundStyle(iconColor)
            BrightText(title, size: .body1, color: .semiLightTextColor)
            BrightText(body, size: .body3, color: .lightTextColor)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(.lineSpacingMedium)
        }
    }

    private func detailLine(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: .spacing2x) {
            BrightText(label, size: .body5, color: .lightTextColor)
                .frame(width: 90, alignment: .leading)
            BrightText(value, size: .body4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func nonEmpty(_ value: String) -> String? {
        value.isEmpty ? nil : value
    }
}
