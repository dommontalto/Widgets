//
//  VaultMarkerDetailSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 19/5/2026.
//

import SwiftUI

struct VaultMarkerDetailData: Identifiable {
    let id = UUID()
    let markerId: String
    let title: String
    let subtitle: String?
    let value: String
    let unit: String
    let status: String?
    let accentColor: Color
    let normalRange: ClosedRange<Double>?
}

struct VaultMarkerDetailSheet: View {
    let data: VaultMarkerDetailData

    @State private var history: VaultMarkerHistoryData?
    @State private var loadState: LoadState = .loading
    @State private var isAllReadingsExpanded = true
    @State private var selectedRange = "W"
    @State private var animatesGraph = false
    @State private var rangeFrames: [String: CGRect] = [:]
    @Namespace private var rangePill

    enum LoadState: Equatable { case loading, loaded, failed }

    private static let ranges = ["W", "M", "3M", "1Y"]

    var body: some View {
        BrightPageSheetViewV5(title: data.title) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .spacing4x) {
                    latest

                    rangeSelector

                    graph

                    statPills

                    if !allReadingsMarkers.isEmpty {
                        allReadings
                    }
                }
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing4x)
            }
            .scrollClipDisabled()
        }
        .task(id: data.markerId) { load() }
    }

    private func load() {
        history = VaultDemo.history(for: data.markerId)
        loadState = .loaded
    }

    // MARK: - Latest value

    private var latest: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText("Latest", size: .body2, color: .lightTextColor)

            HStack(spacing: .spacing2x) {
                BrightText(data.value, size: .huge)
                    .monospacedDigit()
                if let status = data.status, !status.isEmpty {
                    BrightStatus(status: status)
                }
            }

            if let latestDate = readings.first.map({ Self.displayDate($0.date) }), !latestDate.isEmpty {
                BrightText(latestDate, size: .body2, color: .lightTextColor)
            } else if let subtitle = data.subtitle, !subtitle.isEmpty {
                BrightText(subtitle, size: .body2, color: .lightTextColor)
            }
        }
    }

    // MARK: - Graph

    // Readings inside the selected window, plotted at their date with
    // `markerPosition` as the y-value. One reading renders as a single dot.
    private var graph: some View {
        let days = Self.windowDays(for: selectedRange)
        let end = readings.compactMap { Self.parseDate($0.date) }.max() ?? .now
        let start = end.addingTimeInterval(-days * 86400)
        let points = readings
            .compactMap { reading -> BrightGraphV5Point? in
                let date = Self.parseDate(reading.date) ?? end
                guard date >= start else { return nil }
                return BrightGraphV5Point(
                    x: date.timeIntervalSince(start) / 86400,
                    value: (reading.markerPosition ?? 0.45) * 100
                )
            }
            .sorted { $0.x < $1.x }

        return BrightGraphV5(
            points: points,
            xDomain: 0...days,
            xAxisLabels: Self.axisLabels(days: days, start: start),
            showsPointMarkers: true
        )
        .frame(height: 250)
        .id(selectedRange)
        .transaction { $0.animation = animatesGraph ? .brightEaseInOut : nil }
    }

    private static func windowDays(for range: String) -> Double {
        switch range {
        case "W": 7
        case "M": 30
        case "3M": 90
        default: 365
        }
    }

    private static func axisLabels(days: Double, start: Date) -> [Double: String] {
        let ticks: [Double] = [0, days / 3, days * 2 / 3, days]
        return ticks.reduce(into: [:]) { labels, tick in
            let date = start.addingTimeInterval(tick * 86400)
            labels[tick] = date.formatted(.brightDate)
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
                                .modifier(BrightGlassEffectV5(shape: .capsule))
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
        .brightHapticV5(.light, trigger: selectedRange)
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

    private func select(_ range: String) {
        guard range != selectedRange else { return }
        animatesGraph = true
        withAnimation(.brightBouncy) { selectedRange = range }
    }

    // MARK: - Readings

    private var readings: [VaultMarkerHistoryReading] {
        if let readings = history?.readings, !readings.isEmpty { return readings }
        guard loadState != .loading else { return [] }
        return [latestFallbackReading]
    }

    // Every marker that opens this sheet has a latest value, so history is
    // never empty — markers without readings show that value as one entry.
    private var latestFallbackReading: VaultMarkerHistoryReading {
        VaultMarkerHistoryReading(
            date: nil,
            lastUpdated: nil,
            value: Double(data.value),
            unit: data.unit,
            status: data.status,
            markerPosition: VaultViewModel.markerPosition(value: data.value, range: data.normalRange),
            normalLow: data.normalRange?.lowerBound,
            normalHigh: data.normalRange?.upperBound,
            reportId: "latest"
        )
    }

    private var readingValues: [Double] {
        readings.compactMap(\.value)
    }

    // Cards for the "All readings" list. Real history maps 1:1; markers
    // without history (e.g. genetic rows whose value is non-numeric) show
    // their latest string value as a single entry instead of a blank "-".
    private var allReadingsMarkers: [VaultRangeMarkerData] {
        if let real = history?.readings, !real.isEmpty {
            return real.map { Self.rangeMarker(from: $0, unit: data.unit) }
        }
        guard loadState != .loading, !data.value.isEmpty else { return [] }
        return [
            VaultRangeMarkerData(
                id: "latest",
                title: "Latest",
                lastUpdated: "",
                value: data.value,
                unit: data.unit,
                markerPosition: VaultViewModel.markerPosition(value: data.value, range: data.normalRange)
            )
        ]
    }

    // MARK: - Stat pills

    private var statPills: some View {
        HStack(spacing: .spacing2x) {
            statPill("AVG \(readingValues.isEmpty ? "–" : formatted(averageValue))")
            statPill("Range \(formattedRange)")
        }
    }

    private func statPill(_ text: String) -> some View {
        BrightText(text, size: .body4)
            .padding(.horizontal, .spacing2x)
            .frame(height: 30)
            .modifier(BrightGlassEffectV5(shape: .capsule, interactive: false))
    }

    private var averageValue: Double {
        if let avg = history?.average { return avg }
        guard !readingValues.isEmpty else { return 0 }
        return readingValues.reduce(0, +) / Double(readingValues.count)
    }

    private var formattedRange: String {
        let lower = history?.rangeMin ?? readingValues.min()
        let upper = history?.rangeMax ?? readingValues.max()
        guard let lower, let upper else { return "–" }
        return "\(formatted(lower)) - \(formatted(upper))"
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }

    // MARK: - All readings

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
                    ForEach(allReadingsMarkers) { marker in
                        VaultMarkerWidget(data: marker, cardColor: .defaultSheetModalCards)
                    }
                }
                .padding(.top, .spacing2x)
            }
        }
    }

    // MARK: - Helpers

    private static func rangeMarker(from reading: VaultMarkerHistoryReading, unit: String) -> VaultRangeMarkerData {
        let date = displayDate(reading.date)
        return VaultRangeMarkerData(
            id: reading.id,
            title: date.isEmpty ? "Latest" : date,
            lastUpdated: reading.lastUpdated ?? "",
            value: reading.value.map { formattedValue($0) } ?? "-",
            unit: reading.unit ?? unit,
            markerPosition: reading.markerPosition ?? 0
        )
    }

    private static func formattedValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }

    private static func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        if let date = Date(brightDayKey: string) { return date }
        return Date(brightISOZoned: string)
    }

    private static func displayDate(_ string: String?) -> String {
        guard let string, let date = parseDate(string) else { return string ?? "" }
        return date.formatted(.brightDate)
    }
}
