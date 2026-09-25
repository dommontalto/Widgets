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
    @State private var shownClinic: ExploreClinic?
    @State private var testCategory: VaultTestCategory?
    @State private var selectedClinic: VaultTestingClinic?
    @State private var receipt: VaultTestOrder?

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
        .navigationDestination(item: $testCategory) { category in
            VaultTestCategoryView(category: category, sortOrder: .proximity) { selectedClinic = $0 }
        }
        .sheet(item: $selectedClinic) { clinic in
            VaultClinicSheet(clinic: clinic, onOrder: place)
        }
        .sheet(item: $receipt) { order in
            VaultTestReceiptSheet(order: order)
        }
    }

    private var home: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightWidgetTitle(icon: .symbol("sparkles"), title: "Agents") {
                agents
            }

            VaultTestBrowse { testCategory = $0 }

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

    // The clinic sheet has to be down before the receipt comes up over it.
    private func place(_ order: VaultTestOrder) {
        selectedClinic = nil
        Task {
            try? await Task.sleep(for: .seconds(Constants.sheetDismissDuration))
            receipt = order
        }
    }

    private var clinics: some View {
        HStack(alignment: .top, spacing: .spacing2x) {
            ForEach(ExploreClinic.demo) { clinic in
                Button {
                    shownClinic = clinic
                } label: {
                    clinicTile(clinic)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $shownClinic) { clinic in
            SafariView(url: clinic.website) { shownClinic = nil }
                .ignoresSafeArea()
        }
    }

    private func clinicTile(_ clinic: ExploreClinic) -> some View {
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
        .contentShape(Rectangle())
    }

    private enum Constants {
        static let sheetDismissDuration: TimeInterval = 0.35
    }
}

// A sponsored clinic: its artwork, an Ad badge, and a frosted footer to visit it.
private struct ExploreAdCard: View {
    let ad: ExploreAd

    @State private var showsWebsite = false

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

            BrightPillButton("Visit", buttonSize: .small) { showsWebsite = true }
        }
        .padding(.horizontal, .spacing3x)
        .frame(height: Constants.footerHeight)
        .background(.ultraThinMaterial.opacity(.veryHighOpacity))
        .background(Color.black.opacity(.veryLowOpacity))
        .environment(\.colorScheme, .dark)
        .sheet(isPresented: $showsWebsite) {
            SafariView(url: ad.website) { showsWebsite = false }
                .ignoresSafeArea()
        }
    }

    private enum Constants {
        static let height: CGFloat = 197
        static let footerHeight: CGFloat = 68
    }
}
