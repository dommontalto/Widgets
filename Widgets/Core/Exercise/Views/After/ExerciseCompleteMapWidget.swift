//
//  ExerciseCompleteMapWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import MapKit
import SwiftUI

// The route as a still, zone-coloured overview. Tapping it opens the same map
// as a page, which is the only place it can be panned and zoomed.
struct ExerciseCompleteMapWidget: View {
    let routeLatitudes: [Double]?
    let routeLongitudes: [Double]?
    let routeZoneIndexes: [Int]?

    // Only the page draws the breakdown, so the card takes none of this.
    var duration: TimeDuration?
    var hrAvg: Double?
    var altitudeGainMetres: Double?
    var avgPaceSecondsPerKm: Int?
    var heartGraph: ExerciseHeartGraphPayload?
    var altitudeGraph: ExerciseAltitudeGraphPayload?
    var paceGraph: ExercisePaceGraphPayload?
    var cadenceGraph: ExerciseCadenceGraphPayload?
    var startDate = ""
    var endDate = ""

    // The stretch of the route to pick out, as fractions of its length. Nil
    // lights the whole thing in its zone colours.
    var highlight: ClosedRange<Double>?
    var highlightTint: Color = .defaultSkyBlue

    // The pushed page fills the screen and takes gestures.
    var isFullScreen = false

    // Set on the card to show the open button; nil on the pushed page.
    var onOpen: (() -> Void)?

    @State private var cameraPosition: MapCameraPosition
    @State private var selectedSecond: Double? = 0
    @State private var chaseHeading: Double?
    @State private var lastFraction: Double = 0
    @State private var isFollowing = false

    // Smoothing the route is expensive enough that it must not re-run on every
    // body evaluation, so it happens once at init.
    private let precomputedRoutePoints: [RoutePoint]
    private let precomputedRouteSegments: [RouteSegment]
    private let precomputedStartCoordinate: CLLocationCoordinate2D?
    private let precomputedEndCoordinate: CLLocationCoordinate2D?

    init(
        routeLatitudes: [Double]?,
        routeLongitudes: [Double]?,
        routeZoneIndexes: [Int]?,
        highlight: ClosedRange<Double>? = nil,
        highlightTint: Color = .defaultSkyBlue,
        duration: TimeDuration? = nil,
        hrAvg: Double? = nil,
        altitudeGainMetres: Double? = nil,
        avgPaceSecondsPerKm: Int? = nil,
        heartGraph: ExerciseHeartGraphPayload? = nil,
        altitudeGraph: ExerciseAltitudeGraphPayload? = nil,
        paceGraph: ExercisePaceGraphPayload? = nil,
        cadenceGraph: ExerciseCadenceGraphPayload? = nil,
        startDate: String = "",
        endDate: String = "",
        isFullScreen: Bool = false,
        onOpen: (() -> Void)? = nil
    ) {
        self.routeLatitudes = routeLatitudes
        self.routeLongitudes = routeLongitudes
        self.routeZoneIndexes = routeZoneIndexes
        self.duration = duration
        self.hrAvg = hrAvg
        self.altitudeGainMetres = altitudeGainMetres
        self.avgPaceSecondsPerKm = avgPaceSecondsPerKm
        self.heartGraph = heartGraph
        self.altitudeGraph = altitudeGraph
        self.paceGraph = paceGraph
        self.cadenceGraph = cadenceGraph
        self.startDate = startDate
        self.endDate = endDate
        self.highlight = highlight
        self.highlightTint = highlightTint
        self.isFullScreen = isFullScreen
        self.onOpen = onOpen

        let coordinates = Self.coordinates(latitudes: routeLatitudes, longitudes: routeLongitudes)
        let points = Self.routePoints(coordinates: coordinates, zoneIndexes: routeZoneIndexes)
        let smoothed = Self.smooth(Self.thin(Self.trimmed(points)))

        precomputedRoutePoints = smoothed
        precomputedStartCoordinate = smoothed.first?.coordinate
        precomputedEndCoordinate = smoothed.last?.coordinate
        precomputedRouteSegments = Self.buildRouteSegments(from: smoothed)

        // A fixed altitude rather than a region: a region is fitted to whatever
        // frame the map currently has, so the card and the page would show the
        // route at different distances. One camera means one framing.
        _cameraPosition = State(initialValue: .camera(Self.overviewCamera(for: coordinates)))
    }

