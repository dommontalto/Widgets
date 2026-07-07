//
//  VaultTestsSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 7/7/2026.
//

import SwiftUI

struct VaultTestPanel: Identifiable, Hashable {
    let id: String
    let name: String
    let imageName: String
    let bannerName: String

    static let demo: [VaultTestPanel] = [
        VaultTestPanel(
            id: "longevity",
            name: "Longevity",
            imageName: ImageNames.vaultTestLongevityCardV5,
            bannerName: ImageNames.vaultTestLongevityBannerV5
        ),
        VaultTestPanel(
            id: "hormones",
            name: "Hormones",
            imageName: ImageNames.vaultTestHormonesCardV5,
            bannerName: ImageNames.vaultTestHormonesBannerV5
        ),
        VaultTestPanel(
            id: "gut",
            name: "Gut Health",
            imageName: ImageNames.vaultTestGutHealthCardV5,
            bannerName: ImageNames.vaultTestGutHealthBannerV5
        ),
        VaultTestPanel(
            id: "metabolic",
            name: "Metabolic Health",
            imageName: ImageNames.vaultTestMetabolicHealthCardV5,
            bannerName: ImageNames.vaultTestMetabolicHealthBannerV5
        ),
        VaultTestPanel(
            id: "fertility",
            name: "Fertility",
            imageName: ImageNames.vaultTestFertilityCardV5,
            bannerName: ImageNames.vaultTestFertilityBannerV5
        ),
    ]
}

struct VaultTestsSheet: View {
    var onTestSelected: (VaultTestPanel) -> Void = { _ in }
    var onDismiss: () -> Void = {}

    @State private var isShowing = false
    @State private var isClosing = false
    @State private var scrollPosition: ScrollPosition = .init(idType: VaultTestPanel.ID.self)
    @State private var activeIndex: Int? = 0
    @State private var hapticTrigger = 0
    @State private var carouselWidth: CGFloat = 0
    @State private var showingDetail = false

    private let panels = VaultTestPanel.demo

    private var visiblePanel: VaultTestPanel {
        guard let index = activeIndex, index >= 0, index < panels.count else {
            return panels[0]
        }
        return panels[index]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: .spacing0x) {
                    Spacer()

                    panelCarousel

                    pageIndicator
                        .opacity(isShowing ? 1 : 0)
                        .padding(.top, .spacing6x)

                    Spacer()
                }

                VStack {
                    Spacer()

                    BrightFullWidthButton("Find tests") {
                        onTestSelected(visiblePanel)
                        showingDetail = true
                    }
                    .opacity(isShowing ? 1 : 0)
                    .padding(.horizontal, .spacing4x)
                }
            }
            .background(Color.sheetBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $showingDetail) {
                VaultTestDetailView(panel: visiblePanel)
            }
            .navigationTitle("What's your goal?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        close()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        showingDetail = true
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.brightBouncy) {
                isShowing = true
            }
        }
    }

    // MARK: Carousel

    private var cardWidth: CGFloat {
        guard carouselWidth > 0 else { return 200 }
        return carouselWidth * 0.65
    }

    private var horizontalInset: CGFloat {
        guard carouselWidth > 0 else { return .spacing4x }
        return (carouselWidth - cardWidth) / 2
    }

    private var panelCarousel: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing05x) {
                ForEach(panels) { panel in
                    panelCard(panel)
                        .frame(width: cardWidth)
                        .contentShape(Rectangle())
                        .scrollTransition(.animated(.brightBouncy)) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.5)
                                .scaleEffect(phase.isIdentity ? 1 : 0.85)
                        }
                        .id(panel.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition($scrollPosition)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .contentMargins(.horizontal, horizontalInset, for: .scrollContent)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            carouselWidth = width
        }
        .onScrollTargetVisibilityChange(idType: VaultTestPanel.ID.self, threshold: 0.5) { visible in
            if let first = visible.first,
               let index = panels.firstIndex(where: { $0.id == first }) {
                activeIndex = index
                hapticTrigger += 1
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hapticTrigger)
    }

    private func panelCard(_ panel: VaultTestPanel) -> some View {
        Image(panel.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: cardWidth, height: cardWidth * 1.25)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius40))
    }

    // MARK: Page indicator

    private var pageIndicator: some View {
        HStack(spacing: .spacing1x) {
            ForEach(panels.indices, id: \.self) { index in
                Circle()
                    .fill(index == activeIndex ? Color.textColor : Color.lightTextColor)
                    .frame(width: .spacing1x, height: .spacing1x)
            }
        }
        .animation(.brightEaseInOut, value: activeIndex)
        .padding(.horizontal, .spacing2x)
        .frame(height: .spacing5x)
        .modifier(GlassEffect())
    }

    private func close() {
        guard !isClosing else { return }
        isClosing = true
        onDismiss()
    }
}

#Preview {
    ZStack {
        Color.bG.ignoresSafeArea()
        VaultTestsSheet()
    }
}
