//
//  HeartWorkoutOverviewWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import MapKit
import SwiftUI

struct HeartWorkoutOverviewWidget: View {
    let duration: TimeDuration?
    let distanceKm: Double?
    let altitudeGainMetres: Double?
    let avgPaceSecondsPerKm: Int?
    let caloriesBurnt: Amount?
    let hrAvg: Double?
    let routeLatitudes: [Double]?
    let routeLongitudes: [Double]?
    let routeZoneIndexes: [Int]?
    let heartGraph: HeartWorkoutSummaryHeartGraphData?
    let altitudeGraph: HeartWorkoutSummaryAltitudeGraphData?
    let paceGraph: HeartWorkoutSummaryPaceGraphData?

    @State private var showingMapSheet = false

    /// Smoothing the route is expensive enough that it must not re-run on every
    /// body evaluation, so it happens once at init.
    private let precomputedRoutePoints: [RoutePoint]
    private let precomputedRouteSegments: [RouteSegment]
    private let precomputedRegion: MKCoordinateRegion
    private let precomputedStartCoordinate: CLLocationCoordinate2D?
    private let precomputedEndCoordinate: CLLocationCoordinate2D?

    init(
        duration: TimeDuration?,
        distanceKm: Double?,
        altitudeGainMetres: Double?,
        avgPaceSecondsPerKm: Int?,
        caloriesBurnt: Amount?,
        hrAvg: Double?,
        routeLatitudes: [Double]?,
        routeLongitudes: [Double]?,
        routeZoneIndexes: [Int]?,
        heartGraph: HeartWorkoutSummaryHeartGraphData? = nil,
        altitudeGraph: HeartWorkoutSummaryAltitudeGraphData? = nil,
        paceGraph: HeartWorkoutSummaryPaceGraphData? = nil
    ) {
        self.duration = duration
        self.distanceKm = distanceKm
        self.altitudeGainMetres = altitudeGainMetres
        self.avgPaceSecondsPerKm = avgPaceSecondsPerKm
        self.caloriesBurnt = caloriesBurnt
        self.hrAvg = hrAvg
        self.routeLatitudes = routeLatitudes
        self.routeLongitudes = routeLongitudes
        self.routeZoneIndexes = routeZoneIndexes
        self.heartGraph = heartGraph
        self.altitudeGraph = altitudeGraph
        self.paceGraph = paceGraph

        let coordinates = Self.coordinates(latitudes: routeLatitudes, longitudes: routeLongitudes)
        let points = Self.routePoints(coordinates: coordinates, zoneIndexes: routeZoneIndexes)
        let smoothed = Self.smooth(Self.thin(Self.trimmed(points)))

        precomputedRoutePoints = smoothed
        precomputedStartCoordinate = smoothed.first?.coordinate
        precomputedEndCoordinate = smoothed.last?.coordinate
        precomputedRouteSegments = Self.buildRouteSegments(from: smoothed)
        precomputedRegion = Self.regionForCoordinates(coordinates)
    }

    private var distanceMetric: OverviewMetric {
        .init(
            icon: .system("lines.measurement.horizontal.aligned.bottom", tint: .defaultGreen),
            title: "Distance",
            value: distanceKm != nil ? String(format: "%.2f", distanceKm!) : "--",
            unit: "km"
        )
    }

    private var paceMetric: OverviewMetric {
        .init(
            icon: .asset(ImageNames.stopwatchV5),
            title: "Pace",
            value: avgPaceSecondsPerKm != nil
                ? "\(avgPaceSecondsPerKm! / 60)'\(String(format: "%02d", avgPaceSecondsPerKm! % 60))"
                : "--",
            unit: "/ KM"
        )
    }

    private var gridMetrics: [OverviewMetric] {
        [
            .init(
                icon: .asset(ImageNames.durationV5),
                title: "Duration",
                value: duration?.clockString ?? "--",
                unit: ""
            ),
            .init(
                icon: .asset(ImageNames.altitudeGainV5),
                title: "Altitude Gain",
                value: altitudeGainMetres != nil ? "\(Int(altitudeGainMetres!.rounded()))" : "--",
                unit: "M"
            ),
            .init(
                icon: .asset(ImageNames.heartPulseRedV5),
                title: "AVG HR",
                value: hrAvg != nil ? "\(Int(hrAvg!.rounded()))" : "--",
                unit: "BPM"
            ),
            .init(
                icon: .asset(ImageNames.energyBurntV5),
                title: "Energy burnt",
                value: caloriesBurnt?.value != nil ? "\(Int(caloriesBurnt!.value!.rounded()))" : "--",
                unit: "Cal"
            ),
        ]
    }

