//
//  ExploreView.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""
    @State private var selectedAgent: ExploreAgent?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightSearchBar("What would you like me to find?", text: $searchText)
                .padding(.horizontal, .spacing3x)

            ZStack(alignment: .top) {
                if searchText.isEmpty {
                    home
                        .transition(.opacity)
                } else {
                    ExploreSearchView(query: searchText)
                        .transition(.opacity)
                }
            }
            .animation(.brightEaseInOut, value: searchText.isEmpty)
        }
        .padding(.top, .spacing2x)
        .padding(.bottom, .spacing12x)
        .sheet(item: $selectedAgent) { agent in
            ExploreAgentSheet(agent: agent)
        }
    }

    private var home: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightWidgetTitle(icon: .symbol("sparkles"), title: "Agents") {
                agents
            }

            BrightWidgetTitle(icon: .symbol("square.grid.2x2"), title: "Browse") {
                BrightTileRow {
                    ForEach(ExploreBrowseCategory.demo) { category in
                        browseTile(category)
                    }
                }
            }

            BrightWidgetTitle(icon: .symbol("globe"), title: "Explore all") {
                clinics
                    .padding(.horizontal, .spacing3x)
            }

            ExploreAdCard(ad: .demo)
                .padding(.horizontal, .spacing3x)
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

    private func browseTile(_ category: ExploreBrowseCategory) -> some View {
        BrightTile(
            category.name,
            subtitle: "\(category.clinicCount) clinics",
            backgroundImage: category.backgroundImage
        ) {} icon: {
            switch category.mark {
            case let .symbol(name):
                Image(systemName: name)
                    .font(.standardSFPro(size: .standout2, weight: .medium))
            case let .testing(testCategory):
                VaultTestCategoryIcon(category: testCategory, symbolSize: .standout1)
            }
        }
    }

    private var clinics: some View {
        HStack(alignment: .top, spacing: .spacing2x) {
            ForEach(ExploreClinic.demo) { clinic in
                VStack(alignment: .leading, spacing: .spacing1x) {
                    clinic.background
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(clinic.logo)
                                .resizable()
                                .scaledToFit()
                                .padding(.spacing3x)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))

                    BrightText(clinic.name, size: .body1, color: .semiLightTextColor)
                        .lineLimit(1)
                        .padding(.leading, .spacing1x)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// A sponsored clinic: its artwork, an Ad badge, and a frosted footer to visit it.
private struct ExploreAdCard: View {
    let ad: ExploreAd

    var body: some View {
        Color.clear
            .frame(height: Constants.height)
            .background {
                Image(ad.image)
                    .resizable()
                    .scaledToFill()
            }
            .overlay(alignment: .bottom) {
                footer
            }
            .overlay(alignment: .bottomLeading) {
                ExploreAdBadge()
                    .padding(.leading, .spacing2x)
                    .padding(.bottom, Constants.footerHeight + .spacing2x)
            }
            .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
    }

    private var footer: some View {
        HStack(spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(ad.title, size: .body1, color: .white.opacity(.mediumOpacity))
                BrightText(ad.subtitle, size: .body1, color: .white.opacity(.lowOpacity))
            }

            Spacer(minLength: .spacing0x)

            BrightPillButton("Visit", buttonSize: .small) {}
        }
        .padding(.horizontal, .spacing3x)
        .frame(height: Constants.footerHeight)
        .background(.ultraThinMaterial.opacity(.veryHighOpacity))
        .background(Color.black.opacity(.veryLowOpacity))
        .environment(\.colorScheme, .dark)
    }

    private enum Constants {
        static let height: CGFloat = 197
        static let footerHeight: CGFloat = 68
    }
}
