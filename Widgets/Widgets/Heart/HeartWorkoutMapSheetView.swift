//
//  HeartWorkoutMapSheetView.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import Charts
import MapKit
import SwiftUI

struct HeartWorkoutMapSheetView: View {
    let routePoints: [HeartWorkoutOverviewWidget.RoutePoint]
    let routeSegments: [HeartWorkoutOverviewWidget.RouteSegment]
    let region: MKCoordinateRegion
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    let duration: TimeDuration?
    let heartGraph: HeartWorkoutSummaryHeartGraphData?
    let altitudeGraph: HeartWorkoutSummaryAltitudeGraphData?
    let paceGraph: HeartWorkoutSummaryPaceGraphData?

    @State private var cameraPosition: MapCameraPosition
    @State private var selectedSecond: Double?
    @State private var selectedMetric: Metric
    @State private var chaseHeading: Double?
    @State private var lastFraction: Double = 0
    @State private var followStart: Date?
    @State private var chartValues: [Double] = []
    @State private var chartDomain: ClosedRange<Double> = 0 ... 1
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    enum Metric: CaseIterable, Identifiable {
        case heartRate
        case altitude
        case pace

        var id: Self { self }

        var title: String {
            switch self {
            case .heartRate: "Heart Rate"
            case .altitude: "Altitude"
            case .pace: "Pace"
            }
        }

        var color: Color {
            switch self {
            case .heartRate: .defaultWarningRed
            case .altitude: .defaultBlue
            case .pace: .defaultBrightGreen
            }
        }
    }

    init(
        routePoints: [HeartWorkoutOverviewWidget.RoutePoint],
        routeSegments: [HeartWorkoutOverviewWidget.RouteSegment],
        region: MKCoordinateRegion,
        startCoordinate: CLLocationCoordinate2D?,
        endCoordinate: CLLocationCoordinate2D?,
        duration: TimeDuration?,
        heartGraph: HeartWorkoutSummaryHeartGraphData?,
        altitudeGraph: HeartWorkoutSummaryAltitudeGraphData?,
        paceGraph: HeartWorkoutSummaryPaceGraphData?
    ) {
        self.routePoints = routePoints
        self.routeSegments = routeSegments
        self.region = region
        self.startCoordinate = startCoordinate
        self.endCoordinate = endCoordinate
        self.duration = duration
        self.heartGraph = heartGraph
        self.altitudeGraph = altitudeGraph
        self.paceGraph = paceGraph

        _cameraPosition = State(initialValue: .region(region))

        let firstAvailable: Metric = if heartGraph?.data?.isEmpty == false {
            .heartRate
        } else if altitudeGraph?.data?.isEmpty == false {
            .altitude
        } else {
            .pace
        }
        _selectedMetric = State(initialValue: firstAvailable)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            map
                .ignoresSafeArea()

            if !availableMetrics.isEmpty {
                panel
                    .padding(.bottom, .spacing105x)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            chartValues = sampledValues(for: selectedMetric)
            chartDomain = yDomain(for: selectedMetric)
        }
        .onChange(of: selectedSecond) { _, _ in
            updateCamera()
        }
    }

