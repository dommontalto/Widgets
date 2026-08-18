//
//  ExerciseCategorySheet.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

struct ExerciseCategorySheet: View {
    let category: ExerciseWorkoutCategory

    // Presented as a sheet there's no back button, so it needs its own close.
    var showCloseButton = false

    // What the caller is already holding, so picking for a session that's open
    // shows what's in it as ticked rather than offering to add it again.
    var included: Set<String> = []

    // Set to pick one exercise and hand it back — swapping, or adding to a draft
    // that's already open. Left nil, the plus adds straight to the draft.
    var onSelect: ((ExerciseDefinition) -> Void)?

    @Environment(ExerciseBuilder.self) private var builder
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedCategory: ExerciseWorkoutCategory?

    var body: some View {
        BrightPageView(
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultSheetBackground,
            toolbar: {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: title, file: #file)
                }

                if showCloseButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Label("Close", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    // Picking one exercise for a draft that's already open has
                    // nothing to add or count.
                    if onSelect == nil, builder.count > 0 {
                        Button("Add") {
                            builder.path.append(ExerciseWorkoutRoute.newSession)
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
                        BrightSearchBar("Search \(activeCategory.displayName)", text: $searchText)

                        categoryTags

                        VStack(spacing: .spacing2x) {
                            ForEach(filtered) { exercise in
                                row(for: exercise)
                            }
                        }
                    }
                    .padding(.spacing3x)
                }
                .overlay(alignment: .bottomTrailing) {
                    if onSelect == nil, builder.count > 0 {
                        ExerciseAddedPill()
                            .padding(.spacing3x)
                    }
                }
            }
        )
        .animation(.brightEaseInOut, value: filtered.count)
        .animation(.brightSnappy, value: builder.count)
    }

    @ViewBuilder private func row(for exercise: ExerciseDefinition) -> some View {
        if let onSelect {
            ExerciseLibraryRow(exercise: exercise, isAdded: included.contains(exercise.name)) {
                onSelect(exercise)
                dismiss()
            }
        } else {
            ExerciseLibraryRow(exercise: exercise, isAdded: builder.isAdded(exercise.name)) {
                withAnimation(.brightBouncy) { builder.toggle(exercise.name) }
            }
        }
    }

    // The categories the sheet no longer lists, so they're switchable from here.
    private var categoryTags: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacing1x) {
                ForEach(ExerciseWorkoutCategory.standard) { category in
                    BrightTag(
                        title: category.displayName,
                        systemImage: category.symbol,
                        isSelected: category == activeCategory
                    ) {
                        withAnimation(.brightSnappy) { selectedCategory = category }
                    }
                }
            }
        }
        .scrollClipDisabled()
    }

    private var activeCategory: ExerciseWorkoutCategory {
        selectedCategory ?? category
    }

    private var title: String {
        "\(activeCategory.displayName) Exercises"
    }

    private var filtered: [ExerciseDefinition] {
        ExerciseDemoLibrary.exercises(in: activeCategory)
            .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }
}

#Preview {
    NavigationStack {
        ExerciseCategorySheet(category: .gym)
            .environment(ExerciseBuilder())
    }
}
