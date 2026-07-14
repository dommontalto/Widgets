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

    @State private var selectedRange = "W"
    @State private var animatesGraph = false
    @State private var showingTests = false
    @State private var isAllReadingsExpanded = true
    @State private var rangeFrames: [String: CGRect] = [:]
    @Namespace private var rangePill

    private static let ranges = ["W", "M", "3M", "1Y"]

    private var valueNumber: String {
        metric.value.split(separator: " ", maxSplits: 1).first.map(String.init) ?? metric.value
    }

    private var history: VaultMarkerHistoryData {
        VaultDemoData.markerHistory(for: metric)
    }

    private var readings: [VaultMarkerHistoryReading] {
        history.readings ?? []
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

                    graph

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

    // MARK: - Graph

    private var graph: some View {
        let series = VaultDemoData.graphSeries(for: selectedRange)
        return BrightGraph(
            points: hasData ? series.points : [],
            xDomain: series.xDomain,
            xAxisLabels: series.xLabels,
            showsPointMarkers: hasData
        )
        .frame(height: 250)
        .id(selectedRange)
        .transaction { $0.animation = animatesGraph ? .brightEaseInOut : nil }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    guard let index = Self.ranges.firstIndex(of: selectedRange) else { return }
                    let newIndex = min(Self.ranges.count - 1, max(0, index + (value.translation.width < 0 ? 1 : -1)))
                    select(Self.ranges[newIndex])
                }
        )
    }

    private func select(_ range: String) {
        guard range != selectedRange else { return }
        animatesGraph = true
        withAnimation(.brightBouncy) { selectedRange = range }
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

            if let latestDate = VaultDemoData.displayDate(readings.first?.date) {
                BrightText(latestDate, size: .body2, color: .lightTextColor)
            }
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
        readings.map { reading in
            VaultRangeMarkerData(
                id: reading.id,
                title: VaultDemoData.displayDate(reading.date) ?? "Latest",
                lastUpdated: "",
                value: reading.value.map { formatted($0) } ?? "--",
                unit: reading.unit ?? VaultDemoData.valueUnit(metric),
                markerPosition: reading.markerPosition ?? 0.45
            )
        }
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
                        select(range)
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
                    select(nearest)
                }
        )
    }

    // MARK: - Stat pills

    private var statPills: some View {
        HStack(spacing: .spacing2x) {
            statPill("AVG \(hasData ? history.average.map { formatted($0) } ?? "–" : "–")")
            statPill("Range \(hasData ? formattedRange : "–")")
        }
    }

    private var formattedRange: String {
        guard let lower = history.rangeMin, let upper = history.rangeMax else { return "–" }
        return "\(formatted(lower)) - \(formatted(upper))"
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
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
