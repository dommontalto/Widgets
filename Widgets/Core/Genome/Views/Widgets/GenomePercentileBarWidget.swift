//
//  GenomePercentileBarWidget.swift
//  Widgets
//

import SwiftUI

struct GenomePercentileBarWidget: View {
    let data: GenomePercentileBar

    private var percentile: Int { data.value }

    private var ordinalSuffix: String {
        String(data.value.ordinalSuffix().dropFirst(String(data.value).count))
    }

    private let bgHeight: CGFloat = 13
    private let barHeight: CGFloat = 9
    private let markerWidth: CGFloat = 4
    private let markerHeight: CGFloat = 25

    private var gradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.genomePRSCyan,   location: 0.00),
                .init(color: Color.genomePRSGreen,  location: 0.58),
                .init(color: Color.genomePRSYellow, location: 0.72),
                .init(color: Color.genomePRSPink,   location: 0.86),
                .init(color: Color.genomePRSRed,    location: 1.00),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            headerSection
            percentileBar
            if let description = data.displayDescription {
                BrightText(description, size: .body4, color: Color.lightTextColor, weight: .regular)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(.lineSpacingMedium)
            }
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("Polygenic risk score", size: .body2, color: Color.lightTextColor, weight: .regular)

            VStack(alignment: .leading, spacing: .spacing1x) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                    BrightText("\(percentile)", size: .huge2)
                    BrightText("\(ordinalSuffix) percentile", size: .body2, color: Color.textColor, weight: .regular)
                }
                BrightText("Higher than \(percentile)% of your matched reference cohort", size: .body4, color: Color.lightTextColor, weight: .regular)
            }
        }
    }

    // MARK: Bar

    private var percentileBar: some View {
        GeometryReader { geo in
            let markerX = geo.size.width * CGFloat(percentile) / 100.0

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.defaultMainGrey.opacity(.lowOpacity))
                    .overlay(Capsule().stroke(Color.defaultMainGrey, lineWidth: 0.5))

                Capsule()
                    .fill(gradient)
                    .padding(2)
            }
            .frame(height: bgHeight)
            .frame(maxHeight: .infinity, alignment: .center)
            .overlay(
                ZStack {
                    Capsule()
                        .fill(Color.defaultSheetModalCards)
                        .frame(width: 8, height: markerHeight)
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: markerWidth, height: markerHeight)
                }
                .offset(x: markerX - 4),
                alignment: .leading
            )
            .zIndex(1)
        }
        .frame(height: bgHeight)
    }
}

#Preview {
    GenomePercentileBarWidget(data: GenomePercentileBar(
        value: 64,
        description: "Your genetics suggest you may lean towards being a morning person."
    ))
    .padding(.spacing3x)
    .background(Color.defaultBackground.ignoresSafeArea())
}
