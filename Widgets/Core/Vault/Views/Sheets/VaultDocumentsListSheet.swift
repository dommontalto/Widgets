//
//  VaultDocumentsListSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 4/11/2026.
//

import SwiftUI

// Every document, grouped by category. Tapping one pushes it as the next page
// inside the sheet.
struct VaultDocumentsListSheet<Destination: View>: View {
    let documents: [VaultDocumentSummary]
    @ViewBuilder let destination: (VaultDocumentSummary) -> Destination

    @State private var searchText = ""
    @State private var selectedCategory: VaultDocumentCategory?
    @State private var openedDocument: VaultDocumentSummary?

    private var matching: [VaultDocumentSummary] {
        guard !searchText.isEmpty else { return documents }
        return documents.filter {
            $0.labName.localizedStandardContains(searchText)
                || ($0.sourceFilename?.localizedStandardContains(searchText) ?? false)
        }
    }

    private var shownCategories: [VaultDocumentCategory] {
        if let selectedCategory { return [selectedCategory] }
        guard searchText.isEmpty else {
            return VaultDocumentCategory.allCases.filter { category in matching.contains { $0.category == category } }
        }
        return filterCategories
    }

    private var filterCategories: [VaultDocumentCategory] {
        VaultDocumentCategory.allCases.filter { category in
            category.isAlwaysShown || documents.contains { $0.category == category }
        }
    }

    var body: some View {
        BrightPageSheetViewV5(title: "My Documents") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .spacing5x) {
                    VStack(alignment: .leading, spacing: .spacing2x) {
                        BrightSearchBarV5("Search for documents", text: $searchText)

                        filterTags
                    }

                    if shownCategories.isEmpty {
                        BrightPlaceholderViewV5(
                            systemImage: "magnifyingglass",
                            title: "No matches",
                            subtitle: "Try a different search."
                        )
                    } else {
                        ForEach(shownCategories) { category in
                            section(category)
                        }
                    }
                }
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing4x)
                .animation(.brightEaseInOut, value: selectedCategory)
                .animation(.brightEaseInOut, value: searchText)
            }
            .scrollClipDisabled()
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(item: $openedDocument) { document in
                destination(document)
            }
        }
    }

    private var filterTags: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing1x) {
                ForEach(filterCategories) { category in
                    BrightTagV5(title: category.title, isSelected: selectedCategory == category) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    private func section(_ category: VaultDocumentCategory) -> some View {
        let rows = matching.filter { $0.category == category }

        return BrightWidgetTitleV5(icon: .symbol(category.systemImage, tint: category.tint), title: category.title) {
            if rows.isEmpty {
                BrightText(category.emptyText, size: .body3, color: .lightTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spacing6x)
                    .modifier(BrightCardModifierV5(color: .defaultSheetModalCards))
            } else {
                BrightRowGroupV5(color: .defaultSheetModalCards) {
                    ForEach(rows) { document in
                        BrightRowV5(
                            document.labName,
                            subtitle: document.listSubtitle,
                            trailing: .chevron
                        ) {
                            openedDocument = document
                        }
                    }
                }
            }
        }
    }
}
