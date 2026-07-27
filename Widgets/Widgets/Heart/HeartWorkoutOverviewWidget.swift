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
    let cadenceGraph: HeartWorkoutSummaryCadenceGraphData?

    /// Owned by the sheet so it can hide the tab pills while the map is open.
    @Binding var isMapExpanded: Bool
    /// Measured by the sheet outside the scroll view. Deriving it in here with
    /// containerRelativeFrame resolves as unbounded along the scroll axis, which
    /// reaches CoreAnimation as a NaN height and aborts.
    let expandedMapHeight: CGFloat

    @State private var cameraPosition: MapCameraPosition
    /// Starts at the beginning of the workout so the camera has somewhere to fly.
    @State private var selectedSecond: Double? = 0
    @State private var selectedMetric: HeartWorkoutGraphMetric = .heartRate
    @State private var chaseHeading: Double?
    @State private var lastFraction: Double = 0
    @State private var isFollowing = false

    /// Smoothing the route is expensive enough that it must not re-run on every
    /// body evaluation, so it happens once at init.
    private let precomputedRoutePoints: [RoutePoint]
    private let precomputedRouteSegments: [RouteSegment]
    /// A fixed altitude rather than a region: a region is fitted to whatever frame
    /// the map currently has, so the card and the full screen would show the route
    /// at different distances. One camera means one zoomed-out state.
    private let precomputedOverviewCamera: MapCamera
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
        paceGraph: HeartWorkoutSummaryPaceGraphData? = nil,
        cadenceGraph: HeartWorkoutSummaryCadenceGraphData? = nil,
        isMapExpanded: Binding<Bool>,
        expandedMapHeight: CGFloat
    ) {
        _isMapExpanded = isMapExpanded
        self.expandedMapHeight = expandedMapHeight
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
        self.cadenceGraph = cadenceGraph

        let coordinates = Self.coordinates(latitudes: routeLatitudes, longitudes: routeLongitudes)
        let points = Self.routePoints(coordinates: coordinates, zoneIndexes: routeZoneIndexes)
        let smoothed = Self.smooth(Self.thin(Self.trimmed(points)))

        precomputedRoutePoints = smoothed
        precomputedStartCoordinate = smoothed.first?.coordinate
        precomputedEndCoordinate = smoothed.last?.coordinate
        precomputedRouteSegments = Self.buildRouteSegments(from: smoothed)

        let overview = Self.overviewCamera(for: coordinates)
        precomputedOverviewCamera = overview
        _cameraPosition = State(initialValue: .camera(overview))
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
            }

            // Kept out of the tree while expanded so the map has the page to
            // itself. The map's own position in the hierarchy never changes, so
            // it stays the same instance and never reloads its tiles.
            if !isMapExpanded {
                heroCard

                metricGrid
            }
        }
    }

    var map: some View {
        Map(position: $cameraPosition, interactionModes: isMapExpanded ? .all : []) {
            ForEach(precomputedRouteSegments.indices, id: \.self) { index in
                let segment = precomputedRouteSegments[index]
                MapPolyline(segment.polyline)
                    .stroke(segment.style, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }

            if let end = precomputedEndCoordinate {
                Annotation("", coordinate: end) {
                    routeFlag("flag.checkered")
                }
            }

            if let start = precomputedStartCoordinate {
                Annotation("", coordinate: start) {
                    routeFlag("flag.fill")
                }
            }

            if let selected = selectedCoordinate, isMapExpanded {
                Annotation("", coordinate: selected) {
                    routeMarker(color: selectedMetric.color, size: Constants.selectedMarkerSize)
                        .shadow(color: .black.opacity(.mediumOpacity), radius: 4, y: 2)
                        // Map annotations don't pick up the ambient transaction,
                        // so the tint change needs its own animation. Ease rather
                        // than spring, for the same reason as the line.
                        .animation(.brightEaseInOut, value: selectedMetric)
                }
            }
        }
        // No compass or scale — the follow camera rotates constantly, which would
        // otherwise keep the compass permanently on screen.
        .mapControls {}
        // Every modifier below is value-driven rather than branched, so expanding
        // re-lays out the same Map instead of building a second one.
        .mapStyle(.standard(elevation: isMapExpanded ? .realistic : .flat))
        .frame(height: max(isMapExpanded ? expandedMapHeight : Constants.mapHeight, Constants.mapHeight))
        .clipShape(
            RoundedRectangle(
                cornerRadius: isMapExpanded ? .spacing0x : .cornerRadius24,
                style: .continuous
            )
        )
        .overlay(alignment: .topTrailing) {
            BrightRoundButton(
                systemImage: isMapExpanded
                    ? "arrow.down.right.and.arrow.up.left"
                    : "arrow.up.left.and.arrow.down.right",
                size: isMapExpanded ? .large : .medium,
                onTapCallback: toggleMap
            )
            // Expanded, it stands in for the sheet's close button, so it sits
            // where that would be rather than tight to the map's corner.
            .padding(.top, isMapExpanded ? .spacing3x : .spacing2x)
            .padding(.trailing, isMapExpanded ? .spacing3x : .spacing2x)
        }
        .overlay(alignment: .bottom) {
            if isMapExpanded {
                breakdown
                    .padding(.horizontal, .spacing2x)
                    .padding(.bottom, .spacing5x)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Cancels the page's own inset so the expanded map runs edge to edge.
        .padding(.horizontal, isMapExpanded ? -CGFloat.spacing3x : .spacing0x)
        // The scroll container stops above the home indicator; let the map fill it.
        .ignoresSafeArea(.container, edges: isMapExpanded ? Edge.Set.bottom : [])
        .contentShape(.rect)
        .onTapGesture { if !isMapExpanded { toggleMap() } }
        .onChange(of: selectedSecond) { _, _ in updateCamera() }
    }

    private var breakdown: some View {
        HeartWorkoutPerformanceGraphWidget(
            hrAvg: hrAvg ?? 0,
            duration: duration ?? TimeDuration(),
            avgPace: avgPaceSecondsPerKm ?? 0,
            altitudeGain: Amount(unit: "M", value: altitudeGainMetres),
            data: HeartWorkoutCombinedGraphData(
                heartData: heartGraph ?? HeartWorkoutSummaryHeartGraphData(),
                altitudeData: altitudeGraph ?? HeartWorkoutSummaryAltitudeGraphData(),
                paceData: paceGraph ?? HeartWorkoutSummaryPaceGraphData(),
                cadenceData: cadenceGraph ?? HeartWorkoutSummaryCadenceGraphData()
            ),
            selectedSecond: stickySelection,
            selectedMetric: $selectedMetric
        )
    }

    /// The chart clears its selection the moment you lift off. The map should hold
    /// its position rather than pulling back out, so nil writes are dropped.
    private var stickySelection: Binding<Double?> {
        Binding(
            get: { selectedSecond },
            set: { newValue in
                if let newValue {
                    selectedSecond = newValue
                }
            }
        )
    }

    private func toggleMap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        // Ease, not spring. A spring undershoots past its target, and a map
        // briefly sized near zero hands CoreAnimation an invalid Metal drawable,
        // which trips a debug-layer assertion and kills the app.
        withAnimation(.brightEaseInOut) {
            isMapExpanded.toggle()
        }

        guard isMapExpanded else {
            // Back to exactly the framing the map opens at, and reset the follow
            // state so the next expand flies in from the same place.
            isFollowing = false
            chaseHeading = nil
            lastFraction = 0
            selectedSecond = 0
            withAnimation(.easeOut(duration: Constants.flyToDuration)) {
                cameraPosition = .camera(precomputedOverviewCamera)
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Constants.flyToDuration))
                cameraPosition = .camera(precomputedOverviewCamera)
            }
            return
        }

        // Let the expansion settle on the route overview before flying in, so the
        // wide shot isn't hidden behind the resize. Explicitly main-actor: the
        // continuation writes view state.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Constants.flyInDelay))
            updateCamera()
        }
    }

    private func routeFlag(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: Constants.markerSize, weight: .bold))
            .foregroundStyle(Color.textColor)
            // The basemap is busy, so the glyph needs some separation from it.
            .shadow(color: .black.opacity(.veryLowOpacity), radius: 2, y: 1)
    }

    private func routeMarker(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }

    private enum Constants {
        static let mapHeight: CGFloat = 145
        static let markerSize: CGFloat = 18
        static let selectedMarkerSize: CGFloat = 22
        static let iconSize: CGFloat = 24
        /// SF Symbols sit inside their own padding, so they need a smaller point
        /// size than an asset icon to read at the same visual weight.
        static let systemIconScale: CGFloat = 20.0 / 24.0
        static let heroDividerHeight: CGFloat = 76
        /// Increase to load the map faster at the cost of route fidelity.
        static let minimumDistanceMetres: Double = 25
        /// Breathing room around the route on the overview shot. 1.0 is a tight
        /// bounding box; raise it to pull the camera back.
        static let regionPadding: Double = 1.2
        /// Camera distance is an altitude, not a ground extent — at a given
        /// altitude a short frame sees far less ground than a tall one. This pulls
        /// back far enough that the whole route fits in the collapsed card. Raise
        /// it to zoom out further.
        static let overviewDistanceFactor: Double = 3
        static let smoothingIterations = 3

        // MARK: Follow camera

        static let followDistance: CLLocationDistance = 500
        static let followPitch: CGFloat = 65
        static let lookAheadFraction: Double = 0.02
        /// How far behind the marker the camera sits, as a fraction of the route.
        /// Raise it to push the marker further up the screen.
        static let cameraTrailFraction: Double = 0.01
        static let headingResponsiveness: Double = 0.3
        static let jumpThreshold: Double = 0.1
        /// Used for the fly-in and for discontinuous jumps.
        static let flyToDuration: TimeInterval = 0.5
        /// Roughly the expand animation, so the overview is on screen before the
        /// camera starts moving.
        static let flyInDelay: TimeInterval = 0.45
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

    /// Frames the whole route from a fixed altitude, so the collapsed card and the
    /// expanded map show it at the same distance.
    fileprivate static func overviewCamera(for coordinates: [CLLocationCoordinate2D]) -> MapCamera {
        let region = regionForCoordinates(coordinates)

        let north = CLLocationCoordinate2D(
            latitude: region.center.latitude + region.span.latitudeDelta / 2,
            longitude: region.center.longitude
        )
        let south = CLLocationCoordinate2D(
            latitude: region.center.latitude - region.span.latitudeDelta / 2,
            longitude: region.center.longitude
        )
        let east = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude + region.span.longitudeDelta / 2
        )
        let west = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude - region.span.longitudeDelta / 2
        )

        let height = MKMapPoint(north).distance(to: MKMapPoint(south))
        let width = MKMapPoint(east).distance(to: MKMapPoint(west))

        return MapCamera(
            centerCoordinate: region.center,
            distance: max(height, width) * Constants.overviewDistanceFactor,
            heading: 0,
            pitch: 0
        )
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
                latitudeDelta: max(0.01, (maxLat - minLat) * Constants.regionPadding),
                longitudeDelta: max(0.01, (maxLon - minLon) * Constants.regionPadding)
            )
        )
    }
}

