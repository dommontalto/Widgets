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
    @State private var shownAd: ExploreSearchClinic?
    @Namespace private var adZoom

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightSearchBarV5("What would you like me to find?", text: $searchText) { isSearchFocused = $0 }
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
        .blur(radius: Constants.comingSoonBlur)
        .allowsHitTesting(false)
        .overlay {
            BrightText("Coming Soon", size: .standout2)
        }
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
            BrightWidgetTitleV5(icon: .symbol("sparkles"), title: "Agents") {
                agents
            }

            BrightWidgetTitleV5(icon: .symbol("globe"), title: "Explore all", onTap: { showsAllClinics = true }) {
                clinics
                    .padding(.horizontal, .spacing3x)
            }

            BrightAdV5(clinic: ExploreSearchClinic.sponsored[0]) { shownAd = ExploreSearchClinic.sponsored[0] }
                .matchedTransitionSource(id: ExploreSearchClinic.sponsored[0].id, in: adZoom) { source in
                    source.clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
                }
                .padding(.horizontal, .spacing3x)
        }
    }

    private var agents: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing1x) {
                ForEach(ExploreAgent.demo) { agent in
                    BrightTagV5(title: agent.title, systemImage: agent.systemImage, isSelected: true) {
                        selectedAgent = agent
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
    }

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
        static let comingSoonBlur: CGFloat = 12
    }
}
