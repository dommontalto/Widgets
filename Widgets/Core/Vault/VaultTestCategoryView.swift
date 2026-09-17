//
//  VaultTestCategoryView.swift
//  Widgets
//
//  Created by Dom Montalto on 17/9/2026.
//

import SwiftUI

struct VaultTestCategoryView: View {
    let category: VaultTestCategory
    let sortOrder: VaultTestingSortOrder
    let onSelectClinic: (VaultTestingClinic) -> Void

    @State private var showingMap = false

    private var clinics: [VaultTestingClinic] {
        sortOrder.sorted(VaultTestingClinic.demo).filter { $0.offers(category.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacing3x) {
                hero

                HStack(spacing: .spacing2x) {
                    Image(systemName: "location")
                        .font(.standard(size: .heading, weight: .light))

                    BrightText("\(category.name) Clinics Near Me", size: .body1, color: .semiLightTextColor, weight: .regular)
                }
                .padding(.horizontal, .spacing5x)

                VStack(spacing: .spacing3x) {
                    ForEach(clinics) { clinic in
                        VaultClinicCard(clinic: clinic) { onSelectClinic(clinic) }
                    }
                }
                .padding(.horizontal, .spacing3x)
            }
            .padding(.bottom, .spacing10x)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.defaultBackground.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingMap = true
                } label: {
                    Label("Map", systemImage: "map")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .navigationDestination(isPresented: $showingMap) {
            VaultClinicsMapView(clinics: clinics, onSelectClinic: onSelectClinic)
        }
    }

    private var hero: some View {
        Color.clear
            .frame(height: Constants.heroHeight)
            .background {
                Image(category.backgroundName)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(Constants.backgroundOverscan)
                    .blur(radius: Constants.backgroundBlur)
            }
            .clipped()
            .overlay(alignment: .top) {
                VStack(spacing: .spacing2x) {
                    VaultTestCategoryIcon(category: category, symbolSize: .huge)
                        .frame(width: Constants.iconSize, height: Constants.iconSize)

                    BrightText(category.name, size: .standout1, weight: .regular)

                    BrightText("\(VaultTestingClinic.count(offering: category.id)) clinics", size: .standout3)
                }
                .blendMode(.overlay)
                .padding(.top, Constants.heroContentTop)
            }
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: Constants.fadeStart),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }

    private enum Constants {
        static let heroHeight: CGFloat = 286
        static let heroContentTop: CGFloat = 98
        static let iconSize: CGFloat = 46
        static let backgroundBlur: CGFloat = 8
        // Blur feathers the image's edges, so it runs past the clip.
        static let backgroundOverscan: CGFloat = 1.2
        static let fadeStart: CGFloat = 0.75
    }
}

#Preview {
    NavigationStack {
        VaultTestCategoryView(category: VaultTestCategory.demo[2], sortOrder: .proximity) { _ in }
    }
}
