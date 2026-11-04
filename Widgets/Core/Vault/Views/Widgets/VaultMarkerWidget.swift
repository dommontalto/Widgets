//
//  VaultMarkerWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 15/5/2026.
//

import SwiftUI

// Which way is good for a marker, which sets the range bar's shape. Two-sided
// markers are bad at both ends; one-sided ones have no bad zone on their good side.
enum VaultMarkerDirection: String {
    case optimalBand = "optimal_band"
    case higherBetter = "higher_better"
    case lowerBetter = "lower_better"

    init(_ rawValue: String?) {
        self = rawValue.flatMap(Self.init(rawValue:)) ?? .optimalBand
    }

    // The bar's segments left to right, each over the share of the bar it spans.
    // The seams match the zones the server places `markerPosition` in.
    var segments: [(band: VaultMarkerBand, span: ClosedRange<Double>)] {
        switch self {
        case .optimalBand:
            [(.low, 0.00...0.12), (.lowEdge, 0.12...0.20), (.optimal, 0.20...0.70), (.highEdge, 0.70...0.78), (.high, 0.78...1.00)]
        case .higherBetter:
            [(.low, 0.00...0.12), (.lowEdge, 0.12...0.20), (.optimal, 0.20...1.00)]
        case .lowerBetter:
            [(.optimal, 0.00...0.70), (.highEdge, 0.70...0.78), (.high, 0.78...1.00)]
        }
    }

    // Half-open bands so a value sitting on a seam lights exactly one segment.
    func band(for markerPosition: Double) -> VaultMarkerBand {
        let position = min(1, max(0, markerPosition))
        return segments.first { position < $0.span.upperBound }?.band ?? segments[segments.count - 1].band
    }
}

enum VaultMarkerBand {
    case low
    case lowEdge
    case optimal
    case highEdge
    case high

    // Status label matched to the lit colour, rendered by `BrightStatus`.
    var statusLabel: String {
        switch self {
        case .low: "Low"
        case .high: "High"
        case .lowEdge, .highEdge: "Sub-Optimal"
        case .optimal: "Optimal"
        }
    }

    var stops: [Color] {
        switch self {
        case .low: [Color(hex: "FF3A3A"), Color(hex: "FF7891")]
        case .lowEdge: [Color(hex: "FF9378"), Color(hex: "FFC43A")]
        case .optimal: [.defaultCyan, Color(hex: "58CB81")]
        case .highEdge: [Color(hex: "FFC43A"), Color(hex: "FF9378")]
        case .high: [Color(hex: "FF7891"), Color(hex: "FF3A3A")]
        }
    }
}

struct VaultRangeMarkerData: Identifiable, Equatable {
    let id: String
    let title: String
    let lastUpdated: String
    let value: String
    let unit: String
    // 0 ... 1 — where the marker sits along the bar.
    let markerPosition: Double
    var direction: VaultMarkerDirection = .optimalBand
    // A marker with no reference range has nothing to place it against, so it
    // shows its value without a bar or status.
    var hasRange = true

    var band: VaultMarkerBand {
        direction.band(for: markerPosition)
    }

    var statusLabel: String {
        band.statusLabel
    }
}

struct VaultMarkerWidget: View, Equatable {
    let data: VaultRangeMarkerData
    var cardColor: Color = .defaultCards
    var onTap: (() -> Void)?

    static func == (lhs: VaultMarkerWidget, rhs: VaultMarkerWidget) -> Bool {
        lhs.data == rhs.data
    }

    private var displayValue: String {
        data.value.localizedCaseInsensitiveContains("percentile") ? "" : data.value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            HStack(spacing: .spacing1x) {
                Image(systemName: VaultMarkerIcon.systemImage(for: data.title))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.textColor)
                    .frame(width: .spacing4x, alignment: .center)

                BrightText(data.title, size: .body1, color: .textColor)

                Spacer()

                if data.hasRange {
                    BrightStatus(status: data.statusLabel)
                }
            }

            if !data.lastUpdated.isEmpty {
                BrightText(
                    "Last Updated: \(data.lastUpdated.isoStringToDate().formatted(.brightDate))",
                    size: .body3,
                    color: .textColor.opacity(.lowOpacity)
                )
            }

            if !displayValue.isEmpty {
                HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                    BrightText(displayValue, size: .huge)
                    BrightText(data.unit, size: .body1, color: .lightTextColor)
                }
                .padding(.top, .spacing2x)
            }

            if data.hasRange {
                rangeBar
                    .padding(.top, .spacing1x)
            }
        }
        .padding(.vertical, .spacing2x)
        .padding(.horizontal, .spacing3x)
        .modifier(BrightCardModifierV5(color: cardColor))
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    private var rangeBar: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let spacing: CGFloat = 2
            let segments = data.direction.segments
            let usableWidth = width - CGFloat(segments.count - 1) * spacing
            let clampedPosition = min(1.0, max(0.0, data.markerPosition))
            ZStack(alignment: .leading) {
                HStack(spacing: spacing) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                        let selected = segment.band == data.band
                        let segmentWidth = usableWidth * CGFloat(segment.span.upperBound - segment.span.lowerBound)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: segment.band.stops.map { $0.opacity(selected ? 1 : .veryMinimalOpacity) },
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: segmentWidth, height: 10)
                    }
                }

                // Indicator with a card-coloured halo so the line always sits in
                // a clean gap and never straddles a segment seam (e.g. green/orange).
                ZStack {
                    Capsule()
                        .fill(cardColor)
                        .frame(width: 8, height: 18)
                    Capsule()
                        .fill(Color.textColor)
                        .frame(width: 3, height: 18)
                }
                .offset(x: max(0, min(width - 8, width * clampedPosition - 4)))
            }
            .frame(height: 18)
        }
        .frame(height: 18)
    }

    // The colour of the band a position falls in, the one lit on the range bar.
    static func stops(forMarkerPosition position: Double, direction: VaultMarkerDirection = .optimalBand) -> [Color] {
        direction.band(for: position).stops
    }
}
