//
//  VaultDatapointsListSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 5/11/2026.
//

import SwiftUI

// Every recorded datapoint as a marker card, A to Z, with search and a filter per type.
struct VaultDatapointsListSheet: View {
    let markers: [VaultMarkerData]

    @State private var searchText = ""
    @State private var selectedType: DatapointType?
    @State private var detailData: VaultMarkerDetailData?

    enum DatapointType: String, CaseIterable, Identifiable {
        case clinical
        case lifestyle
        case genetic

        var id: String { rawValue }

        var title: String {
            switch self {
            case .clinical: "Clinical"
            case .lifestyle: "Lifestyle"
            case .genetic: "Genetic"
            }
        }
    }

    private var shown: [VaultMarkerData] {
        markers
            .filter { selectedType == nil || $0.type?.lowercased() == selectedType?.rawValue }
            .filter { searchText.isEmpty || $0.name.localizedStandardContains(searchText) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        BrightPageSheetViewV5(title: "All datapoints") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .spacing4x) {
                    VStack(alignment: .leading, spacing: .spacing2x) {
                        BrightSearchBarV5("Search for datapoints", text: $searchText)

                        typeTags
                    }

                    if shown.isEmpty {
                        BrightPlaceholderViewV5(
                            systemImage: "magnifyingglass",
                            title: "No matches",
                            subtitle: "Try a different search."
                        )
                    } else {
                        LazyVStack(spacing: .spacing3x) {
                            ForEach(shown) { marker in
                                VaultMarkerWidget(
                                    data: VaultViewModel.rangeMarker(from: marker),
                                    cardColor: .defaultSheetModalCards
                                ) {
                                    detailData = VaultViewModel.detail(from: marker)
                                }
                                .equatable()
                            }
                        }
                    }
                }
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing4x)
                .animation(.brightEaseInOut, value: selectedType)
            }
            .scrollClipDisabled()
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(item: $detailData) { data in
            VaultMarkerDetailSheet(data: data)
        }
    }

    private var typeTags: some View {
        HStack(spacing: .spacing1x) {
            ForEach(DatapointType.allCases) { type in
                BrightTagV5(title: type.title, isSelected: selectedType == type) {
                    selectedType = selectedType == type ? nil : type
                }
            }
        }
    }
}