#Preview {
    @Previewable @State var isMapExpanded = false
    let workout = HeartDemoData.workout

    ScrollView {
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
            paceGraph: workout.paceGraph,
            cadenceGraph: workout.cadenceGraph,
            isMapExpanded: $isMapExpanded,
            expandedMapHeight: 600
        )
        .padding(.spacing3x)
    }
    .background(Color.sheetBackground)
}

// MARK: - Follow camera

extension HeartWorkoutOverviewWidget {
    private var selectedFraction: Double? {
        let total = max((duration ?? TimeDuration()).totalSeconds, 1)
        return selectedSecond.map { max(0, min(1, $0 / total)) }
    }

    private var selectedCoordinate: CLLocationCoordinate2D? {
        selectedFraction.flatMap { coordinate(atFraction: $0) }
    }

    private func coordinate(atFraction fraction: Double) -> CLLocationCoordinate2D? {
        guard precomputedRoutePoints.count >= 2 else { return nil }

        let position = fraction * Double(precomputedRoutePoints.count - 1)
        let lowerIndex = max(0, min(precomputedRoutePoints.count - 1, Int(floor(position))))
        let upperIndex = max(0, min(precomputedRoutePoints.count - 1, Int(ceil(position))))
        let t = position - Double(lowerIndex)

        let a = precomputedRoutePoints[lowerIndex].coordinate
        let b = precomputedRoutePoints[upperIndex].coordinate

        return CLLocationCoordinate2D(
            latitude: a.latitude + (b.latitude - a.latitude) * t,
            longitude: a.longitude + (b.longitude - a.longitude) * t
        )
    }

