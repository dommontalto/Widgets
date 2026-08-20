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
    case newSession
    // Carries the saved session's id — the draft itself lives on the builder.
    case editSession(String)
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
                sessions
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

    // MARK: - Saved sessions

    private var sessions: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("My Sessions", size: .subheading)

            if builder.saved.isEmpty {
                placeholder
            } else {
                LazyVGrid(columns: columns, spacing: .spacing2x) {
                    sessionCards
                }
            }
        }
    }

    private var placeholder: some View {
        BrightPlaceholderView(
            systemImage: ExerciseWorkoutCategory.gym.symbol,
            title: "No sessions yet",
            subtitle: "Add exercises, runs or sports and save them as a session.",
            imageColor: ExerciseWorkoutCategory.gym.accentColor,
            buttonTitle: "Create session"
        ) {
            newSession()
        }
    }

    private var sessionCards: some View {
        ForEach(builder.saved) { workout in
            Button {
                workoutStage = workout.isCardio ? .preCardio(workout) : .preWorkout(workout)
            } label: {
                sessionCard(workout)
            }
            .buttonStyle(.plain)
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
            .contextMenu {
                sessionMenu(for: workout)
            }
        }
    }

    private func sessionCard(_ workout: ExerciseQuickWorkout) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                ForEach(workout.glyphs) { glyph in
                    Image(systemName: glyph.symbol)
                        .font(.standard(size: .heading, weight: .light))
                        .foregroundStyle(glyph.color)
                }
            }
            .frame(height: Constants.iconSize, alignment: .leading)
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
    private func sessionMenu(for workout: ExerciseQuickWorkout) -> some View {
        Button("Duplicate", systemImage: "plus.square.on.square") {
            withAnimation(.brightSnappy) { builder.duplicate(workout) }
        }

        Button("Edit", systemImage: "pencil") {
            builder.loadDraft(from: workout)
            builder.path.append(ExerciseWorkoutRoute.editSession(workout.id))
        }

        Button("Delete", systemImage: "trash", role: .destructive) {
            withAnimation(.brightSnappy) { builder.delete(workout) }
        }
        .tint(.defaultRed)
    }

    // MARK: - Creating

    private var addButton: some View {
        BrightRoundButton(systemImage: "plus", size: .finalBossLarge, onTapCallback: newSession)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.spacing3x)
    }

    // A session starts in the library: pick as many exercises, runs or sports as
    // you want, and Add carries them into the create screen.
    private func newSession() {
        builder.reset()
        builder.path.append(ExerciseWorkoutRoute.category(.gym))
    }

    // MARK: - Routing

    @ViewBuilder
    private func destination(for route: ExerciseWorkoutRoute) -> some View {
        switch route {
        case let .category(category):
            ExerciseLibrarySheet(category: category)
        case let .exercise(name):
            exerciseDetail(named: name)
        case .newSession:
            ExerciseCreateSessionSheet { builder.path = NavigationPath() }
        case let .editSession(id):
            editor(forSessionID: id)
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
    private func editor(forSessionID id: String) -> some View {
        if let workout = builder.saved.first(where: { $0.id == id }) {
            ExerciseCreateSessionSheet(editing: workout) { builder.path = NavigationPath() }
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
