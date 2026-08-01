//
//  ExerciseCategoryView.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

struct ExerciseCategoryView: View {
    let category: ExerciseSessionCategory

    @Environment(ExerciseSessionBuilder.self) private var builder

    @State private var searchText = ""

    var body: some View {
        BrightPageView(
            title: title,
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultSheetBackground,
            toolbar: {
                ToolbarItem(placement: .topBarTrailing) {
                    if builder.count > 0 {
                        Button("Add") {
                            builder.path.append(ExerciseSessionRoute.newSession)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.defaultSkyBlue)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            },
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: .spacing3x) {
                        BrightSearchBar("Search \(category.displayName)", text: $searchText)

                        if builder.count > 0 {
                            ExerciseAddedPill()
                        }

                        VStack(spacing: .spacing2x) {
                            ForEach(filtered) { exercise in
                                ExerciseLibraryRow(exercise: exercise, isAdded: builder.isAdded(exercise.name)) {
                                    withAnimation(.brightBouncy) { builder.toggle(exercise.name) }
                                }
                            }
                        }
                    }
                    .padding(.spacing3x)
                }
            }
        )
        .animation(.brightEaseInOut, value: filtered.count)
        .animation(.brightSnappy, value: builder.count)
    }

    private var title: String {
        "\(category.displayName) Exercises"
    }

    private var filtered: [ExerciseDefinition] {
        ExerciseDemoLibrary.exercises(in: category)
            .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }
}

#Preview {
    NavigationStack {
        ExerciseCategoryView(category: .gym)
            .environment(ExerciseSessionBuilder())
    }
}
