//
//  VaultDatapointMiniSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 13/7/2026.
//

import SwiftUI

struct VaultDatapointMiniSheet: View {
    let title: String
    let unit: String
    let hasData: Bool
    let latestRecorded: String?
    let onClose: () -> Void
    var value: String?
    var markerId: String?
    var markerPosition: Double?

    @State private var showDetail = false

    private var statusLabel: String {
        guard let markerPosition else { return "Optimal" }
        let position = min(1, max(0, markerPosition))
        if position < 0.12 { return "Low" }
        if position >= 0.78 { return "High" }
        if position < 0.20 || position >= 0.70 {
            return "Sub-Optimal"
        }
        return "Optimal"
    }

    var body: some View {
        content
            .sheet(isPresented: $showDetail) {
                if hasData, let markerId {
                    VaultMarkerDetailSheet(
                        data: VaultMarkerDetailData(
                            markerId: markerId,
                            title: title,
                            subtitle: nil,
                            value: value ?? "–",
                            unit: unit,
                            status: statusLabel,
                            accentColor: BrightStatus(status: statusLabel).color,
                            normalRange: nil
                        )
                    )
                    .presentationCornerRadius(.cardCornerRadius)
                } else {
                    VaultDatapointDetailSheet(title: title)
                        .presentationCornerRadius(.cardCornerRadius)
                }
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            HStack {
                VStack(alignment: .leading, spacing: .spacing1x) {
                    BrightText(title, size: .standout3)
                        .contentTransition(.numericText())
                    BrightText(
                        "Latest: \(hasData ? (latestRecorded?.formattedRecordedDate() ?? "–") : "–")",
                        size: .body3,
                        color: .lightTextColor
                    )
                        .contentTransition(.numericText())
                }
                Spacer()
                BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)
            }

            VStack(alignment: .leading, spacing: .spacing105x) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                    BrightText(hasData ? (value ?? "–") : "–", size: .huge)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    BrightText(unit, size: .subheading2, color: .lightTextColor)
                        .contentTransition(.numericText())
                }

                HStack(spacing: .spacing1x) {
                    if hasData {
                        Image(systemName: statusLabel == "Optimal" ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.standard(size: .subheading2, weight: .regular))
                            .foregroundStyle(BrightStatus(status: statusLabel).color)
                    } else {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.standard(size: .subheading2, weight: .regular))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.defaultSkyBlue, Color.defaultLighthouseBlue)
                    }
                    BrightText(hasData ? statusLabel.lowercased() : "no data available", size: .body3, color: .semiLightTextColor)
                        .contentTransition(.numericText())
                }
            }

            BrightPillButton("See More", buttonSize: .large) {
                showDetail = true
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.brightBouncy, value: title)
        .animation(.brightBouncy, value: hasData)
        .padding([.top, .horizontal], .spacing4x)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
