//
//  ExerciseCompleteMapWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import CoreLocation
import MapboxMaps
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

    @State private var viewport: Viewport
    @State private var selectedSecond: Double? = 0
    @State private var chaseHeading: Double?
    @State private var lastFraction: Double = 0
    @State private var isFollowing = false

    @Environment(\.colorScheme) private var colorScheme

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

        // A fixed zoom rather than a fitted overview: an overview is framed to
        // whatever size the map currently has, so the card and the page would
        // show the route at different scales. One camera means one framing.
        _viewport = State(initialValue: Self.overviewViewport(for: coordinates))
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
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous))
                .frame(height: Constants.mapHeight)
                .overlay(alignment: .topTrailing) {
                    if let onOpen {
                        BrightRoundButton(
                            systemImage: "arrow.down.backward.and.arrow.up.forward",
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
        MapboxMaps.Map(viewport: $viewport) {
            // Picking out a section drops the zone colours: the run reads as one
            // faint line so the stretch being read stands away from it.
            if let highlighted {
                PolylineAnnotationGroup {
                    routeLine(fullRoute, color: fadedRouteColor)
                    routeLine(highlighted, color: highlightTint)
                }
                .lineCap(.round)
                .lineJoin(.round)
            } else {
                // A group rather than a loop: the builder takes no ForEach, and
                // one layer for every segment is what keeps the draw cheap.
                PolylineAnnotationGroup(precomputedRouteSegments, id: \.id) { segment in
                    routeLine(segment.coordinates, color: segment.color)
                }
                .lineCap(.round)
                .lineJoin(.round)
            }

            if let end = precomputedEndCoordinate {
                MapViewAnnotation(coordinate: end) {
                    routeFlag("flag.checkered")
                }
                .allowOverlap(true)
            }

            if let start = precomputedStartCoordinate {
                MapViewAnnotation(coordinate: start) {
                    routeFlag("flag.fill")
                }
                .allowOverlap(true)
            }

            if isFullScreen, let selected = selectedCoordinate {
                MapViewAnnotation(coordinate: selected) {
                    routeMarker(color: highlightTint)
                        .shadow(color: .black.opacity(.mediumOpacity), radius: 4, y: 2)
                }
                .allowOverlap(true)
            }
        }
        .mapStyle(.standard(
            lightPreset: colorScheme == .dark ? .night : .day,
            show3dObjects: isFullScreen
        ))
        .gestureOptions(gestureOptions)
        // No compass or scale bar — the card can't be moved, and the page reads
        // cleaner without them. The logo and attribution have to stay.
        .ornamentOptions(OrnamentOptions(
            scaleBar: ScaleBarViewOptions(visibility: .hidden),
            compass: CompassViewOptions(visibility: .hidden)
        ))
        .onChange(of: selectedSecond) { _, _ in updateCamera() }
    }

    // The card is a still: every gesture is off, so a swipe scrolls the sheet
    // it sits in rather than panning the map.
    private var gestureOptions: GestureOptions {
        guard !isFullScreen else { return GestureOptions() }

        var options = GestureOptions()
        options.panEnabled = false
        options.pinchEnabled = false
        options.rotateEnabled = false
        options.pitchEnabled = false
        options.doubleTapToZoomInEnabled = false
        options.doubleTouchToZoomOutEnabled = false
        options.quickZoomEnabled = false
        return options
    }

    private func routeLine(_ coordinates: [CLLocationCoordinate2D], color: Color) -> PolylineAnnotation {
        PolylineAnnotation(lineCoordinates: coordinates)
            .lineColor(StyleColor(UIColor(color)))
            .lineWidth(Constants.routeLineWidth)
            // Standard's lighting dims unlit layers, which reads as a washed-out line.
            .lineEmissiveStrength(Constants.routeEmissiveStrength)
    }

    // Tied to the map's own light preset rather than the system appearance, so
    // the faint line stays legible against whichever basemap is showing.
    private var fadedRouteColor: Color {
        (colorScheme == .dark ? Color.defaultWhite : .defaultBlack).opacity(.veryLowOpacity)
    }

    private var fullRoute: [CLLocationCoordinate2D] {
        precomputedRoutePoints.map(\.coordinate)
    }

    private var highlighted: [CLLocationCoordinate2D]? {
        guard let highlight, precomputedRoutePoints.count >= 2 else { return nil }

        let last = precomputedRoutePoints.count - 1
        let lower = max(0, min(last, Int((Double(last) * highlight.lowerBound).rounded())))
        let upper = max(0, min(last, Int((Double(last) * highlight.upperBound).rounded())))
        guard upper > lower else { return nil }

        return precomputedRoutePoints[lower ... upper].map(\.coordinate)
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
            .overlay(Circle().stroke(Color.defaultWhite, lineWidth: 2))
    }

    private func routeFlag(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: Constants.markerSize, weight: .bold))
            .foregroundStyle(colorScheme == .dark ? Color.defaultWhite : .defaultBlack)
            // The basemap is busy, so the glyph needs some separation from it.
            .shadow(color: .black.opacity(.veryLowOpacity), radius: 2, y: 1)
    }

    private enum Constants {
        // MARK: Follow camera

        static let followZoom: CGFloat = 16.5
        static let followPitch: CGFloat = 65
        static let lookAheadFraction: Double = 0.02
        // How far behind the marker the camera sits, as a fraction of the route.
        // Raise it to push the marker further up the screen.
        static let cameraTrailFraction: Double = 0.01
        static let headingResponsiveness: Double = 0.3
        static let jumpThreshold: Double = 0.1
        // Used for the fly-in and for discontinuous jumps.
        static let flyToDuration: TimeInterval = 0.5

        static let routeLineWidth: Double = 4
        static let routeEmissiveStrength: Double = 1
        static let mapHeight: CGFloat = 145
        static let markerSize: CGFloat = 18
        static let markerDotSize: CGFloat = 22
        // Increase to load the map faster at the cost of route fidelity.
        static let minimumDistanceMetres: Double = 25
        // Breathing room around the route on the overview shot. 1.0 is a tight
        // bounding box; raise it to pull the camera back.
        static let regionPadding: Double = 1.2
        // How many points of screen the whole route spans at the overview zoom.
        // A fixed span, not a fraction of the frame, so the collapsed card and
        // the expanded page draw the route at the same scale. Lower it to pull
        // the camera back.
        static let overviewSpanPoints: Double = 110
        static let minimumOverviewExtentMetres: Double = 200
        static let maximumOverviewZoom: CGFloat = 17
        // Metres per point at zoom 0 on the equator, the base of Mapbox's
        // zoom scale.
        static let metresPerPointAtZoomZero: Double = 156_543.033_92
        static let smoothingIterations = 3
        // One zone-to-zone hop is drawn as this many solid sub-hops, since a
        // polyline annotation takes a single colour and can't carry a gradient.
        static let zoneBlendSteps = 8
    }
}

