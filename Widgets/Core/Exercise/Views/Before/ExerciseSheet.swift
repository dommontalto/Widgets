//
//  ExerciseSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

enum ExerciseSessionRoute: Hashable {
    case category(ExerciseSessionCategory)
    case exercise(String)
    case newSession
    /// Carries the saved workout's id — the draft itself lives on the builder.
    case editSession(String)
}

struct ExerciseSheet: View {
    @State private var searchText = ""
    @Environment(ExerciseSessionBuilder.self) private var builder
    @State private var sessionStage: ExerciseSessionStage?

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
                        section("Saved Workouts") { sessionCards }
                    } else {
                        searchResults
                    }
                }
                .padding(.spacing3x)
                .padding(.top, .spacing1x)
            }
            .navigationDestination(for: ExerciseSessionRoute.self) { route in
                destination(for: route)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: "Start Workout", file: #file)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if builder.count > 0 {
                        Button("Create") {
                            builder.path.append(ExerciseSessionRoute.newSession)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.defaultSkyBlue)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            }
        }
        .exerciseSessionFlow($sessionStage)
        .animation(.brightEaseInOut, value: searchText.isEmpty)
        .animation(.brightSnappy, value: builder.count)
    }

    @ViewBuilder
    private func destination(for route: ExerciseSessionRoute) -> some View {
        switch route {
        case let .category(category):
            ExerciseCategoryView(category: category)
        case let .exercise(name):
            exerciseDetail(named: name)
        case .newSession:
            ExerciseCreateSessionView { builder.path = NavigationPath() }
        case let .editSession(id):
            editor(forSessionID: id)
        }
    }

    @ViewBuilder
    private func editor(forSessionID id: String) -> some View {
        if let session = builder.saved.first(where: { $0.id == id }) {
            ExerciseCreateSessionView(editing: session) { builder.path = NavigationPath() }
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
        ForEach(ExerciseSessionCategory.standard) { category in
            NavigationLink(value: ExerciseSessionRoute.category(category)) {
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

    private var sessionCards: some View {
        ForEach(sessions) { session in
            Group {
                if session.isCardio {
                    Button {
                        sessionStage = .cardio
                    } label: {
                        sessionCard(session)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        sessionStage = .preSession(session)
                    } label: {
                        sessionCard(session)
                    }
                    .buttonStyle(.plain)
                }
            }
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
            .contextMenu {
                sessionMenu(for: session)
            }
        }
    }

    @ViewBuilder
    private func sessionMenu(for session: ExerciseQuickSession) -> some View {
        Button("Duplicate", systemImage: "plus.square.on.square") {
            withAnimation(.brightSnappy) { builder.duplicate(session) }
        }

        Button("Edit", systemImage: "pencil") {
            builder.loadDraft(from: session)
            builder.path.append(ExerciseSessionRoute.editSession(session.id))
        }

        Button("Delete", systemImage: "trash", role: .destructive) {
            withAnimation(.brightSnappy) { builder.delete(session) }
        }
    }

    private var sessions: [ExerciseQuickSession] {
        builder.saved
    }

    private func sessionCard(_ session: ExerciseQuickSession) -> some View {
        cardContent(
            symbol: session.symbol,
            color: session.accentColor,
            title: session.name,
            subtitle: session.subtitle
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
        .environment(ExerciseSessionBuilder())
}