    private var map: some View {
        Map(position: $cameraPosition) {
            ForEach(routeSegments.indices, id: \.self) { index in
                let segment = routeSegments[index]
                MapPolyline(segment.polyline)
                    .stroke(segment.style, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }

            if let end = endCoordinate {
                Annotation("", coordinate: end) {
                    routeMarker(color: .defaultWarningRed, size: Constants.markerSize)
                }
            }

            if let start = startCoordinate {
                Annotation("", coordinate: start) {
                    routeMarker(color: .defaultGreen, size: Constants.markerSize)
                }
            }

            if let selected = selectedCoordinate {
                Annotation("", coordinate: selected) {
                    routeMarker(color: selectedMetric.color, size: Constants.selectedMarkerSize)
                        .shadow(color: .black.opacity(.mediumOpacity), radius: 4, y: 2)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {}
        .environment(\.colorScheme, .dark)
    }

    private func routeMarker(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }

    private var panel: some View {
        VStack(spacing: .spacing2x) {
            readout
                .padding(.horizontal, .spacing1x)

            chart
                .frame(height: Constants.graphHeight)

            metricSwitcher
        }
        .padding(.spacing3x)
        .modifier(GlassEffect(shape: .roundedRect, cornerRadius: .cornerRadius50, interactive: false))
        .padding(.horizontal, .spacing2x)
        .environment(\.colorScheme, .dark)
    }

    private var readout: some View {
        HStack {
            BrightText(
                timeString(for: selectedSecond ?? 0),
                size: .body3,
                color: .semiLightTextColor
            )

            Spacer()

            BrightText(
                selectedValueString,
                size: .body2,
                color: selectedMetric.color
            )
        }
    }

    private var chart: some View {
        Chart {
            ForEach(chartValues.indices, id: \.self) { index in
                LineMark(
                    x: .value("Second", xSecond(for: index, count: chartValues.count)),
                    y: .value("Value", chartValues[index])
                )
                .interpolationMethod(.cardinal(tension: 1.1))
                .lineStyle(StrokeStyle(lineWidth: 0.75))
                .foregroundStyle(selectedMetric.color)
            }

            if let selectedSecond, let value = value(at: selectedSecond, in: chartValues) {
                RuleMark(x: .value("Selected", selectedSecond))
                    .foregroundStyle(Color.textColor.opacity(.lowOpacity))
                    .lineStyle(StrokeStyle(lineWidth: 1))

                PointMark(
                    x: .value("Selected", selectedSecond),
                    y: .value("Value", value)
                )
                .symbolSize(20)
                .foregroundStyle(selectedMetric.color)
            }
        }
        .chartXScale(domain: 0 ... max(durationSeconds, 1))
        .chartYScale(domain: chartDomain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXSelection(value: chartSelectionBinding)
    }

    private var metricSwitcher: some View {
        HStack(spacing: .spacing105x) {
            ForEach(availableMetrics) { metric in
                BrightPillButton(
                    metric.title,
                    color: selectedMetric == metric ? metric.color : nil,
                    size: .body3,
                    buttonSize: .small
                ) {
                    selectedMetric = metric
                    withAnimation(.brightSnappy) {
                        chartValues = sampledValues(for: metric)
                        chartDomain = yDomain(for: metric)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var chartSelectionBinding: Binding<Double?> {
        Binding(
            get: { selectedSecond },
            set: { newValue in
                if let newValue, newValue != selectedSecond {
                    haptic.impactOccurred()
                }
                selectedSecond = newValue
            }
        )
    }

    private var availableMetrics: [Metric] {
        Metric.allCases.filter { !values(for: $0).isEmpty }
    }

    private func values(for metric: Metric) -> [Double] {
        switch metric {
        case .heartRate: (heartGraph?.data ?? []).map { Double($0.value ?? 0) }
        case .altitude: (altitudeGraph?.data ?? []).map(Double.init)
        case .pace: (paceGraph?.data ?? []).map(Double.init)
        }
    }

    /// Resamples onto a fixed grid so the line keeps the same visual density
    /// whichever metric is showing.
    private func sampledValues(for metric: Metric) -> [Double] {
        let raw = values(for: metric)
        guard raw.count >= 2 else { return raw }

        return (0 ..< Constants.sampleCount).map { index in
            let second = (Double(index) / Double(Constants.sampleCount - 1)) * durationSeconds
            return value(at: second, in: raw) ?? 0
        }
    }

    private func yDomain(for metric: Metric) -> ClosedRange<Double> {
        let ticks: [Int]? = switch metric {
        case .heartRate: heartGraph?.yTicks
        case .altitude: altitudeGraph?.yTicks
        case .pace: paceGraph?.yTicks
        }

        let values = values(for: metric)
        let lowest = Double(ticks?.first ?? Int(values.min() ?? 0))
        let highest = Double(ticks?.last ?? Int(values.max() ?? 1))

        guard lowest < highest else { return lowest ... lowest + 1 }
        return lowest ... highest
    }

    private var durationSeconds: Double {
        let hours = Double(duration?.hour ?? 0)
        let minutes = Double(duration?.minute ?? 0)
        return (hours * 3600) + (minutes * 60)
    }

    private func xSecond(for index: Int, count: Int) -> Double {
        guard count > 1 else { return 0 }
        return (Double(index) / Double(count - 1)) * durationSeconds
    }

    private func value(at second: Double, in values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }

        let safeDuration = max(durationSeconds, 1)
        let position = (second / safeDuration) * Double(values.count - 1)
        let lowerIndex = max(0, min(values.count - 1, Int(floor(position))))
        let upperIndex = max(0, min(values.count - 1, Int(ceil(position))))
        let fraction = position - Double(lowerIndex)

        return values[lowerIndex] + (values[upperIndex] - values[lowerIndex]) * fraction
    }

    private var selectedFraction: Double? {
        selectedSecond.map { max(0, min(1, $0 / max(durationSeconds, 1))) }
    }

    private var selectedCoordinate: CLLocationCoordinate2D? {
        selectedFraction.flatMap { coordinate(atFraction: $0) }
    }

    private func coordinate(atFraction fraction: Double) -> CLLocationCoordinate2D? {
        guard routePoints.count >= 2 else { return nil }

        let position = fraction * Double(routePoints.count - 1)
        let lowerIndex = max(0, min(routePoints.count - 1, Int(floor(position))))
        let upperIndex = max(0, min(routePoints.count - 1, Int(ceil(position))))
        let t = position - Double(lowerIndex)

        let a = routePoints[lowerIndex].coordinate
        let b = routePoints[upperIndex].coordinate

        return CLLocationCoordinate2D(
            latitude: a.latitude + (b.latitude - a.latitude) * t,
            longitude: a.longitude + (b.longitude - a.longitude) * t
        )
    }

    private func updateCamera() {
        guard let fraction = selectedFraction, let current = coordinate(atFraction: fraction) else {
            chaseHeading = nil
            followStart = nil
            withAnimation(.easeOut(duration: Constants.entranceDuration)) {
                cameraPosition = .region(region)
            }
            return
        }

        let ahead = coordinate(atFraction: min(1, fraction + Constants.lookAheadFraction)) ?? current
        let targetHeading = bearing(from: current, to: ahead)

        let isJump = abs(fraction - lastFraction) > Constants.jumpThreshold
        lastFraction = fraction

        let now = Date()
        if followStart == nil {
            followStart = now
        }
        let isEntering = now.timeIntervalSince(followStart ?? now) < Constants.entranceDuration

        // Ease the heading towards the target so scrubbing doesn't whip the camera.
        let heading: Double
        if let chaseHeading, !isJump {
            heading = chaseHeading
                + shortestAngleDelta(from: chaseHeading, to: targetHeading) * Constants.headingResponsiveness
        } else {
            heading = targetHeading
        }
        chaseHeading = heading

        let camera = MapCamera(
            centerCoordinate: ahead,
            distance: Constants.followDistance,
            heading: heading,
            pitch: Constants.followPitch
        )

        if isEntering || isJump {
            withAnimation(.easeOut(duration: Constants.entranceDuration)) {
                cameraPosition = .camera(camera)
            }
        } else {
            cameraPosition = .camera(camera)
        }
    }

    private func bearing(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }

    private func shortestAngleDelta(from a: Double, to b: Double) -> Double {
        var delta = b - a
        while delta > 180 { delta -= 360 }
        while delta < -180 { delta += 360 }
        return delta
    }

    private var selectedValueString: String {
        let values = values(for: selectedMetric)
        guard let value = value(at: selectedSecond ?? 0, in: values) else { return "--" }

        return switch selectedMetric {
        case .heartRate: "\(Int(value.rounded())) BPM"
        case .altitude: "\(Int(value.rounded())) m"
        case .pace: "\(paceString(from: value)) / km"
        }
    }

    private func paceString(from paceInSeconds: Double) -> String {
        let totalSeconds = Int(paceInSeconds.rounded())
        guard totalSeconds > 0 else { return "0'00\"" }

        return "\(totalSeconds / 60)'\(String(format: "%02d", totalSeconds % 60))\""
    }

    private func timeString(for second: Double) -> String {
        let total = Int(second.rounded())
        return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    private enum Constants {
        static let graphHeight: CGFloat = 120
        static let markerSize: CGFloat = 18
        static let selectedMarkerSize: CGFloat = 22
        static let followDistance: CLLocationDistance = 500
        static let followPitch: CGFloat = 65
        static let lookAheadFraction: Double = 0.02
        static let headingResponsiveness: Double = 0.3
        static let entranceDuration: TimeInterval = 0.5
        static let jumpThreshold: Double = 0.1
        static let sampleCount = 100
    }
}
