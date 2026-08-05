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
    /// Carries the saved workout's id — the draft itself lives on the builder.
    case editWorkout(String)
}

struct ExerciseSheet: View {
    @State private var searchText = ""
    @Environment(ExerciseWorkoutBuilder.self) private var builder
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
                    VStack(alignment: .leading, spacing: .spacing2x) {
                        BrightSearchBar("Search for exercise", text: $searchText)

                        if builder.count > 0 {
                            ExerciseAddedPill()
                        }
                    }

                    if searchText.isEmpty {
                        section("Categories") { categoryCards }
                        section("Saved Workouts") { workoutCards }
                    } else {
                        searchResults
                    }
                }
                .padding(.spacing3x)
                .padding(.top, .spacing1x)
            }
            .navigationDestination(for: ExerciseWorkoutRoute.self) { route in
                destination(for: route)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: "Start Workout", file: #file)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if builder.count > 0 {
                        Button("Create") {
                            builder.path.append(ExerciseWorkoutRoute.newWorkout)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.defaultSkyBlue)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            }
        }
        .exerciseWorkoutFlow($workoutStage)
        .animation(.brightEaseInOut, value: searchText.isEmpty)
        .animation(.brightSnappy, value: builder.count)
    }

    @ViewBuilder
    private func destination(for route: ExerciseWorkoutRoute) -> some View {
        switch route {
        case let .category(category):
            ExerciseCategoryView(category: category)
        case let .exercise(name):
            exerciseDetail(named: name)
        case .newWorkout:
            ExerciseCreateWorkoutView { builder.path = NavigationPath() }
        case let .editWorkout(id):
            editor(forWorkoutID: id)
        }
    }

    @ViewBuilder
    private func editor(forWorkoutID id: String) -> some View {
        if let workout = builder.saved.first(where: { $0.id == id }) {
            ExerciseCreateWorkoutView(editing: workout) { builder.path = NavigationPath() }
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

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(title, size: .subheading)

            LazyVGrid(columns: columns, spacing: .spacing2x) {
                content()
            }
        }
    }

    private var categoryCards: some View {
        ForEach(ExerciseWorkoutCategory.standard) { category in
            NavigationLink(value: ExerciseWorkoutRoute.category(category)) {
                cardContent(
                    symbol: category.symbol,
                    color: category.accentColor,
                    title: category.displayName,
                    subtitle: "\(ExerciseDemoLibrary.exercises(in: category).count) \(category.countUnit)"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var workoutCards: some View {
        ForEach(workouts) { workout in
            Group {
                if workout.isCardio {
                    Button {
                        workoutStage = .cardio
                    } label: {
                        workoutCard(workout)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        workoutStage = .preWorkout(workout)
                    } label: {
                        workoutCard(workout)
                    }
                    .buttonStyle(.plain)
                }
            }
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
            .contextMenu {
                workoutMenu(for: workout)
            }
        }
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
    }

    private var workouts: [ExerciseQuickWorkout] {
        builder.saved
    }

    private func workoutCard(_ workout: ExerciseQuickWorkout) -> some View {
        cardContent(
            symbol: workout.symbol,
            color: workout.accentColor,
            title: workout.name,
            subtitle: workout.subtitle
        )
    }

    private func cardContent(
        symbol: String,
        color: Color,
        title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            Image(systemName: symbol)
                .font(.standardSFPro(size: .heading, weight: .light))
                .foregroundStyle(color)
                .frame(width: Constants.iconSize, height: Constants.iconSize, alignment: .leading)
                .padding(.bottom, .spacing105x)

            BrightText(title, size: .body2, color: .semiLightTextColor, weight: .regular)
                .lineLimit(1)

            BrightText(subtitle, size: .body2, color: .lightTextColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing2x)
        .frame(height: Constants.cardHeight, alignment: .topLeading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private var searchResults: some View {
        VStack(spacing: .spacing2x) {
            ForEach(filtered) { exercise in
                ExerciseLibraryRow(exercise: exercise, isAdded: builder.isAdded(exercise.name)) {
                    withAnimation(.brightBouncy) { builder.toggle(exercise.name) }
                }
            }
        }
    }

    private var filtered: [ExerciseDefinition] {
        ExerciseDemoLibrary.all
            .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }

    private enum Constants {
        static let cardHeight: CGFloat = 97
        static let iconSize: CGFloat = 24
    }
}

#Preview {
    ExerciseSheet()
        .environment(ExerciseWorkoutBuilder())
}
