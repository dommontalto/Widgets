//
//  ExploreAdDetailView.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI

// What a sponsored card opens into: the clinic in its own colours up top, then
// every test it runs, filterable by category.
struct ExploreAdDetailView: View {
    let clinic: ExploreSearchClinic

    @Environment(\.dismiss) private var dismiss
    @State private var filter: VaultTestCategory?
    @State private var shownWebsite: ExploreSearchClinic?
    @State private var hasAppeared = false
    @State private var selectedTest: VaultClinicTest?
    @State private var receipt: VaultTestOrder?

    private var categories: [VaultTestCategory] {
        VaultTestCategory.demo.filter { category in clinic.tests.contains { $0.categoryId == category.id } }
    }

    private var tests: [VaultClinicTest] {
        guard let filter else { return clinic.tests }
        return clinic.tests.filter { $0.categoryId == filter.id }
    }

    var body: some View {
        NavigationStack {
            content
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item: $selectedTest) { test in
                    VaultTestDetailView(test: test, clinic: clinic.testingClinic, isSheet: false, onOrder: place)
                }
        }
        .sheet(item: $receipt) { order in
            VaultTestReceiptSheet(order: order)
        }
    }

    private var content: some View {
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

    private func place(_ order: VaultTestOrder) {
        selectedTest = nil
        receipt = order
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
                    ForEach(categories) { category in
                        Button {
                            filter = filter == category ? nil : category
                        } label: {
                            ExploreServiceChip(title: category.name, isSelected: filter == category)
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

            VStack(spacing: .spacing2x) {
                ForEach(tests) { test in
                    Button {
                        selectedTest = test
                    } label: {
                        testCard(test)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, .spacing3x)
        }
    }

    private func testCard(_ test: VaultClinicTest) -> some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            HStack(spacing: .spacing2x) {
                if let category = VaultTestCategory.named(test.categoryId) {
                    categoryBadge(category)
                }

                BrightText(test.name, size: .subheading)
                    .lineLimit(1)
            }
            .padding(.bottom, .spacing2x)

            BrightDivider()

            BrightText(test.detail, size: .body1, color: .semiLightTextColor)
                .lineSpacing(.lineSpacingMedium)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, .spacing2x)

            BrightDivider()

            VStack(alignment: .leading, spacing: .spacing105x) {
                BrightText("Available:", size: .body1)

                ForEach(test.availability) { availability in
                    HStack(spacing: .spacing1x) {
                        Image(systemName: availability.systemImage)
                            .font(.standardSFPro(size: .body1, weight: .regular))
                            .foregroundStyle(Color.textColor)
                            .frame(width: Constants.availabilitySize, height: Constants.availabilitySize)
                            .background(Color.defaultBackground, in: Circle())

                        BrightText(availability.rawValue, size: .body1)
                    }
                }
            }
            .padding(.top, .spacing2x)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(cornerRadius: .cornerRadius24))
        .contentShape(Rectangle())
    }

    private func categoryBadge(_ category: VaultTestCategory) -> some View {
        Image(category.tileName)
            .resizable()
            .scaledToFill()
            .frame(width: Constants.badgeSize, height: Constants.badgeSize)
            .overlay {
                VaultTestCategoryIcon(category: category, symbolSize: .body1)
                    .foregroundStyle(.white)
                    .frame(width: Constants.badgeIconSize, height: Constants.badgeIconSize)
            }
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))
    }

    private enum Constants {
        static let logoSize: CGFloat = 80
        static let badgeSize: CGFloat = 46
        static let badgeIconSize: CGFloat = .spacing3x
        static let availabilitySize: CGFloat = 32
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
