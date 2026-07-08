//
//  VaultTestingServicesView.swift
//  Widgets
//
//  Created by Dom Montalto on 7/7/2026.
//

import SwiftUI

struct VaultTestingClinic: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let distanceKm: Double
    let services: [String]
    let pricing: [(option: String, price: String)]

    var distance: String {
        String(format: "%.1f km away", distanceKm)
    }

    static let demo: [VaultTestingClinic] = [
        VaultTestingClinic(
            name: "Longevity clinic",
            address: "121 Norton St, Leichhardt NSW 2040",
            distanceKm: 5.3,
            services: ["BLOOD / CBC", "ELECTROLYTES", "LIVER", "LIPIDS", "METABOLIC HEALTH", "INFLAMMATION"],
            pricing: [
                (option: "Full panel", price: "$150"),
                (option: "Custom panel", price: "Enquire"),
            ]
        ),
        VaultTestingClinic(
            name: "Meridian Health Labs",
            address: "88 Pirrama Rd, Pyrmont NSW 2009",
            distanceKm: 2.1,
            services: ["HORMONES", "THYROID", "VITAMIN D", "IRON STUDIES", "CORTISOL"],
            pricing: [
                (option: "Hormone panel", price: "$220"),
                (option: "Single marker", price: "$45"),
            ]
        ),
        VaultTestingClinic(
            name: "Harbour Diagnostics",
            address: "45 Miller St, North Sydney NSW 2060",
            distanceKm: 8.7,
            services: ["GENOMICS", "MICROBIOME", "FOOD SENSITIVITY", "HEAVY METALS"],
            pricing: [
                (option: "Genome sequence", price: "$399"),
                (option: "Microbiome kit", price: "$180"),
            ]
        ),
        VaultTestingClinic(
            name: "Apex Wellness Centre",
            address: "312 Crown St, Surry Hills NSW 2010",
            distanceKm: 3.9,
            services: ["CARDIAC", "LIPIDS", "GLUCOSE / HbA1c", "BLOOD PRESSURE", "ECG"],
            pricing: [
                (option: "Heart health", price: "$275"),
                (option: "Metabolic add-on", price: "$60"),
            ]
        ),
        VaultTestingClinic(
            name: "Coastal Pathology",
            address: "17 Bronte Rd, Bondi Junction NSW 2022",
            distanceKm: 11.4,
            services: ["FERTILITY", "HORMONES", "VITAMIN PANEL", "AMH", "SEMEN ANALYSIS"],
            pricing: [
                (option: "Fertility panel", price: "$340"),
                (option: "Follow-up", price: "Enquire"),
            ]
        ),
    ]
}

enum VaultTestingSortOrder: String, CaseIterable, Identifiable {
    case proximity = "Proximity"
    case alphabetical = "Alphabetical"

    var id: String { rawValue }

    func sorted(_ clinics: [VaultTestingClinic]) -> [VaultTestingClinic] {
        switch self {
        case .proximity:
            return clinics.sorted { $0.distanceKm < $1.distanceKm }
        case .alphabetical:
            return clinics.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}

struct VaultTestingServicesView: View {
    @State private var sortOrder: VaultTestingSortOrder = .proximity
    @State private var showingMap = false

    private var clinics: [VaultTestingClinic] {
        sortOrder.sorted(VaultTestingClinic.demo)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacing3x) {
                BrightText(
                    "\(clinics.count) clinics found near your location",
                    size: .body4,
                    color: .lightTextColor
                )

                ForEach(clinics) { clinic in
                    clinicCard(clinic)
                }
            }
            .padding(.horizontal, .spacing3x)
            .padding(.bottom, .spacing10x)
        }
        .scrollIndicators(.hidden)
        .background(Color.sheetBackground.ignoresSafeArea())
        .navigationTitle("Testing services")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(VaultTestingSortOrder.allCases) { order in
                        Button {
                            withAnimation(.brightEaseInOut) { sortOrder = order }
                        } label: {
                            Label {
                                Text(order.rawValue)
                            } icon: {
                                if order == sortOrder {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingMap = true
                } label: {
                    Image(systemName: "map")
                }
            }
        }
        .navigationDestination(isPresented: $showingMap) {
            VaultClinicsMapView()
        }
    }

    // MARK: Clinic card

    private func clinicCard(_ clinic: VaultTestingClinic) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing105x) {
                Circle()
                    .fill(Color.defaultMainBlack)
                    .frame(width: .spacing4x, height: .spacing4x)
                    .overlay {
                        Image(systemName: "circle.hexagongrid")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                    }

                BrightText(clinic.name, size: .subheading1, weight: .regular)

                Spacer()

                BrightText(clinic.distance, size: .body2, color: .lightTextColor)
            }

            BrightText(clinic.address, size: .body2, color: .lightTextColor)

            divider

            BrightText("Services:", size: .body2, color: .lightTextColor)

            serviceTags(clinic.services)

            divider

            BrightText("Pricing:", size: .body2, color: .lightTextColor)

            VStack(spacing: .spacing1x) {
                ForEach(Array(clinic.pricing.enumerated()), id: \.offset) { _, row in
                    HStack {
                        BrightText(row.option, size: .body2, color: .lightTextColor)
                        Spacer()
                        BrightText(row.price, size: .body2, color: .lightTextColor)
                    }
                }
            }

            visitWebsiteButton
                .frame(maxWidth: .infinity)
                .padding(.top, .spacing1x)
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .sheetModalCards))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.lightTextColor.opacity(.ultraLowOpacity))
            .frame(height: 0.5)
    }

    private func serviceTags(_ services: [String]) -> some View {
        FlowLayout(spacing: .spacing1x) {
            ForEach(services, id: \.self) { service in
                BrightChip(
                    title: service,
                    size: .body3,
                    tint: .defaultBlue,
                    fill: .defaultBlue.opacity(.veryMinimalOpacity)
                )
            }
        }
    }

    private var visitWebsiteButton: some View {
        Button {
        } label: {
            BrightText("Visit website", size: .body2, weight: .regular)
                .padding(.horizontal, .spacing2x)
                .padding(.vertical, .spacing105x)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.textColor.opacity(.minimalOpacity), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

/// Simple left-aligned wrapping layout for the service tag capsules.
struct FlowLayout: Layout {
    var spacing: CGFloat = .spacing1x

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.height }.reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in computeRows(proposal: proposal, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var height: CGFloat = 0
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var current = Row()
        var x: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
                x = 0
            }
            current.indices.append(index)
            current.height = max(current.height, size.height)
            x += size.width + spacing
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

#Preview {
    NavigationStack {
        VaultTestingServicesView()
    }
}
