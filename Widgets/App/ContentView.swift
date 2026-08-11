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
    @State private var showingWorkout = false
    @State private var showingAddWorkouts = false
    @State private var showingExerciseDetail = false
    @State private var showingBeam = false
    @State private var beamTarget = BeamTarget.screen
    @State private var screenBeam = BeamConfig.screen
    @State private var cardBeam = BeamConfig.card
    @State private var builder = ExerciseBuilder()
    @State private var workoutStage: ExerciseWorkoutStage?

    var body: some View {
        NavigationStack {
            content
        }
        .environment(builder)
    }

    private var workouts: [ExerciseQuickWorkout] {
        builder.saved
    }

    private func start(_ workout: ExerciseQuickWorkout) {
        workoutStage = workout.isCardio ? .cardio : .preWorkout(workout)
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing3x) {
                section("Exercise") {
                    VStack(alignment: .leading, spacing: .spacing2x) {
                        addWorkoutsButton
                        viewExerciseButton
                    }
                    .padding(.top, .spacing2x)
                    .padding(.bottom, .spacing3x)

                    widgetLabel("ExerciseUpcomingWidget")
                    ExerciseUpcomingWidget { workout in
                        start(workout)
                    }
                        .padding(.bottom, .spacing3x)

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
                Menu {
                    Section("Saved Workouts") {
                        ForEach(workouts) { workout in
                            Button(workout.name, systemImage: workout.symbol) {
                                start(workout)
                            }
                        }
                    }
                } label: {
                    Label("Start workout", systemImage: "play.fill")
                        .labelStyle(.iconOnly)
                } primaryAction: {
                    showingWorkout = true
                }
            }
        }
        .sheet(isPresented: $showingWorkout) {
            ExerciseSheet()
        }
        .sheet(isPresented: $showingAddWorkouts) {
            ExerciseAddWorkoutsSheet()
        }
        .sheet(isPresented: $showingExerciseDetail) {
            if let exercise = ExerciseDemoLibrary.exercise(named: "Squat") {
                BrightPageSheetView(title: exercise.name, horizontalPadding: .spacing0x) {
                    ExerciseDetailSheet(exercise: exercise)
                }
            }
        }
        .fullScreenCover(isPresented: $showingBeam) {
            beamScreen
        }
        .exerciseWorkoutFlow($workoutStage)
        .sheet(isPresented: $showingOrder) {
            GenomeOrderSheet()
        }
        .sheet(isPresented: $showingVaultTests) {
            VaultTestsSheet(onDismiss: {
                showingVaultTests = false
            })
        }
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

    // Matches the live workout sheet's set row — same width inset, corner and
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

    private var addWorkoutsButton: some View {
        Button {
            showingAddWorkouts = true
        } label: {
            BrightText("ExerciseAddWorkoutsSheet", size: .body2, weight: .regular)
                .padding(.horizontal, .spacing3x)
                .padding(.vertical, .spacing105x)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.textColor.opacity(.minimalOpacity), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var viewExerciseButton: some View {
        Button {
            showingExerciseDetail = true
        } label: {
            BrightText("ExerciseDetailSheet", size: .body2, weight: .regular)
                .padding(.horizontal, .spacing3x)
                .padding(.vertical, .spacing105x)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.textColor.opacity(.minimalOpacity), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
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
