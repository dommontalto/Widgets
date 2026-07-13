//
//  VaultDatapointDetailSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 13/7/2026.
//

import SwiftUI

struct VaultDatapointDetailSheet: View {
    let metric: VaultDemoData.Metric
    var hasData: Bool = true

    @State private var selectedRange = "D"
    @State private var showingTests = false
    @State private var isAllReadingsExpanded = true
    @State private var rangeFrames: [String: CGRect] = [:]
    @Namespace private var rangePill

    private static let ranges = ["D", "W", "M", "3M", "1Y"]

    private var valueNumber: String {
        metric.value.split(separator: " ", maxSplits: 1).first.map(String.init) ?? metric.value
    }

    var body: some View {
        BrightPageSheetView(title: metric.title, showBackButton: true) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .spacing4x) {
                    if hasData {
                        latest
                    }

                    if !hasData {
                        noDataBanner
                    }

                    rangeSelector

                    BrightGraph()
                        .frame(height: 250)

                    statPills

                    if hasData {
                        allReadings
                    } else {
                        VaultGuidedTestingCard {
                            withAnimation(.brightBouncy) {
                                showingTests = true
                            }
                        }
                    }
                }
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing4x)
            }
            .scrollClipDisabled()
        }
        .sheet(isPresented: $showingTests) {
            VaultTestsSheet(onDismiss: {
                showingTests = false
            })
        }
    }

    // MARK: - Latest value

    private var latest: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText("Latest", size: .body2, color: .lightTextColor)

            HStack(spacing: .spacing2x) {
                BrightText(valueNumber, size: .huge)
                    .monospacedDigit()
                BrightHealthStatus(status: "Optimal")
            }

            BrightText("Today, 21 Jan, 2026", size: .body2, color: .lightTextColor)
        }
    }

    // MARK: - No data

    private var noDataBanner: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 26))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.defaultBlue, Color.defaultBlue.opacity(.minimalOpacity))

            BrightText("No data found for this datapoint.", size: .body2, color: .defaultBlue, weight: .regular)
        }
        .padding(.spacing2x + .spacing05x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous)
                .fill(Color.defaultBlue.opacity(.finalBossLowOpacity))
        )
    }

    // MARK: - All readings

    private var demoReadings: [VaultRangeMarkerData] {
        let unit = metric.value.split(separator: " ", maxSplits: 1).dropFirst().first.map(String.init) ?? ""
        return [
            VaultRangeMarkerData(id: "r1", title: "Today, 21 Jan, 2026", lastUpdated: "", value: valueNumber, unit: unit, markerPosition: 0.45),
            VaultRangeMarkerData(id: "r2", title: "14 Jan, 2026", lastUpdated: "", value: "44", unit: unit, markerPosition: 0.4),
        ]
    }

    private var allReadings: some View {
        VStack(spacing: .spacing0x) {
            HStack {
                BrightText("ALL READINGS", size: .body3, color: .lightTextColor)
                Spacer()
                BrightRoundButton(
                    systemImage: "chevron.right",
                    imageRotation: isAllReadingsExpanded ? .degrees(90) : .zero
                )
            }
            .padding(.horizontal, .spacing2x + .spacing05x)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.brightSnappy) {
                    isAllReadingsExpanded.toggle()
                }
            }

            if isAllReadingsExpanded {
                VStack(spacing: .spacing3x) {
                    ForEach(demoReadings) { reading in
                        VaultMarkerWidget(data: reading)
                    }
                }
                .padding(.top, .spacing2x)
            }
        }
    }

    // MARK: - Range selector

    private var rangeSelector: some View {
        HStack(spacing: .spacing1x) {
            ForEach(Self.ranges, id: \.self) { range in
                BrightText(range, size: .body1)
                    .padding(.horizontal, .spacing3x)
                    .frame(height: 30)
                    .background {
                        if selectedRange == range {
                            Color.clear
                                .modifier(GlassEffect(shape: .capsule))
                                .matchedGeometryEffect(id: "rangePill", in: rangePill)
                        }
                    }
                    .contentShape(Capsule())
                    .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .named("rangeSelector")) }) {
                        rangeFrames[range] = $0
                    }
                    .onTapGesture {
                        withAnimation(.brightBouncy) { selectedRange = range }
                    }
            }
        }
        .coordinateSpace(name: "rangeSelector")
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: selectedRange)
        .gesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .named("rangeSelector"))
                .onChanged { value in
                    guard let nearest = rangeFrames.min(by: {
                        abs($0.value.midX - value.location.x) < abs($1.value.midX - value.location.x)
                    })?.key, nearest != selectedRange else { return }
                    withAnimation(.brightBouncy) { selectedRange = nearest }
                }
        )
    }

    // MARK: - Stat pills

    private var statPills: some View {
        HStack(spacing: .spacing2x) {
            statPill("AVG –")
            statPill("Range –")
        }
    }

    private func statPill(_ text: String) -> some View {
        BrightText(text, size: .body4)
            .padding(.horizontal, .spacing2x)
            .frame(height: 30)
            .modifier(GlassEffect(shape: .capsule, interactive: false))
    }
}

#Preview {
    VaultDatapointDetailSheet(metric: VaultDemoData.metric(forIndex: 0))
}
