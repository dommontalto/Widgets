//
//  ExploreView.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""
    @State private var isSearchFocused = false
    @State private var selectedAgent: ExploreAgent?
    @State private var shownClinic: ExploreClinic?
    @State private var showsAllClinics = false
    @State private var selectedClinic: VaultTestingClinic?
    @State private var receipt: VaultTestOrder?
    @State private var shownAd: ExploreSearchClinic?
    @Namespace private var adZoom

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightSearchBar("What would you like me to find?", text: $searchText) { isSearchFocused = $0 }
                .padding(.horizontal, .spacing3x)

            ZStack(alignment: .top) {
                if !isSearching {
                    home
                        .transition(.opacity)
                } else {
                    ExploreSearchView(query: searchText)
                        .transition(.opacity)
                }
            }
            .animation(.brightEaseInOut, value: isSearching)
        }
        .padding(.top, .spacing2x)
        .padding(.bottom, .spacing12x)
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
        .sheet(item: $selectedAgent) { agent in
            ExploreAgentSheet(agent: agent)
        }
        .sheet(item: $selectedClinic) { clinic in
            VaultClinicSheet(clinic: clinic, onOrder: place)
        }
        .sheet(item: $receipt) { order in
            BrightReceiptSheet(order: order)
        }
        .fullScreenCover(item: $shownAd) { clinic in
            ExploreAdDetailView(clinic: clinic)
                .navigationTransition(.zoom(sourceID: clinic.id, in: adZoom))
        }
        .navigationDestination(isPresented: $showsAllClinics) {
            ExploreClinicsView()
        }
    }

    private var isSearching: Bool {
        isSearchFocused || !searchText.isEmpty
    }

    private var home: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightWidgetTitle(icon: .symbol("sparkles"), title: "Agents") {
                agents
            }

            VaultTestBrowse { selectedClinic = $0 }

            BrightWidgetTitle(icon: .symbol("globe"), title: "Explore all", onTap: { showsAllClinics = true }) {
                clinics
                    .padding(.horizontal, .spacing3x)
            }

            BrightAd(clinic: ExploreSearchClinic.sponsored[0]) { shownAd = ExploreSearchClinic.sponsored[0] }
                .matchedTransitionSource(id: ExploreSearchClinic.sponsored[0].id, in: adZoom) { source in
                    source.clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
                }
                .padding(.horizontal, .spacing3x)
        }
    }

    private func place(_ order: VaultTestOrder) {
        selectedClinic = nil
        Task {
            try? await Task.sleep(for: .seconds(Constants.sheetDismissDuration))
            receipt = order
        }
    }

    private var agents: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing1x) {
                ForEach(ExploreAgent.demo) { agent in
                    BrightTag(title: agent.title, systemImage: agent.systemImage, isSelected: true) {
                        selectedAgent = agent
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
    }

    // The clinic sheet has to be down before the receipt comes up over it.
    private var clinics: some View {
        HStack(alignment: .top, spacing: .spacing3x) {
            ForEach(ExploreClinic.demo) { clinic in
                ExploreClinicTile(clinic: clinic)
                    .onTapGesture { shownClinic = clinic }
            }
        }
        .sheet(item: $shownClinic) { clinic in
            SafariView(url: clinic.website) { shownClinic = nil }
                .ignoresSafeArea()
        }
    }

    private enum Constants {
        static let sheetDismissDuration: TimeInterval = 0.35
    }
}
