//
//  ExploreClinicsView.swift
//  Widgets
//
//  Created by Dom Montalto on 25/9/2026.
//

import SwiftUI

struct ExploreClinicsView: View {
    @State private var shownClinic: ExploreClinic?

    var body: some View {
        BrightPageView(title: "Explore all") {
            LazyVGrid(columns: Constants.columns, spacing: .spacing3x) {
                ForEach(ExploreClinic.all) { clinic in
                    ExploreClinicTile(clinic: clinic)
                        .onTapGesture { shownClinic = clinic }
                }
            }
            .padding(.bottom, .spacing4x)
        }
        .sheet(item: $shownClinic) { clinic in
            SafariView(url: clinic.website) { shownClinic = nil }
                .ignoresSafeArea()
        }
    }

    private enum Constants {
        static let columns = Array(repeating: GridItem(.flexible(), spacing: .spacing2x), count: 2)
    }
}

struct ExploreClinicTile: View {
    let clinic: ExploreClinic

    var body: some View {
        VStack(spacing: .spacing1x) {
            clinic.background
                .aspectRatio(1, contentMode: .fit)
                .overlay { logo }
                .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))

            BrightText(clinic.name, size: .body1, color: .semiLightTextColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    @ViewBuilder private var logo: some View {
        if clinic.fillsLogo {
            Image(clinic.logo)
                .resizable()
                .scaledToFill()
        } else {
            Image(clinic.logo)
                .resizable()
                .scaledToFit()
                .padding(.spacing3x)
        }
    }
}

#Preview {
    NavigationStack {
        ExploreClinicsView()
    }
}
