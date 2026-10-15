//
//  VaultClinicTestList.swift
//  Widgets
//
//  Created by Dom Montalto on 12/10/2026.
//

import SwiftUI

// A lab's tests under its category filters, shown a page at a time since a lab can
// offer hundreds.
struct VaultClinicTestList: View {
    let clinic: VaultTestingClinic
    let tests: [VaultClinicTest]
    var color: Color = .defaultCards
    let onSelect: (VaultClinicTest) -> Void

    @State private var selectedCategoryId: String?
    @State private var shownCount = Constants.pageSize

    private var categories: [VaultTestCategory] {
        clinic.categories.filter { category in
            tests.contains { $0.categoryIds.contains(category.id) }
        }
    }

    private var filtered: [VaultClinicTest] {
        guard let selectedCategoryId else { return tests }
        return tests.filter { $0.categoryIds.contains(selectedCategoryId) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            filters

            VStack(spacing: .spacing3x) {
                ForEach(filtered.prefix(shownCount)) { test in
                    VaultClinicTestCard(test: test, color: color) { onSelect(test) }
                }

                // Reaching the end of what's shown brings in the next page.
                if filtered.count > shownCount {
                    BrightProgressViewV5()
                        .onAppear { shownCount += Constants.pageSize }
                }
            }
        }
        .animation(.brightSnappy, value: selectedCategoryId)
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing105x) {
                filterTag("All", systemImage: "square.grid.2x2", id: nil)

                ForEach(categories) { category in
                    filterTag(category.name, systemImage: category.systemImage, id: category.id)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    private func filterTag(_ title: String, systemImage: String, id: String?) -> some View {
        BrightTagV5(title: title, systemImage: systemImage, isSelected: selectedCategoryId == id) {
            withAnimation(.brightSnappy) { selectedCategoryId = id }
            shownCount = Constants.pageSize
        }
    }

    private enum Constants {
        static let pageSize = 20
    }
}
