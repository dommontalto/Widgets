//
//  VaultTestCategoryView.swift
//  Widgets
//
//  Created by Dom Montalto on 17/9/2026.
//

import SwiftUI

struct VaultTestCategoryView: View {
    let category: VaultTestCategory
    let onOrder: (VaultTestOrder) -> Void

    @State private var query = ""
    @State private var selectedTest: VaultClinicTest?
    @State private var showingMap = false
    @State private var showingCart = false
    @State private var pull: CGFloat = 0
    @State private var shownAd: ExploreSearchClinic?
    @Namespace private var adZoom

    private let catalog = LabCatalog.shared
    private let cart = LabCart.shared

    private var clinic: VaultTestingClinic? {
        catalog.region.flatMap(catalog.clinic(for:))
    }

    private var sections: (primary: [VaultClinicTest], also: [VaultClinicTest]) {
        guard let clinic else { return ([], []) }
        let sections = clinic.tests(in: category.id)
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return sections }
        let matches: (VaultClinicTest) -> Bool = { $0.name.localizedCaseInsensitiveContains(needle) }
        return (sections.primary.filter(matches), sections.also.filter(matches))
    }

    private var count: Int {
        guard let clinic else { return 0 }
        let sections = clinic.tests(in: category.id)
        return sections.primary.count + sections.also.count
    }

    private var showsCartButton: Bool {
        catalog.region == .au && !cart.items.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacing3x) {
                hero

                VStack(spacing: .spacing3x) {
                    ForEach(ExploreSearchClinic.sponsored) { clinic in
                        BrightAdV5(clinic: clinic, showsBadge: false) { shownAd = clinic }
                            .matchedTransitionSource(id: clinic.id, in: adZoom) { source in
                                source.clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
                            }
                    }
                }
                .padding(.horizontal, .spacing3x)

                tests
            }
            .padding(.bottom, .spacing10x)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            pull = max(0, -offset)
        }
        .brightSoftScrollEdgesV5()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.defaultBackground.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                DebugInlineTitle(file: #file)
            }

            ToolbarItem(placement: .topBarTrailing) {
                LabRegionMenu()
            }
            if catalog.region == .au {
                ToolbarItem(placement: .topBarTrailing) {
                    LabCentresMapButton { showingMap = true }
                }
            }
        }
        .brightBottomButtonV5 {
            if showsCartButton {
                BrightPillButton(
                    "View Cart · \(cart.items.count) \(cart.items.count == 1 ? "test" : "tests")",
                    systemImage: "cart",
                    buttonSize: .large
                ) {
                    showingCart = true
                }
            }
        }
        .fullScreenCover(item: $shownAd) { clinic in
            ExploreAdDetailView(clinic: clinic)
                .navigationTransition(.zoom(sourceID: clinic.id, in: adZoom))
        }
        .navigationDestination(isPresented: $showingMap) {
            LabCollectionCentresMapView()
        }
        .navigationDestination(item: $selectedTest) { test in
            if let clinic {
                VaultTestDetailView(test: test, clinic: clinic, isSheet: false, onOrder: onOrder)
            }
        }
        .navigationDestination(isPresented: $showingCart) {
            if let clinic = catalog.clinic(for: .au) {
                LabCartView(clinic: clinic, isSheet: false) { order in
                    showingCart = false
                    onOrder(order)
                }
            }
        }
        .onChange(of: catalog.region) { query = "" }
        .animation(.brightEaseInOut, value: catalog.region)
        .animation(.brightSnappy, value: query)
        .animation(.brightEaseInOut, value: showsCartButton)
    }

    @ViewBuilder
    private var tests: some View {
        if clinic == nil {
            if catalog.isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .padding(.top, .spacing4x)
            } else {
                emptyText("No \(category.name) tests available in \(catalog.region?.title ?? "your region") yet.")
            }
        } else {
            VStack(alignment: .leading, spacing: .spacing3x) {
                if count > 0 {
                    BrightSearchBarV5("Search \(category.name) tests", text: $query)
                }

                if sections.primary.isEmpty, sections.also.isEmpty {
                    emptyText(query.isEmpty
                        ? "No \(category.name) tests available in \(catalog.region?.title ?? "your region") yet."
                        : "No \(category.name) tests match “\(query)”.")
                }

                testSection("\(category.name) Tests", tests: sections.primary)
                testSection("Also includes", tests: sections.also)
            }
            .padding(.horizontal, .spacing3x)
        }
    }

    @ViewBuilder
    private func testSection(_ title: String, tests: [VaultClinicTest]) -> some View {
        if !tests.isEmpty {
            VStack(alignment: .leading, spacing: .spacing2x) {
                BrightText(title, size: .body1, color: .semiLightTextColor, weight: .regular)
                    .padding(.horizontal, .spacing2x)

                ForEach(tests) { test in
                    VaultClinicTestCard(test: test, color: .defaultCards) { selectedTest = test }
                }
            }
        }
    }

    private func emptyText(_ text: String) -> some View {
        BrightText(text, size: .body1, color: .lightTextColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, .spacing2x)
    }

    private var hero: some View {
        Color.clear
            .frame(height: Constants.heroHeight)
            .background { heroImage }
            .clipped()
            .mask { fade }
            .scaleEffect(1 + pull / Constants.heroHeight, anchor: .bottom)
            .overlay(alignment: .top) {
                VStack(spacing: .spacing2x) {
                    VaultTestCategoryIcon(category: category, symbolSize: .huge)
                        .frame(width: Constants.iconSize, height: Constants.iconSize)

                    BrightText(category.name, size: .standout1, weight: .regular)

                    BrightText("\(count) \(count == 1 ? "test" : "tests")", size: .standout3)
                }
                .blendMode(.overlay)
                .padding(.top, Constants.heroContentTop)
            }
    }

    private var heroImage: some View {
        ZStack {
            background(blur: Constants.backgroundBlur)

            background(blur: Constants.fadeBlur)
                .mask {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                }
        }
    }

    private func background(blur: CGFloat) -> some View {
        Image(category.backgroundName)
            .resizable()
            .scaledToFill()
            .scaleEffect(Constants.backgroundOverscan)
            .blur(radius: blur)
    }

    private var fade: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: Constants.fadeStart),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private enum Constants {
        static let heroHeight: CGFloat = 286
        static let heroContentTop: CGFloat = 98
        static let iconSize: CGFloat = 46
        static let backgroundBlur: CGFloat = 8
        static let fadeBlur: CGFloat = 22
        // Blur feathers the image's edges, so it runs past the clip.
        static let backgroundOverscan: CGFloat = 1.2
        static let fadeStart: CGFloat = 0.25
    }
}

#Preview {
    NavigationStack {
        VaultTestCategoryView(category: VaultTestCategory.demo[2]) { _ in }
    }
}