    var body: some View {
        VStack(spacing: .spacing3x) {
            if routeLatitudes != nil, routeLongitudes != nil {
                map
                    .onTapGesture(perform: expandMap)
            }

            heroCard

            metricGrid
        }
        .sheet(isPresented: $showingMapSheet) {
            NavigationStack {
                HeartWorkoutMapSheetView(
                    routePoints: precomputedRoutePoints,
                    routeSegments: precomputedRouteSegments,
                    region: precomputedRegion,
                    startCoordinate: precomputedStartCoordinate,
                    endCoordinate: precomputedEndCoordinate,
                    duration: duration,
                    heartGraph: heartGraph,
                    altitudeGraph: altitudeGraph,
                    paceGraph: paceGraph
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingMapSheet = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.textColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarBackground(.hidden, for: .automatic)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    var map: some View {
        Map(initialPosition: .region(precomputedRegion)) {
            ForEach(precomputedRouteSegments.indices, id: \.self) { index in
                let segment = precomputedRouteSegments[index]
                MapPolyline(segment.polyline)
                    .stroke(segment.style, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }

            if let end = precomputedEndCoordinate {
                Annotation("", coordinate: end) {
                    routeMarker(color: .defaultWarningRed, size: Constants.markerSize)
                }
            }

            if let start = precomputedStartCoordinate {
                Annotation("", coordinate: start) {
                    routeMarker(color: .defaultGreen, size: Constants.markerSize)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .frame(height: Constants.mapHeight)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous))
        .overlay(alignment: .topTrailing) {
            BrightRoundButton(
                systemImage: "arrow.up.left.and.arrow.down.right",
                onTapCallback: expandMap
            )
            .padding(.spacing2x)
        }
        .environment(\.colorScheme, .dark)
    }

    private func expandMap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        showingMapSheet = true
    }

    private func routeMarker(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }

    private enum Constants {
        static let mapHeight: CGFloat = 145
        static let markerSize: CGFloat = 14
        static let iconSize: CGFloat = 24
        /// SF Symbols sit inside their own padding, so they need a smaller point
        /// size than an asset icon to read at the same visual weight.
        static let systemIconScale: CGFloat = 20.0 / 24.0
        static let heroDividerHeight: CGFloat = 76
        /// Increase to load the map faster at the cost of route fidelity.
        static let minimumDistanceMetres: Double = 25
        static let smoothingIterations = 3
    }
}

// MARK: - Metric cards

extension HeartWorkoutOverviewWidget {
    fileprivate struct OverviewMetric {
        let icon: MetricIcon
        let title: String
        let value: String
        let unit: String
    }

    fileprivate enum MetricIcon {
        case asset(String)
        case system(String, tint: Color)
    }

    private var heroCard: some View {
        // Matches the card's own inset, so Pace sits as far from the divider as
        // Distance sits from the card edge.
        HStack(spacing: .spacing3x) {
            heroMetric(distanceMetric)

            BrightVerticalDivider(height: Constants.heroDividerHeight)

            heroMetric(paceMetric)
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .sheetModalCards, cornerRadius: .cornerRadius24))
    }

    private var metricGrid: some View {
        VStack(spacing: .spacing3x) {
            ForEach(Array(stride(from: 0, to: gridMetrics.count, by: 2)), id: \.self) { index in
                HStack(spacing: .spacing3x) {
                    gridTile(gridMetrics[index])

                    if index + 1 < gridMetrics.count {
                        gridTile(gridMetrics[index + 1])
                    }
                }
            }
        }
    }

    private func heroMetric(_ metric: OverviewMetric) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            metricLabel(metric, color: .textColor)

            HStack(alignment: .lastTextBaseline, spacing: .spacing1x) {
                BrightText(
                    metric.value,
                    size: .huge,
                    color: metric.value == "--" ? .lightTextColor : .textColor
                )

                BrightText(metric.unit, size: .standout2, color: .lightTextColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func gridTile(_ metric: OverviewMetric) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            metricLabel(metric, color: .semiLightTextColor)

            HStack(alignment: .lastTextBaseline, spacing: .spacing1x) {
                BrightText(
                    metric.value,
                    size: .standout2,
                    color: metric.value == "--" ? .lightTextColor : .textColor
                )

                if !metric.unit.isEmpty {
                    BrightText(metric.unit, size: .body1, color: .lightTextColor)
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .sheetModalCards, cornerRadius: .cornerRadius24))
    }

    private func metricLabel(_ metric: OverviewMetric, color: Color) -> some View {
        HStack(spacing: .spacing1x) {
            metricIcon(metric.icon)

            BrightText(metric.title, size: .body2, color: color)
        }
    }

    @ViewBuilder
    private func metricIcon(_ icon: MetricIcon) -> some View {
        switch icon {
        case let .asset(name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.iconSize, height: Constants.iconSize)
        case let .system(name, tint):
            Image(systemName: name)
                .font(.system(size: Constants.iconSize * Constants.systemIconScale))
                .foregroundStyle(tint)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
        }
    }
}

// MARK: - Route geometry

extension HeartWorkoutOverviewWidget {
    struct RoutePoint {
        let coordinate: CLLocationCoordinate2D
        let zoneIndex: Int
    }

    struct RouteSegment {
        let polyline: MKGeodesicPolyline
        let style: AnyShapeStyle
    }

    private static func coordinates(latitudes: [Double]?, longitudes: [Double]?) -> [CLLocationCoordinate2D] {
        let lats = latitudes ?? []
        let lons = longitudes ?? []
        let count = min(lats.count, lons.count)
        guard count > 0 else { return [] }

        return (0 ..< count).map { CLLocationCoordinate2D(latitude: lats[$0], longitude: lons[$0]) }
    }

    private static func routePoints(
        coordinates: [CLLocationCoordinate2D],
        zoneIndexes: [Int]?
    ) -> [RoutePoint] {
        let zones = zoneIndexes ?? []
        let count = min(coordinates.count, zones.count)
        guard count > 0 else { return [] }

        return (0 ..< count).map { RoutePoint(coordinate: coordinates[$0], zoneIndex: zones[$0]) }
    }

    /// Drops the first and last couple of samples — GPS is usually still settling there.
    private static func trimmed(_ points: [RoutePoint]) -> [RoutePoint] {
        guard points.count >= 4 else { return [] }

        let startIndex = 2
        let endIndex = points.count - 2
        guard startIndex <= endIndex else { return [] }

        return Array(points[startIndex ... endIndex])
    }

    private static func thin(_ points: [RoutePoint]) -> [RoutePoint] {
        guard points.count >= 2 else { return [] }

        var filtered: [RoutePoint] = []
        filtered.reserveCapacity(points.count)

        filtered.append(points[0])
        var lastKept = points[0]

        for point in points.dropFirst() {
            let distance = MKMapPoint(lastKept.coordinate).distance(to: MKMapPoint(point.coordinate))
            if distance >= Constants.minimumDistanceMetres {
                filtered.append(point)
                lastKept = point
            }
        }

        if let last = points.last,
           filtered.last?.coordinate.latitude != last.coordinate.latitude
           || filtered.last?.coordinate.longitude != last.coordinate.longitude {
            filtered.append(last)
        }

        return filtered
    }

    /// Chaikin corner cutting — turns the GPS polyline into something that reads as a road.
    private static func smooth(_ points: [RoutePoint]) -> [RoutePoint] {
        guard points.count >= 3 else { return points }

        var working = points

        for _ in 0 ..< Constants.smoothingIterations {
            guard working.count >= 3 else { break }

            var next: [RoutePoint] = []
            next.reserveCapacity((working.count * 2) + 2)
            next.append(working[0])

            for i in 0 ..< (working.count - 1) {
                let p0 = working[i]
                let p1 = working[i + 1]

                let q = CLLocationCoordinate2D(
                    latitude: (0.75 * p0.coordinate.latitude) + (0.25 * p1.coordinate.latitude),
                    longitude: (0.75 * p0.coordinate.longitude) + (0.25 * p1.coordinate.longitude)
                )

                let r = CLLocationCoordinate2D(
                    latitude: (0.25 * p0.coordinate.latitude) + (0.75 * p1.coordinate.latitude),
                    longitude: (0.25 * p0.coordinate.longitude) + (0.75 * p1.coordinate.longitude)
                )

                next.append(RoutePoint(coordinate: q, zoneIndex: p0.zoneIndex))
                next.append(RoutePoint(coordinate: r, zoneIndex: p1.zoneIndex))
            }

            if let last = working.last {
                next.append(last)
            }
            working = next
        }

        return working
    }

    fileprivate static func buildRouteSegments(from points: [RoutePoint]) -> [RouteSegment] {
        guard points.count >= 2 else { return [] }

        var segments: [RouteSegment] = []
        segments.reserveCapacity(24)

        var currentZone = points[0].zoneIndex
        var currentCoords: [CLLocationCoordinate2D] = [points[0].coordinate]

        func appendSolidSegment(coords: [CLLocationCoordinate2D], zone: Int) {
            guard coords.count >= 2 else { return }
            var coordsCopy = coords
            let polyline = MKGeodesicPolyline(coordinates: &coordsCopy, count: coordsCopy.count)
            segments.append(
                RouteSegment(polyline: polyline, style: AnyShapeStyle(colorForZoneIndex(zone)))
            )
        }

        /// A one-hop polyline so the colour change between zones fades rather than jumps.
        func appendGradientSegment(
            from: CLLocationCoordinate2D,
            to: CLLocationCoordinate2D,
            fromZone: Int,
            toZone: Int
        ) {
            var coordsCopy = [from, to]
            let polyline = MKGeodesicPolyline(coordinates: &coordsCopy, count: coordsCopy.count)
            let gradient = LinearGradient(
                colors: [colorForZoneIndex(fromZone), colorForZoneIndex(toZone)],
                startPoint: .leading,
                endPoint: .trailing
            )
            segments.append(RouteSegment(polyline: polyline, style: AnyShapeStyle(gradient)))
        }

        for i in 1 ..< points.count {
            let point = points[i]
            let prevPoint = points[i - 1]

            if point.zoneIndex == currentZone {
                currentCoords.append(point.coordinate)
            } else {
                appendSolidSegment(coords: currentCoords, zone: currentZone)
                appendGradientSegment(
                    from: prevPoint.coordinate,
                    to: point.coordinate,
                    fromZone: currentZone,
                    toZone: point.zoneIndex
                )

                currentZone = point.zoneIndex
                currentCoords = [prevPoint.coordinate, point.coordinate]
            }
        }

        appendSolidSegment(coords: currentCoords, zone: currentZone)

        return segments
    }

    fileprivate static func colorForZoneIndex(_ zoneIndex: Int) -> Color {
        switch zoneIndex {
        case 1: .defaultBlue
        case 2: .defaultBrightGreen
        case 3: .defaultYellow
        case 4: .defaultOrange
        case 5: .defaultWarningRed
        default: .defaultBlue
        }
    }

    fileprivate static func regionForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -33.8769, longitude: 151.2006),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }

        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude

        for c in coordinates {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(0.01, (maxLat - minLat) * 1.6),
                longitudeDelta: max(0.01, (maxLon - minLon) * 1.6)
            )
        )
    }
}

#Preview {
    let workout = HeartDemoData.workout

    return ScrollView {
        HeartWorkoutOverviewWidget(
            duration: workout.duration,
            distanceKm: workout.distance.map { ($0.value ?? 0) / 1000 },
            altitudeGainMetres: workout.altitudeGain?.value,
            avgPaceSecondsPerKm: workout.avgPaceSecondsPerKm,
            caloriesBurnt: workout.energyOut,
            hrAvg: workout.hrAvg,
            routeLatitudes: workout.routeLatitudes,
            routeLongitudes: workout.routeLongitudes,
            routeZoneIndexes: workout.routeZoneIndexes,
            heartGraph: workout.heartGraph,
            altitudeGraph: workout.altitudeGraph,
            paceGraph: workout.paceGraph
        )
        .padding(.spacing3x)
    }
    .background(Color.sheetBackground)
}