    var body: some View {
        if isFullScreen {
            map
                .ignoresSafeArea()
                .overlay(alignment: .bottom) {
                    breakdown
                        .padding(.horizontal, .spacing2x)
                }
        } else {
            map
                .frame(height: Constants.mapHeight)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    if let onOpen {
                        BrightRoundButton(
                            systemImage: "arrow.up.left.and.arrow.down.right",
                            size: .medium,
                            onTapCallback: onOpen
                        )
                        .padding(.spacing2x)
                    }
                }
                .contentShape(.rect)
                .onTapGesture { onOpen?() }
        }
    }

    private var map: some View {
        Map(position: $cameraPosition, interactionModes: isFullScreen ? .all : []) {
            // Picking out a section drops the zone colours: the run reads as one
            // faint line so the stretch being read stands away from it.
            if let highlighted {
                MapPolyline(fullRoute)
                    .stroke(Color.textColor.opacity(.minimalOpacity), style: Constants.routeStroke)

                MapPolyline(highlighted)
                    .stroke(highlightTint, style: Constants.routeStroke)
            } else {
                ForEach(precomputedRouteSegments.indices, id: \.self) { index in
                    let segment = precomputedRouteSegments[index]
                    MapPolyline(segment.polyline)
                        .stroke(segment.style, style: Constants.routeStroke)
                }
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

            if isFullScreen, let selected = selectedCoordinate {
                Annotation("", coordinate: selected) {
                    routeMarker(color: highlightTint)
                        .shadow(color: .black.opacity(.mediumOpacity), radius: 4, y: 2)
                }
            }
        }
        // No compass or scale — the card can't be moved, and the page reads
        // cleaner without them.
        .mapControls {}
        .mapStyle(.standard(elevation: isFullScreen ? .realistic : .flat))
        .onChange(of: selectedSecond) { _, _ in updateCamera() }
    }

    private var fullRoute: MKGeodesicPolyline {
        var coordinates = precomputedRoutePoints.map(\.coordinate)
        return MKGeodesicPolyline(coordinates: &coordinates, count: coordinates.count)
    }

    private var highlighted: MKGeodesicPolyline? {
        guard let highlight, precomputedRoutePoints.count >= 2 else { return nil }

        let last = precomputedRoutePoints.count - 1
        let lower = max(0, min(last, Int((Double(last) * highlight.lowerBound).rounded())))
        let upper = max(0, min(last, Int((Double(last) * highlight.upperBound).rounded())))
        guard upper > lower else { return nil }

        var coordinates = precomputedRoutePoints[lower ... upper].map(\.coordinate)
        return MKGeodesicPolyline(coordinates: &coordinates, count: coordinates.count)
    }

    private var breakdown: some View {
        ExerciseCompletePerformanceGraphWidget(
            hrAvg: hrAvg ?? 0,
            duration: duration ?? TimeDuration(),
            avgPace: avgPaceSecondsPerKm ?? 0,
            altitudeGain: Amount(unit: "M", value: altitudeGainMetres),
            data: ExerciseCompleteCombinedGraphData(
                heartData: heartGraph ?? ExerciseHeartGraphPayload(),
                altitudeData: altitudeGraph ?? ExerciseAltitudeGraphPayload(),
                paceData: paceGraph ?? ExercisePaceGraphPayload(),
                cadenceData: cadenceGraph ?? ExerciseCadenceGraphPayload()
            ),
            startDate: startDate,
            endDate: endDate,
            selectedSecond: stickySelection,
            usesGlass: true
        )
    }

    // The chart clears its selection the moment you lift off. The marker should
    // hold its place rather than vanishing, so nil writes are dropped.
    private var stickySelection: Binding<Double?> {
        Binding(
            get: { selectedSecond },
            set: { newValue in
                if let newValue { selectedSecond = newValue }
            }
        )
    }

    private func routeMarker(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: Constants.markerDotSize, height: Constants.markerDotSize)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }

    private func routeFlag(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: Constants.markerSize, weight: .bold))
            .foregroundStyle(Color.textColor)
            // The basemap is busy, so the glyph needs some separation from it.
            .shadow(color: .black.opacity(.veryLowOpacity), radius: 2, y: 1)
    }

    private enum Constants {
        // MARK: Follow camera

        static let followDistance: CLLocationDistance = 500
        static let followPitch: CGFloat = 65
        static let lookAheadFraction: Double = 0.02
        // How far behind the marker the camera sits, as a fraction of the route.
        // Raise it to push the marker further up the screen.
        static let cameraTrailFraction: Double = 0.01
        static let headingResponsiveness: Double = 0.3
        static let jumpThreshold: Double = 0.1
        // Used for the fly-in and for discontinuous jumps.
        static let flyToDuration: TimeInterval = 0.5

        static let routeStroke = StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
        static let mapHeight: CGFloat = 145
        static let markerSize: CGFloat = 18
        static let markerDotSize: CGFloat = 22
        // Increase to load the map faster at the cost of route fidelity.
        static let minimumDistanceMetres: Double = 25
        // Breathing room around the route on the overview shot. 1.0 is a tight
        // bounding box; raise it to pull the camera back.
        static let regionPadding: Double = 1.2
        // Camera distance is an altitude, not a ground extent — at a given
        // altitude a short frame sees far less ground than a tall one. This
        // pulls back far enough that the whole route fits in the card.
        static let overviewDistanceFactor: Double = 3
        static let smoothingIterations = 3
    }
}

// MARK: - Route geometry

extension ExerciseCompleteMapWidget {
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

    // Drops the first and last couple of samples — GPS is usually still settling there.
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

    // Chaikin corner cutting — turns the GPS polyline into something that reads as a road.
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

        // A one-hop polyline so the colour change between zones fades rather than jumps.
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
        case 5: .defaultRed
        default: .defaultBlue
        }
    }

    // Frames the whole route from a fixed altitude, so the collapsed card and the
    // expanded map show it at the same distance.
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

#Preview("Card") {
    let session = ExerciseDemoComplete.cardio.summary

    return ExerciseCompleteMapWidget(
        routeLatitudes: session.routeLatitudes,
        routeLongitudes: session.routeLongitudes,
        routeZoneIndexes: session.routeZoneIndexes,
        onOpen: {}
    )
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}

#Preview("Page") {
    let session = ExerciseDemoComplete.cardio.summary

    return ExerciseCompleteMapWidget(
        routeLatitudes: session.routeLatitudes,
        routeLongitudes: session.routeLongitudes,
        routeZoneIndexes: session.routeZoneIndexes,
        isFullScreen: true
    )
}

// MARK: - Follow camera

extension ExerciseCompleteMapWidget {
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
        guard isFullScreen,
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
