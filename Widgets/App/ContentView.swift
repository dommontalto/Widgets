//
//  ContentView.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSession = false
    @State private var showingChat = false
    @State private var showingProgram = false
    @State private var showingBeam = false
    @State private var beamTarget = BeamTarget.screen
    @State private var screenBeam = BeamConfig.screen
    @State private var cardBeam = BeamConfig.card
    @State private var builder = ExerciseBuilder()
    @State private var sessionStage: ExerciseSessionStage?
    @State private var openedExerciseName: String?
    @State private var showingRecordSession = false
    @State private var recordSessionPart = 0

    var body: some View {
        NavigationStack {
            content
        }
        .environment(builder)
    }

    private var sessions: [ExerciseQuickSession] {
        builder.saved
    }

    private func start(_ session: ExerciseQuickSession) {
        sessionStage = .setup(for: session, leg: 0)
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing3x) {
                section("Exercise") {
                    widgetLabel("ExerciseUpcomingWidget")
                    ExerciseWidgetSection(icon: .symbol("list.bullet.indent"), title: "Upcoming") {
                        ExerciseUpcomingWidget(
                            onQuickSession: { session in start(session) },
                            onCreateSession: { showingSession = true }
                        )
                    }
                        .padding(.top, .spacing2x)
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseWeeklyPlanWidget")
                    ExerciseWidgetSection(icon: .asset(ImageNames.exerciseCalendarV5), title: "Weekly plan (Demo Data)") {
                        ExerciseWeeklyPlanWidget {
                            showingProgram = true
                        }
                    }
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseHistoryWidget")
                    ExerciseWidgetSection(icon: .symbol("backward.end.alt"), title: "Session history") {
                        ExerciseHistoryWidget()
                    }
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExercisePersonalRecordsWidget")
                    ExerciseWidgetSection(
                        icon: .symbol("star.square.on.square.fill"),
                        title: "Personal Records"
                    ) {
                        ExercisePersonalRecordsWidget(
                            records: ExerciseDemoComplete.strength.records + ExerciseDemoComplete.cardio.records,
                            cardColor: .defaultCards,
                            onSelectExercise: { openedExerciseName = $0 },
                            onSelectSession: { record in
                                recordSessionPart = record.logId == "demo-cardio" ? 1 : 0
                                showingRecordSession = true
                            }
                        )
                    }
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseScoresWidget")
                    ExerciseScoresWidget()
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseConsistencyWidget")
                    ExerciseWidgetSection(icon: .symbol("list.bullet.indent"), title: "Consistency") {
                        ExerciseConsistencyWidget()
                    }
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseTrainingLoadWidget")
                    ExerciseWidgetSection(icon: .asset(ImageNames.exerciseTrainingLoadV5), title: "Training load") {
                        ExerciseTrainingLoadWidget()
                    }
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseProgramPhaseWidget")
                    ExerciseWidgetSection(icon: .symbol("list.bullet.indent"), title: "Program Phase") {
                        ExerciseProgramPhaseWidget()
                    }
                        .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseBodymapWidget")
                    ExerciseWidgetSection(icon: .symbol("list.bullet.indent"), title: "Bodymap") {
                        ExerciseBodymapWidget()
                    }
                        .padding(.bottom, .spacing3x)
                }
            }
            .padding(.spacing3x)
        }
        .background(Color.defaultBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingBeam = true
                } label: {
                    Label("Show beam", systemImage: "sparkles")
                        .labelStyle(.iconOnly)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingChat = true
                } label: {
                    Label("Create with AI", systemImage: "apple.intelligence")
                        .labelStyle(.iconOnly)
                }
            }

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
            ExerciseSheet()
        }
        .sheet(isPresented: $showingChat) {
            ExerciseChatSheet()
        }
        .sheet(isPresented: $showingProgram) {
            ExerciseCreateProgramSheet()
        }
        .sheet(isPresented: $showingRecordSession) {
            ExerciseCompleteSheet(
                sessions: [ExerciseDemoComplete.strength, ExerciseDemoComplete.cardio],
                initialPart: recordSessionPart
            )
        }
        .navigationDestination(item: $openedExerciseName) { name in
            if let exercise = ExerciseDemoLibrary.exercise(named: name) {
                ExerciseDetailSheet(exercise: exercise, cardColor: .defaultCards)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.defaultBackground.ignoresSafeArea())
            }
        }
        .fullScreenCover(isPresented: $showingBeam) {
            beamScreen
        }
        .exerciseSessionFlow($sessionStage)
    }

    private var beamScreen: some View {
        NavigationStack {
            VStack(spacing: .spacing3x) {
                beamCard
                    .padding(.top, .spacing2x)

                BeamControlsView(defaults: controlDefaults, config: controlBinding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.defaultBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingBeam = false
                    } label: {
                        Label("Close", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.brightSnappy) { beamTarget = beamTarget.next }
                    } label: {
                        Label(beamTarget.title, systemImage: beamTarget.symbol)
                    }
                    .brightHaptic(.light, trigger: beamTarget)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .overlay {
            BrightScreenEdgeBeam(
                isActive: screenBeam.isActive,
                cornerRadius: screenBeam.cornerRadius,
                colorVariant: screenBeam.colorVariant,
                size: screenBeam.size,
                duration: screenBeam.duration,
                brightness: screenBeam.brightness,
                saturation: screenBeam.saturation,
                strength: screenBeam.strength,
                renderScale: screenBeam.renderScale,
                tuning: screenBeam.tuning
            )
        }
        .statusBarHidden()
    }

    private var controlDefaults: BeamConfig {
        beamTarget == .card ? .card : .screen
    }

    private var controlBinding: Binding<BeamConfig> {
        beamTarget == .card ? $cardBeam : $screenBeam
    }

    // Matches the live session sheet's set row — same width inset, corner and
    // beam — with nothing in it.
    private var beamCard: some View {
        Color.clear
            .frame(height: Constants.beamCardHeight)
            .modifier(CardModifier(cornerRadius: .cornerRadius24))
            .borderBeam(
                cardBeam.size,
                colorVariant: cardBeam.colorVariant,
                theme: .auto,
                duration: cardBeam.duration,
                active: cardBeam.isActive,
                borderRadius: cardBeam.cornerRadius,
                brightness: cardBeam.brightness,
                saturation: cardBeam.saturation,
                strength: cardBeam.strength,
                tuning: cardBeam.tuning
            )
            .padding(.horizontal, .spacing3x)
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

    private enum Constants {
        static let beamCardHeight: CGFloat = 68
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
