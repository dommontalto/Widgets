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
    let detail: String
    let backgroundName: String
    let gradientTopColor: Color
    var iconName: String?
    var systemImage: String?

    static let demo: [VaultTestPanel] = [
        VaultTestPanel(
            id: "longevity",
            name: "Longevity",
            detail: "Biomarkers linked to biological aging, inflammation, organ function, cardiovascular risk, nutrient status, and long-term disease risk.",
            backgroundName: ImageNames.vaultTestLongevityBackgroundV5,
            gradientTopColor: .vaultGoalLongevityTop,
            systemImage: "figure"
        ),
        VaultTestPanel(
            id: "hormones",
            name: "Hormones",
            detail: "Sex, thyroid, adrenal, and metabolic hormones that influence energy, mood, libido, weight, sleep, and reproductive health.",
            backgroundName: ImageNames.vaultTestHormonesBackgroundV5,
            gradientTopColor: .vaultGoalHormonesTop,
            iconName: ImageNames.vaultTestHormonesIconV5
        ),
        VaultTestPanel(
            id: "gut",
            name: "Gut Health",
            detail: "Digestive function, gut microbiome composition, inflammation, pathogens, food sensitivities, and markers of nutrient absorption.",
            backgroundName: ImageNames.vaultTestGutHealthBackgroundV5,
            gradientTopColor: .vaultGoalGutHealthTop,
            iconName: ImageNames.vaultTestGutHealthIconV5
        ),
        VaultTestPanel(
            id: "metabolic",
            name: "Metabolic Health",
            detail: "Blood sugar regulation, insulin sensitivity, cholesterol, liver function, kidney function, inflammation, and cardiovascular risk.",
            backgroundName: ImageNames.vaultTestMetabolicHealthBackgroundV5,
            gradientTopColor: .vaultGoalMetabolicTop,
            iconName: ImageNames.vaultTestMetabolicHealthIconV5
        ),
        VaultTestPanel(
            id: "fertility",
            name: "Fertility",
            detail: "Reproductive hormones, ovarian reserve or sperm health, cycle function, thyroid status, and other markers that may affect conception.",
            backgroundName: ImageNames.vaultTestFertilityBackgroundV5,
            gradientTopColor: .vaultGoalFertilityTop,
            iconName: ImageNames.vaultTestFertilityIconV5
        ),
    ]
}

struct VaultTestsSheet: View {
    var onTestSelected: (VaultTestPanel) -> Void = { _ in }
    var onDismiss: () -> Void = {}

    @State private var isShowing = false
    @State private var isClosing = false
    @State private var activeIndex: Int? = 0
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

                    BrightCarousel(items: panels, activeIndex: $activeIndex) { panel, width in
                        VaultTestPanelCard(panel: panel)
                            .frame(width: width, height: width * 1.25)
                    }

                    BrightPageIndicator(total: panels.count, activeIndex: $activeIndex)
                        .opacity(isShowing ? 1 : 0)
                        .padding(.top, .spacing6x)

                    Spacer()
                }

                VStack {
                    Spacer()

                    BrightFullWidthButton("Find tests", horizontalPadding: .spacing6x) {
                        onTestSelected(visiblePanel)
                        showingDetail = true
                    }
                    .opacity(isShowing ? 1 : 0)
                }
            }
            .background(goalGradientBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $showingDetail) {
                VaultTestDetailView(panel: visiblePanel)
            }
            .navigationTitle("What's your goal?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrightText("What's your goal?", size: .body1, color: .defaultMainBlack, weight: .medium)
                }

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

    // MARK: Background

    private let gradientTopLocation: CGFloat = 1 - 0.89532
    private let gradientBottomLocation: CGFloat = 1 - 0.01663

    private var goalGradientBackground: some View {
        ZStack {
            ForEach(Array(panels.enumerated()), id: \.element.id) { index, panel in
                LinearGradient(
                    stops: [
                        .init(color: panel.gradientTopColor, location: gradientTopLocation),
                        .init(color: .sheetBackground, location: gradientBottomLocation),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(index <= (activeIndex ?? 0) ? 1 : 0)
            }
        }
        .animation(.brightEaseInOut, value: activeIndex)
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
