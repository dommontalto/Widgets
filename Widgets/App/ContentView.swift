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
    @State private var showingSession = false
    @State private var builder = ExerciseSessionBuilder()
    @State private var startedSession: ExerciseQuickSession?
    @State private var isLoggingCardio = false

    var body: some View {
        NavigationStack {
            content
        }
        .environment(builder)
    }

    private var sessions: [ExerciseQuickSession] {
        ExerciseDemoSessions.all + builder.saved
    }

    private func start(_ session: ExerciseQuickSession) {
        if session.isCardio {
            isLoggingCardio = true
        } else {
            startedSession = session
        }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing3x) {
                section("Exercise") {
                    widgetLabel("ExercisePersonalRecordsWidget")
                    ExercisePersonalRecordsWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseScoresWidget")
                    ExerciseScoresWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseConsistencyWidget")
                    ExerciseConsistencyWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseTrainingLoadWidget")
                    ExerciseTrainingLoadWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseHistoryWidget")
                    ExerciseHistoryWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseUpcomingWidget")
                    ExerciseUpcomingWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseWeeklyPlanWidget")
                    ExerciseWeeklyPlanWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseProgramPhaseWidget")
                    ExerciseProgramPhaseWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseBodymapWidget")
                    ExerciseBodymapWidget()
                        .padding(.bottom, .spacing3x)
                }

                section("Vault") {
                    widgetLabel("VaultDatapointsWidget")
                    VaultDatapointsWidget()
                        .padding(.bottom, .spacing3x)

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
            }
            .padding(.spacing3x)
        }
        .background(Color.bG.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("My Sessions") {
                        ForEach(sessions) { session in
                            Button(session.name, systemImage: session.symbol) {
                                start(session)
                            }
                        }
                    }
                } label: {
                    Label("Start session", systemImage: "play.fill")
                        .labelStyle(.iconOnly)
                } primaryAction: {
                    showingSession = true
                }
            }
        }
        .sheet(isPresented: $showingSession) {
            ExerciseSessionSheet()
        }
        .sheet(item: $startedSession) { session in
            NavigationStack {
                ExerciseLiveSessionSheet(sessionName: session.name, templateItems: session.items)
            }
        }
        .fullScreenCover(isPresented: $isLoggingCardio) {
            ExerciseLiveCardioSheet { isLoggingCardio = false }
        }
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
                BrightTick(isTicked: isTicked)
            }
            .buttonStyle(.plain)

            BrightText(name, size: .body1, color: Color.lightTextColor, weight: .regular)
        }
    }
}

#Preview {
    ContentView()
}
