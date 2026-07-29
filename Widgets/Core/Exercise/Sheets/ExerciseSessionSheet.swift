//
//  ExerciseSessionSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

enum ExerciseSessionRoute: Hashable {
    case category(ExerciseSessionCategory)
    case exercise(String)
    case session(String)
    case newSession
}

struct ExerciseSessionSheet: View {
    @State private var searchText = ""
    @State private var isLoggingCardio = false
    @Environment(ExerciseSessionBuilder.self) private var builder
    @State private var path = NavigationPath()

    private let columns = [
        GridItem(.flexible(), spacing: .spacing2x),
        GridItem(.flexible(), spacing: .spacing2x),
    ]

    var body: some View {
        BrightPageSheetView(title: "Start Session", horizontalPadding: .spacing0x, path: $path) {
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
                        section("My Sessions") { sessionCards }
                    } else {
                        searchResults
                    }
                }
                .padding(.horizontal, .spacing3x)
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing4x)
            }
            .navigationDestination(for: ExerciseSessionRoute.self) { route in
                destination(for: route)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if builder.count > 0 {
                        NavigationLink(value: ExerciseSessionRoute.newSession) {
                            Text("Add")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.defaultSkyBlue)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isLoggingCardio) {
            ExerciseLiveCardioSheet { isLoggingCardio = false }
        }
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
        case let .session(name):
            quickSession(named: name)
        case .newSession:
            ExerciseCustomiseSetsView { path = NavigationPath() }
        }
    }

    @ViewBuilder
    private func exerciseDetail(named name: String) -> some View {
        if let exercise = ExerciseDemoLibrary.exercise(named: name) {
            ExerciseDetailSheet(exercise: exercise)
                .padding(.horizontal, .spacing3x)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.sheetBackground.ignoresSafeArea())
                .navigationTitle(exercise.name)
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func quickSession(named name: String) -> some View {
        if let session = sessions.first(where: { $0.name == name }) {
            ExerciseLiveSessionSheet(sessionName: session.name, templateItems: session.items)
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
            if session.isCardio {
                Button {
                    isLoggingCardio = true
                } label: {
                    sessionCard(session)
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink(value: ExerciseSessionRoute.session(session.name)) {
                    sessionCard(session)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sessions: [ExerciseQuickSession] {
        ExerciseDemoSessions.all + builder.saved
    }

    private func sessionCard(_ session: ExerciseQuickSession) -> some View {
        cardContent(
            symbol: session.symbol,
            color: session.accentColor,
            title: session.name,
            subtitle: session.subtitle
        )
        .contextMenu {
            if builder.canDelete(session) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    builder.delete(session)
                }
            }
        }
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
        .modifier(CardModifier(color: .sheetModalCards))
    }

    private var searchResults: some View {
        VStack(spacing: .spacing2x) {
            ForEach(filtered) { exercise in
                ExerciseLibraryRow(exercise: exercise, isAdded: builder.isAdded(exercise.name)) {
                    builder.toggle(exercise.name)
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
    ExerciseSessionSheet()
        .environment(ExerciseSessionBuilder())
}
