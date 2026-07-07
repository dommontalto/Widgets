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
    let distance: String
    let services: [String]
    let pricing: [(option: String, price: String)]

    static let demo: [VaultTestingClinic] = (0 ..< 3).map { _ in
        VaultTestingClinic(
            name: "Longevity clinic",
            address: "121 Norton St, Leichhardt NSW 2040",
            distance: "5.3 km away",
            services: ["BLOOD / CBC", "ELECTROLYTES", "LIVER", "LIPIDS", "METABOLIC HEALTH", "INFLAMMATION"],
            pricing: [
                (option: "Option 1", price: "$150"),
                (option: "Option 1", price: "Enquire"),
            ]
        )
    }
}

enum VaultTestingSortOrder: String, CaseIterable, Identifiable {
    case proximity = "Proximity"
    case alphabetical = "Alphabetical"

    var id: String { rawValue }
}

struct VaultTestingServicesView: View {
    private let clinics = VaultTestingClinic.demo
    @State private var sortOrder: VaultTestingSortOrder = .proximity
    @State private var showingMap = false

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
                            sortOrder = order
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
