//
//  VaultMetricSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 13/7/2026.
//

import SwiftUI

struct MetricSheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct VaultMetricSheet: View {
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
        VStack(alignment: .leading, spacing: .spacing3x) {
            VStack(alignment: .leading, spacing: .spacing1x) {
                BrightText(metric.title, size: .standout3)
                    .padding(.trailing, 52)
                if hasData {
                    BrightText("Latest: \(VaultDemoData.latestRecorded(metric))", size: .body3, color: .lightTextColor, weight: .regular)
                }
            }

            VStack(alignment: .leading, spacing: .spacing105x) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                    BrightText(hasData ? valueNumber : "–", size: .huge)
                        .monospacedDigit()
                    BrightText(valueUnit, size: .subheading2, color: .lightTextColor, weight: .regular)
                }

                if hasData {
                    HStack(spacing: .spacing1x) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.standard(size: .subheading2, weight: .regular))
                            .foregroundStyle(Color.defaultBrightGreen)
                        BrightText("in normal range", size: .body3, color: .semiLightTextColor, weight: .regular)
                    }
                } else {
                    HStack(spacing: .spacing1x) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.standard(size: .subheading2, weight: .regular))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.defaultSkyBlue, Color.defaultLighthouseBlue)
                        BrightText("no data available", size: .body3, color: .semiLightTextColor, weight: .regular)
                    }
                }
            }

            BrightPillButton("Show more", color: .defaultGreen, buttonSize: .large) {
                showDetail = true
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.spacing4x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: MetricSheetHeightKey.self, value: proxy.size.height)
            }
        )
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.textColor)
                    .frame(width: 44, height: 44)
                    .modifier(GlassEffect(shape: .circle, interactive: false))
                    .overlay(Circle().stroke(Color.textColor.opacity(.veryMinimalOpacity), lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, .spacing3x)
            .padding(.trailing, .spacing3x)
        }
        .sheet(isPresented: $showDetail) {
            VaultDatapointDetailSheet(metric: metric)
                .presentationCornerRadius(.modalCornerRadius)
        }
    }
}
