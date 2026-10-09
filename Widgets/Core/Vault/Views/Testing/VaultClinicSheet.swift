//
//  VaultClinicSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import SwiftUI

struct VaultClinicSheet: View {
    let clinic: VaultTestingClinic
    let onOrder: (VaultTestOrder) -> Void

    @State private var selectedCategoryId: String?
    @State private var selectedTest: VaultClinicTest?
    @State private var showsWebsite = false
    @State private var showingCart = false

    private var tests: [VaultClinicTest] {
        guard let selectedCategoryId else { return clinic.tests }
        return clinic.tests.filter { $0.categoryIds.contains(selectedCategoryId) }
    }

    var body: some View {
        BrightPageSheetViewV5(
            horizontalPadding: .spacing0x,
            trailing: {
                if clinic.provider == .eirly {
                    ToolbarItem(placement: .topBarTrailing) {
                        LabCartButton { showingCart = true }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Visit") { showsWebsite = true }
                }
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing3x) {
                        header
                        filters

                        VStack(spacing: .spacing3x) {
                            ForEach(tests) { test in
                                VaultClinicTestCard(test: test) { selectedTest = test }
                            }
                        }
                    }
                    .padding(.horizontal, .spacing3x)
                    .padding(.bottom, .spacing10x)
                }
                .scrollIndicators(.hidden)
                .animation(.brightSnappy, value: selectedCategoryId)
                .navigationDestination(item: $selectedTest) { test in
                    VaultTestDetailView(test: test, clinic: clinic, onOrder: onOrder)
                }
                .navigationDestination(isPresented: $showingCart) {
                    LabCartView(clinic: clinic, onOrder: onOrder)
                }
            }
        )
        .sheet(isPresented: $showsWebsite) {
            SafariView(url: clinic.website) { showsWebsite = false }
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            BrightText(clinic.name, size: .standout1, weight: .regular)

            BrightText(clinic.address, size: .body1, color: .lightTextColor)
        }
        .padding(.top, .spacing2x)
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing2x) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.standard(size: .heading, weight: .light))

                BrightText("Filters", size: .body1, color: .lightTextColor, weight: .regular)
            }

            ScrollView(.horizontal) {
                HStack(spacing: .spacing105x) {
                    filterTag("All", systemImage: "square.grid.2x2", id: nil)

                    ForEach(clinic.categories) { category in
                        filterTag(category.name, systemImage: category.systemImage, id: category.id)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .animation(.brightSnappy, value: selectedCategoryId)
        }
    }

    private func filterTag(_ title: String, systemImage: String, id: String?) -> some View {
        BrightTagV5(title: title, systemImage: systemImage, isSelected: selectedCategoryId == id) {
            withAnimation(.brightSnappy) { selectedCategoryId = id }
        }
    }
}

#Preview {
    VaultClinicSheet(clinic: VaultTestingClinic.demo[0]) { _ in }
}
