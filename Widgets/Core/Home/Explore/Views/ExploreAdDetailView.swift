//
//  ExploreAdDetailView.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI

// What a sponsored card opens into: the clinic in its own colours up top, then
// every service near you, filterable by what this clinic offers.
struct ExploreAdDetailView: View {
    let clinic: ExploreSearchClinic

    @Environment(\.dismiss) private var dismiss
    @State private var filter: String?
    @State private var shownWebsite: ExploreSearchClinic?
    @State private var hasAppeared = false

    private var services: [ExploreSearchClinic] {
        let others = ExploreSearchClinic.results.filter { $0.name != clinic.name }
        guard let filter else { return others }
        return others.filter { $0.services.contains(filter) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacing0x) {
                hero

                VStack(alignment: .leading, spacing: .spacing4x) {
                    BrightText(clinic.blurb, size: .body1, color: .semiLightTextColor)
                        .lineSpacing(.lineSpacingMedium)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, .spacing3x)
                        .modifier(ExploreAdEntrance(isShown: hasAppeared, step: 0))

                    filters
                        .modifier(ExploreAdEntrance(isShown: hasAppeared, step: 1))

                    allServices
                        .modifier(ExploreAdEntrance(isShown: hasAppeared, step: 2))
                }
                .padding(.top, .spacing3x)
                .padding(.bottom, .spacing10x)
            }
        }
        .scrollIndicators(.hidden)
        .modifier(HiddenTopScrollEdge())
        .ignoresSafeArea(edges: .top)
        .background(Color.defaultBackground.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            BrightRoundButton(systemImage: "xmark", size: .large) { dismiss() }
                .padding(.trailing, .spacing3x)
        }
        .animation(.brightEaseInOut, value: filter)
        .onAppear { hasAppeared = true }
        .sheet(item: $shownWebsite) { clinic in
            SafariView(url: clinic.website) { shownWebsite = nil }
                .ignoresSafeArea()
        }
    }

    private var hero: some View {
        VStack(spacing: .spacing2x) {
            clinic.logoBackground
                .frame(width: Constants.logoSize, height: Constants.logoSize)
                .overlay {
                    Image(clinic.logo)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius20, style: .continuous))
                .padding(.bottom, .spacing1x)

            BrightText(clinic.name, size: .standout1, color: .white)
                .multilineTextAlignment(.center)

            BrightText(clinic.address, size: .body1, color: .white.opacity(.mediumOpacity))
                .multilineTextAlignment(.center)

            BrightPillButton("Visit", systemImage: "safari", buttonSize: .small) { shownWebsite = clinic }
                .padding(.top, .spacing1x)
        }
        .padding(.top, Constants.heroTop)
        .padding(.bottom, .spacing5x)
        .padding(.horizontal, .spacing3x)
        .frame(maxWidth: .infinity)
        .background { BrightAdBackdrop(logo: clinic.logo, bleed: Constants.pullBleed) }
        .environment(\.colorScheme, .dark)
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing1x) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.standardSFPro(size: .body1, weight: .regular))
                    .foregroundStyle(Color.textColor)

                BrightText("Filters", size: .body1)
            }
            .padding(.horizontal, .spacing3x)

            ScrollView(.horizontal) {
                HStack(spacing: .spacing105x) {
                    ForEach(clinic.services, id: \.self) { service in
                        Button {
                            filter = filter == service ? nil : service
                        } label: {
                            ExploreServiceChip(title: service, isSelected: filter == service)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
            .brightHaptic(.light, trigger: filter)
        }
    }

    private var allServices: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("All Services", size: .body1)
                .padding(.horizontal, .spacing3x)

            if services.isEmpty, let filter {
                BrightText("No other clinics near you offer \(filter) yet.", size: .body1, color: .lightTextColor)
                    .padding(.horizontal, .spacing3x)
            } else {
                VStack(spacing: .spacing2x) {
                    ForEach(services) { service in
                        serviceCard(service)
                    }
                }
                .padding(.horizontal, .spacing3x)
            }
        }
    }

    private func serviceCard(_ service: ExploreSearchClinic) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing2x) {
                service.logoBackground
                    .frame(width: Constants.cardLogoSize, height: Constants.cardLogoSize)
                    .overlay {
                        Image(service.logo)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius20, style: .continuous))

                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(service.name, size: .subheading)
                        .lineLimit(1)

                    BrightText(service.address, size: .body1, color: .lightTextColor)
                        .lineLimit(1)
                }
            }

            BrightDivider()

            BrightText(service.blurb, size: .body1, color: .semiLightTextColor)
                .lineSpacing(.lineSpacingMedium)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: .spacing05x) {
                Image(systemName: "list.clipboard")
                    .font(.standardSFPro(size: .body1, weight: .regular))
                    .foregroundStyle(Color.textColor)

                BrightText("Services", size: .body1)
            }

            ScrollView(.horizontal) {
                HStack(spacing: .spacing105x) {
                    ForEach(service.services, id: \.self) { name in
                        ExploreServiceChip(title: name, isSelected: name == filter)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(cornerRadius: .cornerRadius24))
        .contentShape(RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous))
        .onTapGesture { shownWebsite = service }
    }

    private enum Constants {
        static let logoSize: CGFloat = 80
        static let cardLogoSize: CGFloat = 60
        // Clears the status bar now that the scroll view runs under it.
        static let heroTop: CGFloat = 84
        static let pullBleed: CGFloat = 1000
    }
}

struct ExploreServiceChip: View {
    let title: String
    var isSelected = false

    var body: some View {
        BrightText(title, size: .body1, color: isSelected ? .defaultBlackWhite : .textColor)
            .padding(.horizontal, .spacing105x)
            .frame(height: .spacing5x)
            .background(isSelected ? Color.textColor : Color.clear, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.textColor.opacity(.minimalOpacity), lineWidth: Constants.stroke))
            .contentShape(Capsule())
    }

    private enum Constants {
        static let stroke: CGFloat = 1
    }
}

private struct HiddenTopScrollEdge: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectHidden(true, for: .top)
        } else {
            content
        }
    }
}

// Each block rises into place a beat after the one above, once the zoom lands.
private struct ExploreAdEntrance: ViewModifier {
    let isShown: Bool
    let step: Int

    func body(content: Content) -> some View {
        content
            .opacity(isShown ? 1 : 0)
            .offset(y: isShown ? 0 : .spacing3x)
            .animation(
                .spring(duration: Constants.duration, bounce: Constants.bounce)
                    .delay(Constants.lead + Double(step) * Constants.stagger),
                value: isShown
            )
    }

    private enum Constants {
        static let duration: Double = 0.55
        static let bounce: Double = 0.2
        static let lead: Double = 0.25
        static let stagger: Double = 0.08
    }
}

#Preview {
    ExploreAdDetailView(clinic: ExploreSearchClinic.sponsored[0])
}
