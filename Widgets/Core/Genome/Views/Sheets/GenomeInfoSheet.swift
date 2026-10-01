//
//  GenomeInfoSheet.swift
//  Widgets
//

import SwiftUI

struct GenomeInfoSheet: View {
    var body: some View {
        BrightPageSheetViewV5(title: "About Genome") {
            content
        }
    }

    var content: some View {
        ScrollView {
            VStack(spacing: .spacing4x) {
                Image(ImageNames.genomeV5)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)

                BrightText(
                    description1,
                    size: .body2,
                    color: .lightTextColor
                )
                .lineSpacing(.lineSpacingMedium)

                BrightDividerV5()

                VStack(alignment: .leading, spacing: .spacing6x) {
                    Section(
                        image: ImageNames.genomeOrderRiskV5,
                        title: "Polygenic risk score",
                        content: prsDescription
                    )

                    Section(
                        image: ImageNames.genomeOrderInsightsV5,
                        title: "Percentiles",
                        content: percentileDescription
                    )

                    Section(
                        image: ImageNames.genomeLongevityV5,
                        title: "Impact categories",
                        content: impactDescription
                    )

                    Section(
                        image: ImageNames.genomeOrderDnaIconV5,
                        title: "Leading contributors",
                        content: contributorsDescription
                    )
                }
            }
            .padding(.top, .spacing1x)
        }
        .scrollIndicators(.hidden)
    }

    struct Section: View {
        var image: String?
        let title: String
        let content: String

        var body: some View {
            VStack(alignment: .leading, spacing: .spacing2x) {
                HStack(spacing: .spacing1x) {
                    if let image {
                        Image(image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    }
                    BrightText(
                        title,
                        size: .subheading,
                        color: .semiLightTextColor
                    )
                }
                BrightText(
                    content,
                    size: .body2,
                    color: .lightTextColor
                )
                .lineSpacing(.lineSpacingMedium)
            }
        }
    }
}

#Preview {
    GenomeInfoSheet()
}

private let description1 = "Your genome offers a window into how your body is built to respond to exercise, nutrition, sleep and more. Bright analyses your genetic data to surface meaningful, science-backed insights that help you personalise your health decisions."
private let prsDescription = "A polygenic risk score (PRS) combines the effects of many genetic variants across your genome into a single score for a given trait or condition. Rather than looking at one gene in isolation, it captures the cumulative influence of thousands of variants to estimate your genetic predisposition."
private let percentileDescription = "Your score is shown as a percentile against a matched reference cohort. For example, the 70th percentile means your genetic predisposition is higher than 70% of people in the cohort. A higher percentile is not a diagnosis — lifestyle, environment and other factors all play a significant role."
private let impactDescription = "Impact categories group your genetic insights into areas such as recovery, sleep, nutrition and cardiovascular health. Explore each category to see the markers analysed and how they may influence that area of your health."
private let contributorsDescription = "Leading contributors are the individual genes and variants with the strongest influence on a score. Understanding your top contributors helps you see which parts of your genome are driving a result and where personalised changes may have the most benefit."
