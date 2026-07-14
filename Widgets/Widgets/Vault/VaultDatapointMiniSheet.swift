//
//  VaultDatapointMiniSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 13/7/2026.
//

import SwiftUI

struct VaultDatapointMiniSheet: View {
    let metric: VaultDemoData.Metric
    let hasData: Bool
    let onClose: () -> Void

    @State private var showDetail = false

    private var valueNumber: String {
        metric.value.split(separator: " ", maxSplits: 1).first.map(String.init) ?? metric.value
    }

    private var valueUnit: String {
        metric.value.split(separator: " ", maxSplits: 1).dropFirst().first.map(String.init) ?? ""
    }

    var body: some View {
        GeometryReader { _ in
            content
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showDetail) {
            VaultDatapointDetailSheet(metric: metric, hasData: hasData)
                .presentationCornerRadius(.modalCornerRadius)
                .presentationBackgroundInteraction(.enabled)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            HStack {
                VStack(alignment: .leading, spacing: .spacing1x) {
                    BrightText(metric.title, size: .standout3)
                        .contentTransition(.numericText())
                    BrightText("Latest: \(hasData ? VaultDemoData.latestRecorded(metric) : "–")", size: .body3, color: .lightTextColor, weight: .regular)
                        .contentTransition(.numericText())
                }
                Spacer()
                BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)
            }

            VStack(alignment: .leading, spacing: .spacing105x) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                    BrightText(hasData ? valueNumber : "–", size: .huge)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    BrightText(valueUnit, size: .subheading2, color: .lightTextColor, weight: .regular)
                        .contentTransition(.numericText())
                }

                HStack(spacing: .spacing1x) {
                    if hasData {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.standard(size: .subheading2, weight: .regular))
                            .foregroundStyle(Color.defaultBrightGreen)
                    } else {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.standard(size: .subheading2, weight: .regular))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.defaultSkyBlue, Color.defaultLighthouseBlue)
                    }
                    BrightText(hasData ? "in normal range" : "no data available", size: .body3, color: .semiLightTextColor, weight: .regular)
                        .contentTransition(.numericText())
                }
            }

            BrightPillButton("Show more", color: .defaultGreen, buttonSize: .large) {
                showDetail = true
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.brightBouncy, value: metric.title)
        .animation(.brightBouncy, value: hasData)
        .padding([.top, .horizontal], .spacing4x)
        .padding(.bottom, .spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