// MARK: - Route geometry

extension ExerciseCompleteMapWidget {
    struct RoutePoint {
        let coordinate: CLLocationCoordinate2D
        let zoneIndex: Int
    }

    struct RouteSegment: Identifiable {
        let id: Int
        let coordinates: [CLLocationCoordinate2D]
        let color: Color
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
            if distance(from: lastKept.coordinate, to: point.coordinate) >= Constants.minimumDistanceMetres {
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
            segments.append(
                RouteSegment(id: segments.count, coordinates: coords, color: colorForZoneIndex(zone))
            )
        }

        // The hop between zones is stepped through in sub-hops so the colour
        // change fades rather than jumps.
        func appendBlendedSegment(
            from: CLLocationCoordinate2D,
            to: CLLocationCoordinate2D,
            fromZone: Int,
            toZone: Int
        ) {
            let steps = Constants.zoneBlendSteps
            let fromColor = colorForZoneIndex(fromZone)
            let toColor = colorForZoneIndex(toZone)

            for step in 0 ..< steps {
                let start = Double(step) / Double(steps)
                let end = Double(step + 1) / Double(steps)
                let coords = [
                    interpolate(from: from, to: to, fraction: start),
                    interpolate(from: from, to: to, fraction: end),
                ]
                let mix = (start + end) / 2
                segments.append(
                    RouteSegment(
                        id: segments.count,
                        coordinates: coords,
                        color: fromColor.mixed(with: toColor, by: mix)
                    )
                )
            }
        }

