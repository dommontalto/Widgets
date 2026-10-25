//
//  GenomeOrderSheet.swift
//  Widgets
//

import SwiftUI

struct GenomeOrderSheet: View {
    @Bindable var viewModel: GenomeOrderViewModel

    var body: some View {
        BrightPageSheetViewV5(horizontalPadding: .spacing0x, backgroundColor: .black) {
            ScrollView {
                VStack(spacing: .spacing0x) {
                    BrightPlaceholderViewV5(
                        image: ImageNames.genomeOrderDnaHeroV5,
                        title: "Order your genome test",
                        subtitle: "Bright has partnered with The Genome Computer Company to provide streamlined access to a Whole Genome Sequence test.",
                        fillsViewport: false
                    )
                    .environment(\.colorScheme, .dark)
                    .padding(.bottom, .spacing6x)

                    GenomeOrderIncludedList()
                }
            }
            .scrollIndicators(.hidden)
            .background(alignment: .top) {
                GenomeOrderWaves()
                    .ignoresSafeArea()
            }
            .brightBottomButtonV5 {
                GenomeOrderPurchaseButton(viewModel: viewModel)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(isPresented: $viewModel.showingCheckout) {
                BrightCheckoutViewV5(item: viewModel.checkoutItem, onPay: viewModel.handlePay)
                    .navigationDestination(isPresented: $viewModel.showingConfirmation) {
                        GenomeOrderConfirmationView(viewModel: viewModel)
                    }
            }
        }
    }
}

// The order sheet and tray's backdrop: the lighter blue waves drifting slowly on uneven
// periods so they never visibly loop, sinking into black towards the bottom.
struct GenomeOrderWaves: View {
    // Covers its whole frame in blue rather than fading into black below the image.
    var fills = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate * Constants.speed
            Image(ImageNames.genomeOrderBackgroundV5)
                .resizable()
                .aspectRatio(contentMode: fills ? .fill : .fit)
                .scaleEffect(Constants.scale + Constants.scaleSwing * sin(t / 5))
                .rotationEffect(.degrees(Constants.rotation * sin(t / 11)))
                .offset(x: Constants.drift * sin(t / 7), y: Constants.drift * 0.6 * cos(t / 9))
                .overlay {
                    LinearGradient(colors: [.defaultCyan, .defaultSkyBlue, .defaultDeepBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .blendMode(.color)
                }
                .frame(maxWidth: .infinity, maxHeight: fills ? .infinity : nil, alignment: .top)
                .clipped()
                .blur(radius: 20, opaque: true)
        }
        .overlay {
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(.minimalOpacity), location: 0),
                    .init(color: .black.opacity(.veryLowOpacity), location: 0.7),
                    .init(color: .black.opacity(fills ? .semiLowOpacity : 1), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private enum Constants {
        static let speed: Double = 2
        static let scale: CGFloat = 1.15
        static let scaleSwing: CGFloat = 0.06
        static let rotation: Double = 3
        static let drift: CGFloat = .spacing4x
    }
}

struct GenomeOrderIncludedList: View {
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
        .modifier(BrightCardModifierV5(isGlass: true))
        .padding(.horizontal, .spacing3x)
    }

}

struct GenomeOrderPurchaseButton: View {
    @Bindable var viewModel: GenomeOrderViewModel

    var body: some View {
        BrightPillButton("Purchase", buttonSize: .large, isLoading: viewModel.isStartingCheckout) {
            viewModel.handlePurchase()
        }
    }
}

#Preview {
    GenomeOrderSheet(viewModel: GenomeOrderViewModel())
}
