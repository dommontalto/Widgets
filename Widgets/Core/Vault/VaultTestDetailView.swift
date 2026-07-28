//
//  VaultTestDetailView.swift
//  Widgets
//
//  Created by Dom Montalto on 7/7/2026.
//

import SwiftUI

struct VaultTestDetailView: View {
    let panel: VaultTestPanel

    @State private var showingServices = false

    private struct IncludedTest: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
    }

    private let tests: [IncludedTest] = [
        IncludedTest(
            title: "Blood",
            detail: "Clinical lab White Blood Cells (WBC), Red Blood Cells (RBC), Hemoglobin, Hematocrit, MCV, MCH, MCHC, RDW, Platelets, Neutrophils, Lymphocytes, Monocytes, Eosinophils and Basophils."
        ),
        IncludedTest(
            title: "Hormones (Male)",
            detail: "Total Testosterone, Free Testosterone, SHBG, DHEA-S LH, FSH and Estradiol."
        ),
        IncludedTest(
            title: "Longevity",
            detail: "Clinical lab tests focus on metabolic, cardiovascular, hormone, thyroid, liver, kidney, nutrient, inflammation and toxin markers."
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: .spacing0x) {
                banner
                includedList
            }
            .padding(.bottom, .spacing10x)
        }
        .scrollIndicators(.hidden)
        .background(Color.sheetBackground)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .bottom) {
            BrightFullWidthButton("Find tests", horizontalPadding: .spacing6x) {
                showingServices = true
            }
        }
        .navigationDestination(isPresented: $showingServices) {
            VaultTestingServicesView()
        }
    }

    private var banner: some View {
        VaultTestPanelCard(panel: panel, cornerRadius: .spacing0x)
            .frame(maxWidth: .infinity)
            .frame(height: 318)
    }

    private var includedList: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            BrightText("Tests included", size: .standout4, weight: .regular)

            ForEach(tests) { test in
                VStack(alignment: .leading, spacing: .spacing105x) {
                    Image(ImageNames.vaultTestFigureV5)
                        .resizable()
                        .scaledToFit()
                        .frame(width: .spacing4x, height: .spacing4x)

                    BrightText(test.title, size: .body1, weight: .regular)

                    BrightText(test.detail, size: .body3, color: .lightTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.spacing3x)
    }
}

#Preview {
    NavigationStack {
        VaultTestDetailView(panel: VaultTestPanel.demo[2])
    }
}