        for i in 1 ..< points.count {
            let point = points[i]
            let prevPoint = points[i - 1]

            if point.zoneIndex == currentZone {
                currentCoords.append(point.coordinate)
            } else {
                appendSolidSegment(coords: currentCoords, zone: currentZone)
                appendBlendedSegment(
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

    fileprivate static func interpolate(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        fraction: Double
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: from.latitude + (to.latitude - from.latitude) * fraction,
            longitude: from.longitude + (to.longitude - from.longitude) * fraction
        )
    }

    fileprivate static func distance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        CLLocation(latitude: from.latitude, longitude: from.longitude)
            .distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
    }

    // Frames the whole route at a fixed zoom, so the collapsed card and the
    // expanded map show it at the same scale.
    fileprivate static func overviewViewport(for coordinates: [CLLocationCoordinate2D]) -> Viewport {
        let region = regionForCoordinates(coordinates)

        let north = CLLocationCoordinate2D(
            latitude: region.center.latitude + region.latitudeDelta / 2,
            longitude: region.center.longitude
        )
        let south = CLLocationCoordinate2D(
            latitude: region.center.latitude - region.latitudeDelta / 2,
            longitude: region.center.longitude
        )
        let east = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude + region.longitudeDelta / 2
        )
        let west = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude - region.longitudeDelta / 2
        )

        let extent = max(
            distance(from: north, to: south),
            distance(from: east, to: west),
            Constants.minimumOverviewExtentMetres
        )

        return .camera(center: region.center, zoom: zoom(forExtentMetres: extent, at: region.center.latitude))
    }

    private static func zoom(forExtentMetres extent: Double, at latitude: CLLocationDegrees) -> CGFloat {
        let metresPerPoint = extent / Constants.overviewSpanPoints
        let scale = Constants.metresPerPointAtZoomZero * cos(latitude * .pi / 180) / metresPerPoint
        return min(Constants.maximumOverviewZoom, CGFloat(log2(max(1, scale))))
    }

    fileprivate static func regionForCoordinates(
        _ coordinates: [CLLocationCoordinate2D]
    ) -> (center: CLLocationCoordinate2D, latitudeDelta: CLLocationDegrees, longitudeDelta: CLLocationDegrees) {
        guard let first = coordinates.first else {
            return (CLLocationCoordinate2D(latitude: -33.8769, longitude: 151.2006), 0.02, 0.02)
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

        return (
            CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            max(0.01, (maxLat - minLat) * Constants.regionPadding),
            max(0.01, (maxLon - minLon) * Constants.regionPadding)
        )
    }
}

// MARK: - Colour blending

private extension Color {
    // Mapbox annotations take one resolved colour per line, so the zone-to-zone
    // fade has to be mixed here rather than handed over as a gradient.
    func mixed(with other: Color, by fraction: Double) -> Color {
        let from = UIColor(self)
        let to = UIColor(other)

        var fromRed: CGFloat = 0, fromGreen: CGFloat = 0, fromBlue: CGFloat = 0, fromAlpha: CGFloat = 0
        var toRed: CGFloat = 0, toGreen: CGFloat = 0, toBlue: CGFloat = 0, toAlpha: CGFloat = 0
        from.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)
        to.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)

        let step = CGFloat(max(0, min(1, fraction)))
        return Color(
            red: fromRed + (toRed - fromRed) * step,
            green: fromGreen + (toGreen - fromGreen) * step,
            blue: fromBlue + (toBlue - fromBlue) * step,
            opacity: fromAlpha + (toAlpha - fromAlpha) * step
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

        return Self.interpolate(
            from: precomputedRoutePoints[lowerIndex].coordinate,
            to: precomputedRoutePoints[upperIndex].coordinate,
            fraction: t
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

        let camera = Viewport.camera(
            center: trailing,
            zoom: Constants.followZoom,
            bearing: heading,
            pitch: Constants.followPitch
        )

        // Animate the one-off transitions only. Scrubbing fires continuously, and
        // wrapping every update in an animation restarts the ease each time, so
        // the camera decelerates towards a target it keeps re-deciding — which
        // reads as a slow crawl. Tracking updates are set directly so the camera
        // stays pinned to the finger.
        guard isFollowing else {
            isFollowing = true
            withViewportAnimation(.easeOut(duration: Constants.flyToDuration)) {
                viewport = camera
            }
            return
        }

        if isJump {
            withViewportAnimation(.easeOut(duration: Constants.flyToDuration)) {
                viewport = camera
            }
        } else {
            viewport = camera
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
