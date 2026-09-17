//
//  VaultClinicSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 17/9/2026.
//

import SwiftUI

struct VaultClinicSheet: View {
    let clinic: VaultTestingClinic
    let onOrder: (VaultClinicTest) -> Void

    @State private var selectedCategoryId: String?
    @State private var selectedTest: VaultClinicTest?

    private var tests: [VaultClinicTest] {
        guard let selectedCategoryId else { return clinic.tests }
        return clinic.tests.filter { $0.categoryId == selectedCategoryId }
    }

    var body: some View {
        BrightPageSheetView(
            horizontalPadding: .spacing0x,
            trailing: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Visit Website") {}
                }
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing3x) {
                        header
                        filters

                        VStack(spacing: .spacing3x) {
                            ForEach(tests) { test in
                                testCard(test)
                            }
                        }
                    }
                    .padding(.horizontal, .spacing3x)
                    .padding(.bottom, .spacing10x)
                }
                .scrollIndicators(.hidden)
                .animation(.brightSnappy, value: selectedCategoryId)
                .navigationDestination(item: $selectedTest) { test in
                    VaultTestDetailView(test: test, clinic: clinic) { onOrder(test) }
                }
            }
        )
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
        BrightTag(title: title, systemImage: systemImage, isSelected: selectedCategoryId == id) {
            withAnimation(.brightSnappy) { selectedCategoryId = id }
        }
    }

    private func testCard(_ test: VaultClinicTest) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing105x) {
                Image(systemName: test.type.systemImage)
                    .font(.standard(size: .heading, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)

                BrightText(test.name, size: .heading, color: .semiLightTextColor, weight: .regular)

                Spacer(minLength: .spacing0x)

                BrightRoundButton(systemImage: "chevron.right", size: .small) {
                    selectedTest = test
                }
            }

            HStack(spacing: .spacing1x) {
                Image(systemName: "checkmark.rectangle.stack")
                    .font(.standard(size: .body1, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)

                BrightText("Available", size: .body1, color: .semiLightTextColor, weight: .regular)
            }

            HStack(spacing: .spacing1x) {
                ForEach(test.availability) { availability in
                    BrightChip(
                        title: availability.rawValue,
                        tint: .defaultBlue,
                        fill: .defaultBlue.opacity(.veryMinimalOpacity)
                    )
                }
            }

            BrightDivider()

            BrightText(test.detail, size: .body1, color: .lightTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
        .contentShape(Rectangle())
        .onTapGesture { selectedTest = test }
    }
}

#Preview {
    VaultClinicSheet(clinic: VaultTestingClinic.demo[0]) { _ in }
}
