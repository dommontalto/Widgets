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

    // The pushed page fills the screen and takes gestures.
    var isFullScreen = false

    // Set on the card to show the open button; nil on the pushed page.
    var onOpen: (() -> Void)?

    @State private var cameraPosition: MapCameraPosition

    // Smoothing the route is expensive enough that it must not re-run on every
    // body evaluation, so it happens once at init.
    private let precomputedRouteSegments: [RouteSegment]
    private let precomputedStartCoordinate: CLLocationCoordinate2D?
    private let precomputedEndCoordinate: CLLocationCoordinate2D?

    init(
        routeLatitudes: [Double]?,
        routeLongitudes: [Double]?,
        routeZoneIndexes: [Int]?,
        isFullScreen: Bool = false,
        onOpen: (() -> Void)? = nil
    ) {
        self.routeLatitudes = routeLatitudes
        self.routeLongitudes = routeLongitudes
        self.routeZoneIndexes = routeZoneIndexes
        self.isFullScreen = isFullScreen
        self.onOpen = onOpen

        let coordinates = Self.coordinates(latitudes: routeLatitudes, longitudes: routeLongitudes)
        let points = Self.routePoints(coordinates: coordinates, zoneIndexes: routeZoneIndexes)
        let smoothed = Self.smooth(Self.thin(Self.trimmed(points)))

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
            map.ignoresSafeArea()
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
        }
        // No compass or scale — the card can't be moved, and the page reads
        // cleaner without them.
        .mapControls {}
        .mapStyle(.standard(elevation: isFullScreen ? .realistic : .flat))
    }

    private func routeFlag(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: Constants.markerSize, weight: .bold))
            .foregroundStyle(Color.textColor)
            // The basemap is busy, so the glyph needs some separation from it.
            .shadow(color: .black.opacity(.veryLowOpacity), radius: 2, y: 1)
    }

    private enum Constants {
        static let mapHeight: CGFloat = 145
        static let markerSize: CGFloat = 18
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
    let workout = ExerciseDemoComplete.cardio.workout

    return ExerciseCompleteMapWidget(
        routeLatitudes: workout.routeLatitudes,
        routeLongitudes: workout.routeLongitudes,
        routeZoneIndexes: workout.routeZoneIndexes,
        onOpen: {}
    )
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}

#Preview("Page") {
    let workout = ExerciseDemoComplete.cardio.workout

    return ExerciseCompleteMapWidget(
        routeLatitudes: workout.routeLatitudes,
        routeLongitudes: workout.routeLongitudes,
        routeZoneIndexes: workout.routeZoneIndexes,
        isFullScreen: true
    )
}
