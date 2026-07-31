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
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    var body: some View {
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
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.defaultSheetBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.brightEaseInOut, value: filtered.count)
        .animation(.brightSnappy, value: builder.count)
        .toolbar {
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
        }
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