    private func updateCamera() {
        guard isMapExpanded,
              let fraction = selectedFraction,
              let current = coordinate(atFraction: fraction)
        else {
            return
        }

        let ahead = coordinate(atFraction: min(1, fraction + Constants.lookAheadFraction)) ?? current
        let targetHeading = bearing(from: current, to: ahead)

        // Centre the camera behind the marker rather than on it, so the marker
        // rides above the middle of the screen and the route ahead stays visible.
        let trailing = coordinate(atFraction: max(0, fraction - Constants.cameraTrailFraction)) ?? current

        let isJump = isFollowing && abs(fraction - lastFraction) > Constants.jumpThreshold
        lastFraction = fraction

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
            centerCoordinate: trailing,
            distance: Constants.followDistance,
            heading: heading,
            pitch: Constants.followPitch
        )

        // Animate the one-off transitions only. Scrubbing fires continuously, and
        // wrapping every update in `withAnimation` restarts the ease each time, so
        // the camera decelerates towards a target it keeps re-deciding — which
        // reads as a slow crawl. Tracking updates are set directly so the camera
        // stays pinned to the finger.
        guard isFollowing else {
            isFollowing = true
            withAnimation(.easeOut(duration: Constants.flyToDuration)) {
                cameraPosition = .camera(camera)
            }
            return
        }

        if isJump {
            withAnimation(.easeOut(duration: Constants.flyToDuration)) {
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
}
