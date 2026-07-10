//
//  GenomeOrderSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct GenomeOrderSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct Panel: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    private let panels: [Panel] = [
        Panel(icon: ImageNames.genomeOrderDnaV5,
              title: "30x Whole Genome Sequencing",
              detail: "Analysis of your complete 3.2B DNA letters, providing significantly more genetic information than standard DNA tests."),
        Panel(icon: ImageNames.genomeOrderRiskV5,
              title: "Polygenic Risk Scores",
              detail: "Advanced genetic risk assessments for a wide range of common health conditions."),
        Panel(icon: ImageNames.genomeOrderInsightsV5,
              title: "Personalized Health Risk Insights",
              detail: "Understand your genetic predisposition to common conditions including cardiovascular disease, diabetes, certain cancers, neurological conditions, and more."),
        Panel(icon: ImageNames.genomeOrderCancerV5,
              title: "Cancer Risk Screening",
              detail: "Insights into inherited genetic variants associated with multiple cancer types."),
        Panel(icon: ImageNames.genomeOrderMentalV5,
              title: "Mental Health & Cognitive Traits",
              detail: "Explore genetic factors linked to traits such as ADHD, anxiety, depression, sleep patterns, and cognitive performance."),
        Panel(icon: ImageNames.genomeOrderNutritionV5,
              title: "Nutrition & Wellness Insights",
              detail: "Discover how your genetics may influence nutrient metabolism, food sensitivities, caffeine processing, and other wellness-related traits."),
        Panel(icon: ImageNames.genomeOrderFitnessV5,
              title: "Fitness & Performance Traits",
              detail: "Learn about genetic factors related to exercise response, recovery, endurance, and strength potential."),
    ]

    var body: some View {
        BrightPageSheetView(horizontalPadding: .spacing0x, backgroundColor: .black) {
            ScrollView {
                VStack(spacing: .spacing0x) {
                    hero
                    includedList
                }
                .padding(.bottom, .spacing10x)
            }
            .scrollIndicators(.hidden)
            .background(alignment: .top) {
                Image(ImageNames.genomeOrderBackgroundV5)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, alignment: .top)
                    .blur(radius: 20, opaque: true)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(.minimalOpacity), location: 0),
                                .init(color: .black.opacity(.veryLowOpacity), location: 0.7),
                                .init(color: .black, location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .ignoresSafeArea()
            }
            .overlay(alignment: .bottom) {
                purchaseButton
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: .spacing3x) {
            Image(ImageNames.genomeOrderDnaHeroV5)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)

            BrightText("Order your genome test", size: .standout4, color: .white)
                .multilineTextAlignment(.center)

            BrightText(
                "Bright has partnered with The Genome Computer Company to provide streamlined access to a Whole Genome Sequence test.",
                size: .body3,
                color: .white
            )
            .multilineTextAlignment(.center)

            VStack(spacing: .spacing2x) {
                BrightText("What's included", size: .body3, color: .white)
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.white.opacity(.minimalOpacity)))
            }
            .padding(.top, .spacing4x)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, .spacing4x)
        .padding(.horizontal, .spacing6x)
    }

    // MARK: Included list

    private var includedList: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            ForEach(Array(panels.enumerated()), id: \.element.id) { index, panel in
                VStack(alignment: .leading, spacing: .spacing105x) {
                    Image(panel.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: .spacing4x, height: .spacing4x)

                    BrightText(panel.title, size: .body1, color: .white)

                    BrightText(panel.detail, size: .body3, color: .white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if index < panels.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(.ultraLowOpacity))
                        .frame(height: 0.5)
                }
            }
        }
        .padding(.spacing3x)
        .modifier(GlassCardModifier())
        .padding(.horizontal, .spacing3x)
    }

    private var purchaseButton: some View {
        BrightFullWidthButton("Purchase", horizontalPadding: .spacing6x) { dismiss() }
    }
}

#Preview {
    GenomeOrderSheet()
}
