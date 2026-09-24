//
//  ExploreSearchView.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

// What Explore shows once something is typed: suggested clinics, then full results.
struct ExploreSearchView: View {
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightWidgetTitle(icon: .symbol("sparkle.magnifyingglass"), title: "Suggestions") {
                VStack(spacing: .spacing2x) {
                    ForEach(matching(ExploreSearchClinic.suggestions)) { clinic in
                        ExploreSuggestionRow(clinic: clinic)
                    }
                }
            }

            BrightWidgetTitle(icon: .symbol("list.bullet.rectangle"), title: "Results") {
                VStack(spacing: .spacing2x) {
                    ForEach(matching(ExploreSearchClinic.results)) { clinic in
                        ExploreResultCard(clinic: clinic)
                    }
                }
            }
        }
        .padding(.horizontal, .spacing3x)
    }

    // The demo has only a handful of clinics, so a query that matches none of
    // them still shows the lot.
    private func matching(_ clinics: [ExploreSearchClinic]) -> [ExploreSearchClinic] {
        let hits = clinics.filter { $0.matches(query) }
        return hits.isEmpty ? clinics : hits
    }
}

private struct ExploreSuggestionRow: View {
    let clinic: ExploreSearchClinic

    @State private var showsWebsite = false

    var body: some View {
        HStack(spacing: .spacing105x) {
            ExploreClinicLogo(clinic: clinic)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(clinic.name, size: .body1)
                    .lineLimit(1)

                if clinic.isAd {
                    ExploreAdBadge()
                }
            }

            Spacer(minLength: .spacing0x)

            BrightPillButton("Visit", buttonSize: .small) { showsWebsite = true }
                .sheet(isPresented: $showsWebsite) {
                    SafariView(url: clinic.website) { showsWebsite = false }
                        .ignoresSafeArea()
                }
        }
        .padding(.leading, .spacing1x)
        .padding(.trailing, .spacing2x)
        .padding(.vertical, .spacing1x)
        .background {
            if clinic.isAd {
                LinearGradient(
                    colors: [Color(hex: "#0091FF"), Color(hex: "#47B9AA")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(.veryLowOpacity)
            }
        }
        .modifier(CardModifier(cornerRadius: .cornerRadius24))
    }
}

struct ExploreResultCard: View {
    let clinic: ExploreSearchClinic

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .top, spacing: .spacing2x) {
                ExploreClinicLogo(clinic: clinic)

                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(clinic.name, size: .heading, color: .semiLightTextColor, weight: .regular)

                    BrightText(clinic.address, size: .body1, color: .lightTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: .spacing0x)

                if clinic.isAd {
                    ExploreAdBadge()
                }
            }

            BrightDivider()

            HStack(spacing: .spacing1x) {
                Image(systemName: "pencil.and.list.clipboard")
                    .font(.standard(size: .body1, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)

                BrightText("Services", size: .body1, color: .semiLightTextColor, weight: .regular)
            }

            FlowLayout(spacing: .spacing1x) {
                ForEach(clinic.services, id: \.self) { service in
                    BrightChip(
                        title: service,
                        tint: .defaultCyan,
                        fill: .defaultCyan.opacity(.veryMinimalOpacity)
                    )
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(cornerRadius: .cornerRadius24))
    }
}

private struct ExploreClinicLogo: View {
    let clinic: ExploreSearchClinic

    var body: some View {
        clinic.logoBackground
            .frame(width: Constants.size, height: Constants.size)
            .overlay {
                Image(clinic.logo)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius20, style: .continuous)
                    .strokeBorder(Color.white.opacity(.lowOpacity), lineWidth: Constants.stroke)
            }
    }

    private enum Constants {
        static let size: CGFloat = .spacing9x
        static let stroke: CGFloat = 0.5
    }
}

struct ExploreAdBadge: View {
    var body: some View {
        BrightText("Ad", size: .body1, color: .black)
            .padding(.horizontal, .spacing105x)
            .frame(height: .spacing4x)
            .background(Color.defaultAmber, in: Capsule())
    }
}
