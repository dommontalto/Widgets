//
//  ExerciseSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

enum ExerciseWorkoutRoute: Hashable {
    case category(ExerciseWorkoutCategory)
    case exercise(String)
    case newWorkout
    case newCardio
    // Carries the saved workout's id — the draft itself lives on the builder.
    case editWorkout(String)
}

struct ExerciseSheet: View {
    @Environment(ExerciseBuilder.self) private var builder

    @State private var workoutStage: ExerciseWorkoutStage?

    private let columns = [
        GridItem(.flexible(), spacing: .spacing2x),
        GridItem(.flexible(), spacing: .spacing2x),
    ]

    var body: some View {
        @Bindable var builder = builder

        return BrightPageSheetView(title: "Start Workout", horizontalPadding: .spacing0x, path: $builder.path) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .spacing4x) {
                    section("Workouts", cardio: false)

                    section("Cardio", cardio: true)
                }
                .padding(.spacing3x)
            }
            .safeAreaInset(edge: .bottom) {
                addButton
            }
            .navigationDestination(for: ExerciseWorkoutRoute.self) { route in
                destination(for: route)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: "Start Workout", file: #file)
                }
            }
        }
        .exerciseWorkoutFlow($workoutStage)
    }

    // MARK: - Saved workouts

    @ViewBuilder
    private func section(_ title: String, cardio: Bool) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(title, size: .subheading)

            if builder.savedWorkouts(cardio: cardio).isEmpty {
                placeholder(cardio: cardio)
            } else {
                LazyVGrid(columns: columns, spacing: .spacing2x) {
                    workoutCards(cardio: cardio)
                }
            }
        }
    }

    private func placeholder(cardio: Bool) -> some View {
        BrightPlaceholderView(
            systemImage: cardio ? "figure.run" : "dumbbell",
            title: cardio ? "No cardio yet" : "No workouts yet",
            subtitle: cardio
                ? "Save a run, ride or swim to start it from here."
                : "Build a workout to start it from here.",
            imageColor: cardio ? .defaultSkyBlue : .defaultPurple,
            buttonTitle: cardio ? "Create cardio" : "Create workout"
        ) {
            builder.path.append(
                cardio ? ExerciseWorkoutRoute.newCardio : ExerciseWorkoutRoute.category(.gym)
            )
        }
    }

    private func workoutCards(cardio: Bool) -> some View {
        ForEach(builder.savedWorkouts(cardio: cardio)) { workout in
            Button {
                workoutStage = workout.isCardio ? .cardio : .preWorkout(workout)
            } label: {
                workoutCard(workout)
            }
            .buttonStyle(.plain)
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
            .contextMenu {
                workoutMenu(for: workout)
            }
        }
    }

    private func workoutCard(_ workout: ExerciseQuickWorkout) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            Image(systemName: workout.symbol)
                .font(.standard(size: .heading, weight: .light))
                .foregroundStyle(workout.accentColor)
                .frame(width: Constants.iconSize, height: Constants.iconSize, alignment: .leading)
                .padding(.bottom, .spacing105x)

            BrightText(workout.name, size: .body2, color: .semiLightTextColor, weight: .regular)
                .lineLimit(1)

            BrightText(workout.subtitle, size: .body2, color: .lightTextColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing2x)
        .frame(height: Constants.cardHeight, alignment: .topLeading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    @ViewBuilder
    private func workoutMenu(for workout: ExerciseQuickWorkout) -> some View {
        Button("Duplicate", systemImage: "plus.square.on.square") {
            withAnimation(.brightSnappy) { builder.duplicate(workout) }
        }

        Button("Edit", systemImage: "pencil") {
            builder.loadDraft(from: workout)
            builder.path.append(ExerciseWorkoutRoute.editWorkout(workout.id))
        }

        Button("Delete", systemImage: "trash", role: .destructive) {
            withAnimation(.brightSnappy) { builder.delete(workout) }
        }
        .tint(.defaultRed)
    }

    // MARK: - Library

    private var addButton: some View {
        // The menu opens upward from the bottom-right button, so iOS lists the
        // last item nearest the finger — cardio is declared first to put Create
        // workout at the top.
        Menu {
            Button("Create cardio", systemImage: "figure.run") {
                builder.path.append(ExerciseWorkoutRoute.newCardio)
            }

            Button("Create workout", systemImage: "dumbbell") {
                builder.path.append(ExerciseWorkoutRoute.category(.gym))
            }
        } label: {
            BrightRoundButton(systemImage: "plus", size: .finalBossLarge)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.spacing3x)
    }

    // MARK: - Routing

    @ViewBuilder
    private func destination(for route: ExerciseWorkoutRoute) -> some View {
        switch route {
        case let .category(category):
            ExerciseCategorySheet(category: category)
        case let .exercise(name):
            exerciseDetail(named: name)
        case .newWorkout:
            ExerciseCreateWorkoutSheet { builder.path = NavigationPath() }
        case .newCardio:
            ExerciseCreateCardioSheet { builder.path = NavigationPath() }
        case let .editWorkout(id):
            editor(forWorkoutID: id)
        }
    }

    @ViewBuilder
    private func exerciseDetail(named name: String) -> some View {
        if let exercise = ExerciseDemoLibrary.exercise(named: name) {
            ExerciseDetailSheet(exercise: exercise)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.defaultSheetBackground.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private func editor(forWorkoutID id: String) -> some View {
        if let workout = builder.saved.first(where: { $0.id == id }) {
            if workout.isCardio {
                ExerciseCreateCardioSheet(editing: workout) { builder.path = NavigationPath() }
            } else {
                ExerciseCreateWorkoutSheet(editing: workout) { builder.path = NavigationPath() }
            }
        }
    }

    private enum Constants {
        static let cardHeight: CGFloat = 97
        static let iconSize: CGFloat = 24
    }
}

#Preview {
    ExerciseSheet()
        .environment(ExerciseBuilder())
}
