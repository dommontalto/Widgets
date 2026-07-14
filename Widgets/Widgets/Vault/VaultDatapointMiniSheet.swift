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
    var markerPosition: Double?

    @State private var showDetail = false

    private var statusLabel: String {
        guard let markerPosition else { return "In range" }
        let position = min(1, max(0, markerPosition))
        if position < 0.12 || position >= 0.78 {
            return "Out of range"
        }
        if position < 0.20 || position >= 0.70 {
            return "Borderline"
        }
        return "In range"
    }

    var body: some View {
        content
            .sheet(isPresented: $showDetail) {
                VaultDatapointDetailSheet(
                    metric: VaultDemoData.Metric(title: title, value: "\(value ?? "–") \(unit)"),
                    hasData: hasData
                )
                .presentationCornerRadius(.modalCornerRadius)
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            HStack {
                VStack(alignment: .leading, spacing: .spacing1x) {
                    BrightText(title, size: .standout3)
                        .contentTransition(.numericText())
                    BrightText("Latest: \(hasData ? (latestRecorded ?? "–") : "–")", size: .body3, color: .lightTextColor, weight: .regular)
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
                    BrightText(unit, size: .subheading2, color: .lightTextColor, weight: .regular)
                        .contentTransition(.numericText())
                }

                HStack(spacing: .spacing1x) {
                    if hasData {
                        Image(systemName: statusLabel == "In range" ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.standard(size: .subheading2, weight: .regular))
                            .foregroundStyle(BrightHealthStatus(status: statusLabel).color)
                    } else {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.standard(size: .subheading2, weight: .regular))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.defaultSkyBlue, Color.defaultLighthouseBlue)
                    }
                    BrightText(hasData ? statusLabel.lowercased() : "no data available", size: .body3, color: .semiLightTextColor, weight: .regular)
                        .contentTransition(.numericText())
                }
            }

            BrightPillButton("Show more", color: .defaultGreen, buttonSize: .large) {
                showDetail = true
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.brightBouncy, value: title)
        .animation(.brightBouncy, value: hasData)
        .padding([.top, .horizontal], .spacing4x)
        .padding(.bottom, .spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
