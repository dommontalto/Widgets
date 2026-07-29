//
//  ExerciseSwapSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

struct ExerciseSwapSheet: View {
    var replacing: String?
    var adding = false
    var onSelect: (ExerciseDefinition) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    var body: some View {
        BrightPageSheetView(title: title, horizontalPadding: .spacing0x) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: .spacing3x) {
                    BrightSearchBar("Search exercises", text: $searchText)

                    VStack(spacing: .spacing2x) {
                        ForEach(filtered) { exercise in
                            Button {
                                onSelect(exercise)
                                dismiss()
                            } label: {
                                ExerciseLibraryRow(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, .spacing3x)
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing4x)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var title: String {
        adding ? "Add exercise" : "Swap out \(replacing ?? "")"
    }

    private var filtered: [ExerciseDefinition] {
        ExerciseDemoLibrary.all
            .filter { $0.name != replacing }
            .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }
}

#Preview {
    ExerciseSwapSheet(replacing: "Bench Press") { _ in }
}

#Preview("Adding") {
    ExerciseSwapSheet(adding: true) { _ in }
}
