//
//  ContentView.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var showingOrder = false
    @State private var showingVaultTests = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing3x) {
                section("Vault") {
                    widgetLabel("VaultOverviewWidget")
                    VaultOverviewWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("VaultGuidedTestingCard")
                    VaultGuidedTestingCard {
                        withAnimation(.brightBouncy) {
                            showingVaultTests = true
                        }
                    }
                    .padding(.bottom, .spacing3x)
                    
                    widgetLabel("VaultDatapointsWidget")
                    VaultDatapointsWidget()
                        .padding(.bottom, .spacing3x)
                }
                
                section("Genome") {
                    widgetLabel("GenomeOrderWidget")
                    Button { showingOrder = true } label: {
                        GenomeOrderWidget()
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, .spacing3x)

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

                    widgetLabel("GenomeOrderStatusWidget")
                    GenomeOrderStatusWidget()
                        .padding(.bottom, .spacing3x)
                }

                section("Workout") {
                    widgetLabel("WorkoutConsistencyWidget")
                    WorkoutConsistencyWidget()
                        .padding(.bottom, .spacing3x)
                }
            }
            .padding(.spacing3x)
        }
        .background(Color.bG.ignoresSafeArea())
        .sheet(isPresented: $showingOrder) {
            GenomeOrderSheet()
        }
        .sheet(isPresented: $showingVaultTests) {
            VaultTestsSheet(onDismiss: {
                showingVaultTests = false
            })
        }
    }

    private var findTestsButton: some View {
        Button {
            withAnimation(.brightBouncy) {
                showingVaultTests = true
            }
        } label: {
            BrightText("Find tests", size: .body2, weight: .regular)
                .padding(.horizontal, .spacing3x)
                .padding(.vertical, .spacing105x)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.textColor.opacity(.minimalOpacity), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(title, size: .standout1, weight: .medium)
            content()
        }
    }

    private func widgetLabel(_ name: String) -> some View {
        WidgetLabelRow(name: name)
    }
}

private struct WidgetLabelRow: View {
    let name: String
    @AppStorage private var isTicked: Bool

    init(name: String) {
        self.name = name
        _isTicked = AppStorage(wrappedValue: false, "widgetTicked_\(name)")
    }

    var body: some View {
        HStack(spacing: .spacing1x) {
            Button {
                isTicked.toggle()
            } label: {
                if isTicked {
                    BrightTick()
                } else {
                    BrightEmptyTick()
                }
            }
            .buttonStyle(.plain)

            BrightText(name, size: .body1, color: Color.lightTextColor, weight: .regular)
        }
    }
}

#Preview {
    ContentView()
}
