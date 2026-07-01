//
//  ContentView.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing3x) {
                section("Genome") {
                    widgetLabel("GenomePercentileGraphWidget")
                    GenomePercentileGraphWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("GenomePercentileBarWidget")
                    GenomePercentileBarWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("GenomeImpactContributorWidget")
                    GenomeImpactContributorWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("GenomeContributorWidget")
                    GenomeContributorWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("GenomeOrderWidget")
                    GenomeOrderWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("GenomeOrderStatusWidget")
                    GenomeOrderStatusWidget()
                        .padding(.bottom, .spacing3x)
                }

                section("Workout") {
                    widgetLabel("WorkoutConsistencyWidget")
                    WorkoutConsistencyWidget()
                        .padding(.bottom, .spacing3x)
                }

                section("Vault") {
                    widgetLabel("VaultDatapointsWidget")
                    VaultDatapointsWidget()
                        .padding(.bottom, .spacing3x)
                }
            }
            .padding(.spacing3x)
        }
        .background(Color.bG.ignoresSafeArea())
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(title, size: .standout1, weight: .medium)
            content()
        }
    }

    private func widgetLabel(_ name: String) -> some View {
        BrightText(name, size: .body1, color: Color.lightTextColor, weight: .regular)
    }
}

#Preview {
    ContentView()
}
