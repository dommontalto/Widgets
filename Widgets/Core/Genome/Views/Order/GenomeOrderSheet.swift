//
//  GenomeOrderSheet.swift
//  Widgets
//

import SwiftUI

struct GenomeOrderSheet: View {
    @Bindable var viewModel: GenomeOrderViewModel

    @State private var showsOrder = false

    var body: some View {
        BrightPageSheetViewV5(horizontalPadding: .spacing0x, backgroundColor: .defaultSheetBackground) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing0x) {
                    GenomeOrderHero(viewModel: viewModel)

                    VStack(alignment: .leading, spacing: .spacing05x) {
                        BrightText(Constants.title, size: .heading)

                        BrightText(Constants.subtitle, size: .heading, color: .lightTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, .spacing4x)
                    .padding(.top, .spacing6x)
                    .padding(.bottom, .spacing4x)

                    GenomeOrderFeatures()
                        .padding(.horizontal, .spacing3x)
                }
            }
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > Constants.orderThreshold
            } action: { _, shows in
                withAnimation(.brightBouncy) { showsOrder = shows }
            }
            .ignoresSafeArea(edges: .top)
            .brightBottomButtonV5 {
                if showsOrder {
                    GenomeOrderPurchaseButton(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $viewModel.showingCheckout) {
                BrightCheckoutViewV5(item: viewModel.checkoutItem, onPay: viewModel.handlePay)
                    .navigationDestination(isPresented: $viewModel.showingConfirmation) {
                        GenomeOrderConfirmationView(viewModel: viewModel)
                    }
            }
        }
    }

    private enum Constants {
        static let title = "Order your test today"
        static let subtitle = "Bright has partnered with The Genome Computer Company to provide streamlined access to a Whole Genome Sequence test."
        static let orderThreshold: CGFloat = 320
    }
}

private struct GenomeOrderHero: View {
    @Bindable var viewModel: GenomeOrderViewModel

    @State private var strand = GenomeState()

    var body: some View {
        ZStack {
            BrightDNAStrandV5(state: strand)
            GenomeRungAnnotations(state: strand)
        }
        .allowsHitTesting(false)
        .frame(height: Constants.height)
        .frame(maxWidth: .infinity)
        .clipped()
        .overlay(alignment: .bottom) { band }
        .onAppear {
            strand.distance = Constants.cameraDistance
            strand.restDistance = Constants.cameraDistance
            strand.isOnScreen = true
        }
    }

    private var band: some View {
        HStack(spacing: .spacing2x) {
            GenomeOrderBadge()

            BrightText(Constants.title, size: .heading)

            Spacer(minLength: .spacing0x)

            BrightPillButton(Constants.order, systemImage: "arrow.right", buttonSize: .small, isLoading: viewModel.isStartingCheckout) {
                viewModel.handlePurchase()
            }
        }
        .padding(.horizontal, .spacing4x)
        .frame(height: Constants.bandHeight)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.defaultCyan.opacity(.ultraLowOpacity))
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: Constants.fadeStop),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(height: Constants.bandHeight + Constants.fadeHeight)
        }
    }

    private enum Constants {
        static let title = "Genome test"
        static let order = "Order"
        static let height: CGFloat = 400
        static let bandHeight: CGFloat = 80
        static let fadeHeight: CGFloat = .spacing8x
        static let fadeStop: CGFloat = 0.6
        static let cameraDistance: Float = 1.7
    }
}

private struct GenomeOrderFeatures: View {
    private enum Icon {
        case asset(String)
        case symbol(String, Color)
    }

    private struct Feature: Identifiable {
        let icon: Icon
        let title: String
        let detail: String

        var id: String { title }
    }

    private let features: [Feature] = [
        Feature(icon: .asset(ImageNames.genomeOrderDnaV5),
                title: "30x Whole Genome Sequencing",
                detail: "Analysis of your complete 3.2B DNA letters, providing significantly more genetic information than standard DNA tests."),
        Feature(icon: .asset(ImageNames.genomeOrderRiskV5),
                title: "Polygenic Risk Scores",
                detail: "Advanced genetic risk assessments for a wide range of common health conditions."),
        Feature(icon: .asset(ImageNames.genomeOrderInsightsV5),
                title: "Personalized Health Risk Insights",
                detail: "Understand your genetic predisposition to common conditions including cardiovascular disease, diabetes, certain cancers, neurological conditions, and more."),
        Feature(icon: .asset(ImageNames.genomeOrderCancerV5),
                title: "Cancer Risk Screening",
                detail: "Insights into inherited genetic variants associated with multiple cancer types."),
        Feature(icon: .symbol("brain.filled.head.profile", .defaultPurple),
                title: "Mental Health & Cognitive Traits",
                detail: "Explore genetic factors linked to traits such as ADHD, anxiety, depression, sleep patterns, and cognitive performance."),
        Feature(icon: .symbol("carrot.fill", .defaultGreen),
                title: "Nutrition & Wellness Insights",
                detail: "Discover how your genetics may influence nutrient metabolism, food sensitivities, caffeine processing, and other wellness-related traits."),
        Feature(icon: .symbol("figure.cooldown", .defaultOrange),
                title: "Fitness & Performance Traits",
                detail: "Learn about genetic factors related to exercise response, recovery, endurance, and strength potential."),
    ]

    var body: some View {
        VStack(spacing: .spacing3x) {
            ForEach(features) { feature in
                VStack(alignment: .leading, spacing: .spacing2x) {
                    HStack(spacing: .spacing1x) {
                        icon(feature.icon)
                            .frame(width: Constants.iconSize, height: Constants.iconSize)

                        BrightText(feature.title, size: .body2, color: .semiLightTextColor)
                    }

                    BrightText(feature.detail, size: .body3, color: .lightTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.spacing3x)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))
            }
        }
    }

    @ViewBuilder
    private func icon(_ icon: Icon) -> some View {
        switch icon {
        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFit()
        case .symbol(let name, let color):
            Image(systemName: name)
                .font(.system(size: Constants.symbolSize, weight: .light))
                .foregroundStyle(color)
        }
    }

    private enum Constants {
        static let iconSize: CGFloat = .spacing4x
        static let symbolSize: CGFloat = 18
    }
}

struct GenomeOrderPurchaseButton: View {
    @Bindable var viewModel: GenomeOrderViewModel

    var body: some View {
        BrightPillButton("Order", systemImage: "arrow.right", buttonSize: .large, selectedTint: .swipePagePillText, selectedFill: .swipePagePillBackground, isLoading: viewModel.isStartingCheckout) {
            viewModel.handlePurchase()
        }
    }
}

#Preview {
    GenomeOrderSheet(viewModel: GenomeOrderViewModel())
}
