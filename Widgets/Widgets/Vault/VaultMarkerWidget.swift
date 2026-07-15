//
//  VaultMarkerWidget.swift
//  Bright
//
//  Created by Dom Montalto on 15/5/2026.
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

struct VaultRangeMarkerData: Identifiable, Equatable {
    let id: String
    let title: String
    let lastUpdated: String
    let value: String
    let unit: String
    /// 0 ... 1 — where the marker sits along the bar.
    let markerPosition: Double

    /// The single lit segment (0...4), derived from `markerPosition`.
    /// Half-open bands so a value sitting on a seam lights exactly one segment.
    var litSegmentIndex: Int {
        switch min(1, max(0, markerPosition)) {
        case ..<0.12: 0   // red (low)
        case ..<0.20: 1   // orange (low)
        case ..<0.70: 2   // green (in range)
        case ..<0.78: 3   // orange (high)
        default: 4        // red (high)
        }
    }

    /// Status label matched to the lit colour, rendered by `BrightHealthStatus`.
    var statusLabel: String {
        switch litSegmentIndex {
        case 0, 4: "Out of range"
        case 1, 3: "Borderline"
        default: "In range"
        }
    }
}

struct VaultMarkerWidget: View, Equatable {
    let data: VaultRangeMarkerData
    var cardColor: Color = .cards
    var onTap: (() -> Void)?

    static func == (lhs: VaultMarkerWidget, rhs: VaultMarkerWidget) -> Bool {
        lhs.data == rhs.data
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

                BrightHealthStatus(status: data.statusLabel)
            }

            BrightText(
                "Last Updated: Today",
                size: .body3,
                color: .textColor.opacity(.lowOpacity)
            )

            HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                BrightText(data.value, size: .huge)
                BrightText(data.unit, size: .body1, color: .lightTextColor)
            }
            .padding(.top, .spacing2x)

            rangeBar
                .padding(.top, .spacing1x)
        }
        .padding(.vertical, .spacing2x)
        .padding(.horizontal, .spacing3x)
        .modifier(CardModifier(color: cardColor))
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    private var rangeBar: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let spacing: CGFloat = 2
            let usableWidth = width - 4 * spacing
            let segments: [SegmentSpec] = [
                SegmentSpec(stops: Self.redLow, fractionalRange: 0.00...0.12),
                SegmentSpec(stops: Self.orangeLow, fractionalRange: 0.12...0.20),
                SegmentSpec(stops: Self.middleBlueGreen, fractionalRange: 0.20...0.70),
                SegmentSpec(stops: Self.orangeHigh, fractionalRange: 0.70...0.78),
                SegmentSpec(stops: Self.redHigh, fractionalRange: 0.78...1.00),
            ]

            let clampedPosition = min(1.0, max(0.0, data.markerPosition))
            ZStack(alignment: .leading) {
                HStack(spacing: spacing) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { offset, segment in
                        let selected = offset == data.litSegmentIndex
                        let segmentWidth = usableWidth * CGFloat(segment.fractionalRange.upperBound - segment.fractionalRange.lowerBound)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: segment.stops.map { $0.opacity(selected ? 1 : .veryMinimalOpacity) },
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

    private struct SegmentSpec {
        let stops: [Color]
        let fractionalRange: ClosedRange<Double>
    }

    private static let redLow: [Color] = [Color(hex: "FF3A3A"), Color(hex: "FF7891")]
    private static let redHigh: [Color] = [Color(hex: "FF7891"), Color(hex: "FF3A3A")]
    private static let orangeLow: [Color] = [Color(hex: "FF9378"), Color(hex: "FFC43A")]
    private static let orangeHigh: [Color] = [Color(hex: "FFC43A"), Color(hex: "FF9378")]
    private static let middleBlueGreen: [Color] = [Color(hex: "71C3FF"), Color(hex: "58CB81")]
}
