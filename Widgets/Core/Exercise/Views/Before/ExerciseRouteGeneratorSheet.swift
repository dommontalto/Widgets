//
//  ExerciseRouteGeneratorSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import MapboxMaps
import MapKit
import SwiftUI

// Full-screen route builder over Mapbox: tap two points or draw a stroke
// and the route snaps to walkable paths via MKDirections.
struct ExerciseRouteGeneratorSheet: View {
    private enum Mode {
        case tap
        case draw
    }

    // Set when the map is opened from a session plan: closing hands back
    // instead of dismissing the presentation.
    var onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode?
    @State private var is3D = true
    @State private var isDarkMap = false
    @State private var viewport: Viewport = .camera(
        center: Constants.initialCenter,
        zoom: Constants.initialZoom,
        bearing: 0,
        pitch: Constants.pitch3D
    )
    // Camera values are only read when an action needs them, never by body.
    // onCameraChanged fires on every rendered frame, so holding them as state
    // would rewrite it mid-update and re-run body just as often.
    @State private var camera = CameraStore()
    @State private var tappedPoints: [CLLocationCoordinate2D] = []
    @State private var drawnPoints: [CLLocationCoordinate2D] = []
    @State private var strokeScreenPoints: [CGPoint] = []
    @State private var isExtending = false
    @State private var route: GeneratedRoute?
    @State private var isGenerating = false
    @State private var undoStack: [Snapshot] = []
    @State private var redoStack: [Snapshot] = []
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var generationTick = 0
    @State private var scrubProgress: Double = 0
    @State private var isScrubbing = false
    @State private var locator = RouteLocator()

    var body: some View {
        ZStack(alignment: .bottom) {
            MapboxMaps.MapReader { proxy in
                map
                    .gesture(RoutePanGesture(isEnabled: mode == .draw) { location, state in
                        handlePan(location, state: state, proxy: proxy)
                    })
                    .overlay { liveStroke }
            }
            .ignoresSafeArea()

            bottomControls
        }
        // Container only, so the keyboard still lifts the card during
        // distance entry.
        .ignoresSafeArea(.container, edges: .bottom)
        .overlay(alignment: .topLeading) { topBar }
        .brightHaptic(.success, trigger: generationTick)
        .onChange(of: scrubProgress) { _, _ in followRoute() }
        .onAppear { locator.request() }
        .onChange(of: locator.lastLocation) { _, location in
            if let location { fly(to: location.coordinate) }
        }
    }

    // MARK: - Map

    private var map: some View {
        MapboxMaps.Map(viewport: $viewport) {
            TapInteraction { context in
                guard mode != .draw, !isGenerating else { return false }
                addTappedPoint(context.coordinate)
                return true
            }

            if locator.isAuthorized {
                Puck2D()
            }

            if drawnPoints.count >= 2 {
                PolylineAnnotation(lineCoordinates: drawnPoints)
                    .lineColor(StyleColor(UIColor(Color.defaultPink)))
                    .lineWidth(Constants.routeLineWidth)
                    .lineJoin(.round)
                    .lineEmissiveStrength(Constants.routeEmissiveStrength)
            }

            if let route {
                PolylineAnnotation(lineCoordinates: route.coordinates)
                    .lineColor(StyleColor(UIColor(Color.defaultPink)))
                    .lineWidth(Constants.routeLineWidth)
                    .lineJoin(.round)
                    .lineEmissiveStrength(Constants.routeEmissiveStrength)

                if let start = route.coordinates.first {
                    MapViewAnnotation(coordinate: start) {
                        routeMarker("figure.run")
                    }
                    .allowOverlap(true)
                }

                if let end = route.coordinates.last {
                    MapViewAnnotation(coordinate: end) {
                        routeMarker("flag.pattern.checkered")
                    }
                    .allowOverlap(true)
                }

                if route.coordinates.count >= 2 {
                    MapViewAnnotation(coordinate: coordinate(atFraction: scrubProgress, along: route.coordinates)) {
                        tappedDot
                    }
                    .allowOverlap(true)
                }
            } else {
                if let first = tappedPoints.first {
                    MapViewAnnotation(coordinate: first) {
                        tappedDot
                    }
                    .allowOverlap(true)
                }

                if tappedPoints.count > 1 {
                    MapViewAnnotation(coordinate: tappedPoints[1]) {
                        tappedDot
                    }
                    .allowOverlap(true)
                }
            }
        }
        .mapStyle(.standard(lightPreset: isDarkMap ? .night : .day))
        .gestureOptions(gestureOptions)
        // No compass or scale bar — the logo and attribution have to stay.
        .ornamentOptions(OrnamentOptions(
            scaleBar: ScaleBarViewOptions(visibility: .hidden),
            compass: CompassViewOptions(visibility: .hidden)
        ))
        .onCameraChanged { event in
            camera.center = event.cameraState.center
            camera.zoom = event.cameraState.zoom
            camera.bearing = event.cameraState.bearing

            // The map only moves mid-stroke when a second finger lands (pinch,
            // rotate or pitch) — the user is navigating, not drawing. Deferred
            // so the clear lands after the frame that reported the move.
            guard mode == .draw, !strokeScreenPoints.isEmpty || !drawnPoints.isEmpty else { return }
            Task {
                strokeScreenPoints = []
                drawnPoints = []
            }
        }
    }

    // Draw mode gives the single finger to the stroke; multi-finger map
    // gestures still pass through since only pan and the one-finger zooms are
    // switched off.
    private var gestureOptions: GestureOptions {
        var options = GestureOptions()
        options.panEnabled = mode != .draw
        options.doubleTapToZoomInEnabled = mode != .draw
        options.quickZoomEnabled = mode != .draw
        return options
    }

    // The stroke stays in screen space until the finger lifts: a polyline
    // annotation rebuilds on every appended point, far too slowly to track a
    // finger, and the camera can't move mid-stroke (that cancels it) so the
    // screen is a stable frame of reference.
    private func handlePan(_ location: CGPoint, state: UIGestureRecognizer.State, proxy: MapboxMaps.MapProxy) {
        guard mode == .draw, !isGenerating else { return }

        switch state {
        case .began, .changed:
            if strokeScreenPoints.isEmpty {
                isExtending = isNearRouteEnd(location, proxy: proxy)
            }
            if let last = strokeScreenPoints.last,
               hypot(location.x - last.x, location.y - last.y) < Constants.minStrokeSamplePt {
                return
            }
            strokeScreenPoints.append(location)
        case .ended, .cancelled, .failed:
            if let map = proxy.map {
                drawnPoints = strokeScreenPoints.map { map.coordinate(for: $0) }
            }
            strokeScreenPoints = []
            commitStroke()
        default:
            break
        }
    }

    private var liveStroke: some View {
        Path { path in
            guard let first = strokeScreenPoints.first else { return }
            path.move(to: first)
            for point in strokeScreenPoints.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(Color.defaultPink, style: Constants.routeStroke)
        .allowsHitTesting(false)
    }

    private var tappedDot: some View {
        Circle()
            .fill(Color.defaultPink)
            .frame(width: Constants.dotSize, height: Constants.dotSize)
            .overlay(Circle().stroke(Color.defaultWhite, lineWidth: 2))
            .shadow(color: .black.opacity(.veryLowOpacity), radius: 4, y: 2)
    }

    private func routeMarker(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: Constants.markerGlyphSize, weight: .medium))
            .foregroundStyle(Color.defaultBlack)
            .frame(width: Constants.markerSize, height: Constants.markerSize)
            .background(Color.defaultPink.opacity(.lowOpacity), in: Circle())
            .shadow(color: .black.opacity(.veryLowOpacity), radius: 4, y: 2)
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack(spacing: .spacing2x) {
            mapButton("xmark") {
                close()
            }

            if isSearching {
                BrightSearchBar("Search", text: $searchText)
                    .onSubmit { performSearch() }
            }

            Spacer(minLength: .spacing2x)

            mapButton(isDarkMap ? "moon.fill" : "sun.max.fill") {
                withAnimation(.brightSnappy) { isDarkMap.toggle() }
            }
            .contentTransition(.symbolEffect(.replace))

            mapButton("magnifyingglass") {
                withAnimation(.brightSnappy) { isSearching.toggle() }
            }
        }
        .padding(.horizontal, .spacing3x)
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private var bottomControls: some View {
        VStack(spacing: .spacing2x) {
            HStack(alignment: .bottom) {
                undoRedo

                Spacer()

                modeColumn
            }
            // Overlaid rather than placed between the clusters, which are
            // uneven widths and would push it off the card's centre.
            .overlay(alignment: .bottom) {
                if route != nil, !isGenerating {
                    BrightPillButton(
                        "Clear Route",
                        systemImage: "xmark",
                        color: .defaultBlack.opacity(.lowOpacity),
                        textColor: .defaultWhite
                    ) {
                        clearRoute()
                    }
                    .frame(height: BrightButtonSizes.large.rawValue)
                }
            }

            bottomCard
        }
        .padding(.spacing3x)
    }

    private func clearRoute() {
        pushUndo()
        scrubProgress = 0
        withAnimation(.brightSnappy) {
            route = nil
            tappedPoints = []
            drawnPoints = []
        }
    }

    private var undoRedo: some View {
        HStack(spacing: .spacing2x) {
            mapButton("arrow.uturn.left", isEnabled: !undoStack.isEmpty && !isGenerating) {
                undo()
            }

            mapButton("arrow.uturn.forward", isEnabled: !redoStack.isEmpty && !isGenerating) {
                redo()
            }
        }
    }

    private var modeColumn: some View {
        VStack(spacing: .spacing2x) {
            mapButton("dot.scope") {
                locator.request()
            }

            mapButton(is3D ? "view.3d" : "view.2d") {
                toggleDimension()
            }

            mapButton("hand.tap.fill", isActive: mode == .tap) {
                select(.tap)
            }

            mapButton("pencil.and.scribble", isActive: mode == .draw) {
                select(.draw)
            }
        }
    }

    private func mapButton(
        _ systemImage: String,
        isActive: Bool = false,
        isEnabled: Bool = true,
        onTap: @escaping () -> Void
    ) -> some View {
        BrightRoundButton(
            systemImage: systemImage,
            size: .large,
            color: isActive ? .defaultGreen : .defaultBlack.opacity(.lowOpacity),
            imageColor: isActive ? .defaultBlack : .defaultWhite,
            onTapCallback: isEnabled ? onTap : nil
        )
        .opacity(isEnabled ? .opaque : .semiLowOpacity)
    }

    // MARK: - Bottom card

    private var bottomCard: some View {
        VStack(spacing: .spacing2x) {
            cardContent
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .spacing3x)
        .frame(height: Constants.cardHeight)
        // Filled behind the glass rather than tinting it, the way the buttons
        // are — a tint alone washes out over the map.
        .background(Color.defaultBlack.opacity(.lowOpacity), in: Constants.cardShape)
        .modifier(GlassEffect(
            shape: .unevenRoundedRect(top: Constants.cardTopCorner, bottom: Constants.cardBottomCorner),
            interactive: false
        ))
    }

    @ViewBuilder
    private var cardContent: some View {
        if isGenerating {
            BrightSolvingOrb(size: Constants.orbSize, speed: Constants.orbSpeed)

            BrightText("Generating route…", size: .body2, color: .defaultWhite)
        } else if let route {
            statsRow(route)

            routeScrubber
                .padding(.top, .spacing1x)
                .padding(.horizontal, .spacing1x)
        } else if mode == .draw {
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: Constants.drawIconSize, weight: .medium))
                .foregroundStyle(Color.defaultWhite)

            BrightText("Draw on the map to create a route.", size: .body2, color: .defaultWhite)
        } else {
            Image(systemName: "map.fill")
                .font(.system(size: Constants.welcomeIconSize))
                .foregroundStyle(Color.defaultGreen)

            BrightText(
                "Welcome to route generator.\nTap on two points or draw to auto generate a route.",
                size: .body2,
                color: .defaultWhite
            )
            .multilineTextAlignment(.center)
            .frame(maxWidth: Constants.welcomeTextWidth)
        }
    }

    private func statsRow(_ route: GeneratedRoute) -> some View {
        HStack(spacing: .spacing0x) {
            stat("Distance", value: route.formattedDistance)
            stat("Elevation", value: route.formattedElevation)
            stat("Est. Time", value: route.formattedDuration)
        }
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(spacing: .spacing1x) {
            BrightText(title, size: .body2, color: .defaultWhite.opacity(.lowOpacity), weight: .regular)

            BrightText(value, size: .standout2, color: .defaultWhite)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    private var routeScrubber: some View {
        Slider(value: $scrubProgress, in: 0 ... 1) { isEditing in
            isScrubbing = isEditing
        }
        .tint(Color.defaultSkyBlue)
    }

    // MARK: - Actions

    private func select(_ newMode: Mode) {
        withAnimation(.brightSnappy) {
            mode = mode == newMode ? nil : newMode
        }
        drawnPoints = []
    }

    private func toggleDimension() {
        is3D.toggle()
        withViewportAnimation(.easeOut(duration: Constants.cameraAnimation)) {
            viewport = .camera(
                center: camera.center,
                zoom: camera.zoom,
                bearing: camera.bearing,
                pitch: is3D ? Constants.pitch3D : 0
            )
        }
    }

    private func addTappedPoint(_ coordinate: CLLocationCoordinate2D) {
        pushUndo()

        if mode == nil {
            withAnimation(.brightSnappy) { mode = .tap }
        }

        if route != nil || tappedPoints.count >= 2 {
            route = nil
            tappedPoints = [coordinate]
            return
        }

        tappedPoints.append(coordinate)

        if tappedPoints.count == 2 {
            generate(through: tappedPoints)
        }
    }

    private func commitStroke() {
        // Pinch residue — the first finger moving before the second lands, or
        // one finger trailing after a zoom — reads as a stroke, but a
        // deliberate route is never this short.
        guard drawnPoints.count >= 2, straightLineDistance(of: drawnPoints) >= Constants.minStrokeLength else {
            drawnPoints = []
            isExtending = false
            return
        }

        pushUndo()

        // A stroke picked up from the finish marker carries the route on
        // rather than starting over.
        if isExtending, let route, let end = route.coordinates.last {
            isExtending = false
            generate(through: [end] + downsampled(drawnPoints), extending: route)
            return
        }

        isExtending = false
        route = nil
        tappedPoints = []
        generate(through: downsampled(drawnPoints))
    }

    private func isNearRouteEnd(_ point: CGPoint, proxy: MapboxMaps.MapProxy) -> Bool {
        guard let map = proxy.map, let end = route?.coordinates.last else { return false }

        let endPoint = map.point(for: end)
        return hypot(point.x - endPoint.x, point.y - endPoint.y) <= Constants.extendGrabRadius
    }

    // Each leg is one MKDirections request, so a freehand stroke has to shrink
    // to a handful of waypoints before it can route. Intermediate waypoints
    // keep a minimum separation — one that lands just inside a side street
    // forces the route to dip in and double back.
    private func downsampled(_ points: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        guard let first = points.first, let last = points.last else { return points }

        var waypoints = [first]
        for point in points.dropFirst()
            where straightLineDistance(from: waypoints[waypoints.count - 1], to: point) >= Constants.minWaypointSeparation {
            waypoints.append(point)
        }

        // The route should still end exactly where the stroke did.
        if waypoints.count == 1 {
            waypoints.append(last)
        } else if straightLineDistance(from: waypoints[waypoints.count - 1], to: last) >= Constants.minWaypointSeparation {
            waypoints.append(last)
        } else {
            waypoints[waypoints.count - 1] = last
        }

        guard waypoints.count > Constants.maxWaypoints else { return waypoints }

        let step = Double(waypoints.count - 1) / Double(Constants.maxWaypoints - 1)
        return (0 ..< Constants.maxWaypoints).map { waypoints[Int((Double($0) * step).rounded())] }
    }

    private func generate(
        through waypoints: [CLLocationCoordinate2D],
        extending base: GeneratedRoute? = nil
    ) {
        guard waypoints.count >= 2 else { return }
        isGenerating = true

        Task {
            var coordinates: [CLLocationCoordinate2D] = []
            var distance: Double = 0

            var from = waypoints[0]

            for (offset, to) in waypoints.dropFirst().enumerated() {
                let request = MKDirections.Request()
                request.source = MKMapItem(
                    location: CLLocation(latitude: from.latitude, longitude: from.longitude),
                    address: nil
                )
                request.destination = MKMapItem(
                    location: CLLocation(latitude: to.latitude, longitude: to.longitude),
                    address: nil
                )
                request.transportType = .walking

                guard let leg = try? await MKDirections(request: request).calculate().routes.first else { continue }

                // A leg that routes far longer than its crow-flies span has
                // dipped into a side street and doubled back — drop that
                // waypoint and let the next leg bridge the gap. The final leg
                // keeps the stroke's endpoint regardless.
                let isFinal = offset == waypoints.count - 2
                if !isFinal, leg.distance > straightLineDistance(from: from, to: to) * Constants.maxLegDetourFactor {
                    continue
                }

                coordinates += leg.polyline.routeCoordinates
                distance += leg.distance
                from = to
            }

            // Directions can fail offline or over unroutable ground — fall back
            // to the raw points so the gesture still becomes a route.
            if coordinates.count < 2 {
                coordinates = waypoints
                distance = straightLineDistance(of: waypoints)
            }

            let routedLength = straightLineDistance(of: coordinates)
            let pruned = prunedSpurs(coordinates)
            let prunedLength = straightLineDistance(of: pruned)
            if prunedLength < routedLength, routedLength > 0 {
                distance *= prunedLength / routedLength
                coordinates = pruned
            }

            // Routing walks the path network, but the time reads as a run.
            let duration = distance / 1000 * Constants.runningSecondsPerKm

            let generated = GeneratedRoute(coordinates: coordinates, distanceMetres: distance, durationSeconds: duration)

            scrubProgress = 0
            withAnimation(.brightSnappy) {
                route = base.map { $0.appending(generated) } ?? generated
                drawnPoints = []
                isGenerating = false
            }
            generationTick += 1
        }
    }

    // Cuts out-and-back spurs from the routed polyline: a stretch that leaves
    // a point and returns to within a few metres of it is a dip into a side
    // road, not part of the route. Deliberate out-and-backs longer than
    // maxSpurLength survive.
    private func prunedSpurs(_ coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        guard coordinates.count > 2 else { return coordinates }

        var pruned: [CLLocationCoordinate2D] = []
        pruned.reserveCapacity(coordinates.count)

        var i = 0
        while i < coordinates.count {
            pruned.append(coordinates[i])

            var pathLength: Double = 0
            var cutTo: Int?
            var j = i + 1

            while j < coordinates.count, pathLength <= Constants.maxSpurLength {
                pathLength += straightLineDistance(from: coordinates[j - 1], to: coordinates[j])
                if pathLength >= Constants.minSpurLength,
                   straightLineDistance(from: coordinates[i], to: coordinates[j]) <= Constants.spurReturnRadius {
                    cutTo = j
                }
                j += 1
            }

            i = cutTo ?? (i + 1)
        }

        return pruned
    }

    private func straightLineDistance(of points: [CLLocationCoordinate2D]) -> Double {
        zip(points, points.dropFirst()).reduce(0) { total, pair in
            total + straightLineDistance(from: pair.0, to: pair.1)
        }
    }

    private func straightLineDistance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        MKMapPoint(a).distance(to: MKMapPoint(b))
    }

    // MARK: - Undo / redo

    private var currentSnapshot: Snapshot {
        Snapshot(tappedPoints: tappedPoints, route: route)
    }

    private func pushUndo() {
        undoStack.append(currentSnapshot)
        redoStack = []
    }

    private func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        redoStack.append(currentSnapshot)
        apply(snapshot)
    }

    private func redo() {
        guard let snapshot = redoStack.popLast() else { return }
        undoStack.append(currentSnapshot)
        apply(snapshot)
    }

    private func apply(_ snapshot: Snapshot) {
        withAnimation(.brightSnappy) {
            tappedPoints = snapshot.tappedPoints
            route = snapshot.route
        }
    }

    // MARK: - Search & locate

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: camera.center,
            span: MKCoordinateSpan(
                latitudeDelta: Constants.searchSpanDegrees,
                longitudeDelta: Constants.searchSpanDegrees
            )
        )

        Task {
            guard let item = try? await MKLocalSearch(request: request).start().mapItems.first else { return }
            withAnimation(.brightSnappy) {
                isSearching = false
                searchText = ""
            }
            fly(to: item.location.coordinate)
        }
    }

    // MARK: - Scrubbing

    // Set directly rather than animated: scrubbing fires continuously, and
    // restarting an ease on every update reads as a lagging crawl.
    private func followRoute() {
        guard isScrubbing, let route, route.coordinates.count >= 2 else { return }

        let current = coordinate(atFraction: scrubProgress, along: route.coordinates)
        let ahead = coordinate(
            atFraction: min(1, scrubProgress + Constants.lookAheadFraction),
            along: route.coordinates
        )

        viewport = .camera(
            center: current,
            zoom: Constants.followZoom,
            bearing: bearing(from: current, to: ahead),
            pitch: Constants.followPitch
        )
    }

    private func coordinate(
        atFraction fraction: Double,
        along coordinates: [CLLocationCoordinate2D]
    ) -> CLLocationCoordinate2D {
        let position = fraction * Double(coordinates.count - 1)
        let lower = max(0, min(coordinates.count - 1, Int(position.rounded(.down))))
        let upper = max(0, min(coordinates.count - 1, Int(position.rounded(.up))))
        let step = position - Double(lower)

        let from = coordinates[lower]
        let to = coordinates[upper]
        return CLLocationCoordinate2D(
            latitude: from.latitude + (to.latitude - from.latitude) * step,
            longitude: from.longitude + (to.longitude - from.longitude) * step
        )
    }

    private func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDirection {
        let fromLatitude = from.latitude * .pi / 180
        let toLatitude = to.latitude * .pi / 180
        let deltaLongitude = (to.longitude - from.longitude) * .pi / 180

        let y = sin(deltaLongitude) * cos(toLatitude)
        let x = cos(fromLatitude) * sin(toLatitude)
            - sin(fromLatitude) * cos(toLatitude) * cos(deltaLongitude)
        return (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }

    private func fly(to coordinate: CLLocationCoordinate2D) {
        withViewportAnimation(.fly(duration: Constants.cameraAnimation)) {
            viewport = .camera(
                center: coordinate,
                zoom: Constants.flyZoom,
                bearing: 0,
                pitch: is3D ? Constants.pitch3D : 0
            )
        }
    }
}

// MARK: - Support

private struct GeneratedRoute {
    let coordinates: [CLLocationCoordinate2D]
    let distanceMetres: Double
    let durationSeconds: Double

    var formattedDistance: String {
        String(format: "%.1f KM", distanceMetres / 1000)
    }

    var formattedDuration: String {
        "\(Int((durationSeconds / 60).rounded())) Min"
    }

    // MKRoute carries no elevation data, so the prototype estimates the gain
    // from distance at a flat-city climb rate.
    var formattedElevation: String {
        "\(Int((distanceMetres / 1000 * Constants.estimatedClimbPerKm).rounded())) M"
    }

    func appending(_ other: GeneratedRoute) -> GeneratedRoute {
        GeneratedRoute(
            coordinates: coordinates + other.coordinates,
            distanceMetres: distanceMetres + other.distanceMetres,
            durationSeconds: durationSeconds + other.durationSeconds
        )
    }
}

// Deliberately not @Observable: nothing here should invalidate the view.
private final class CameraStore {
    var center = Constants.initialCenter
    var zoom = Constants.initialZoom
    var bearing: CLLocationDirection = 0
}

private struct Snapshot {
    let tappedPoints: [CLLocationCoordinate2D]
    let route: GeneratedRoute?
}

@Observable
private final class RouteLocator: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var lastLocation: CLLocation?
    var isAuthorized = false

    override init() {
        super.init()
        manager.delegate = self
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        isAuthorized = manager.authorizationStatus == .authorizedWhenInUse
            || manager.authorizationStatus == .authorizedAlways
        if isAuthorized {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

// A UIKit pan recognizer bridged into SwiftUI: unlike a SwiftUI gesture over
// Map, its updates keep flowing while MapKit's own recognizers run, so the
// stroke renders live under the finger.
private struct RoutePanGesture: UIGestureRecognizerRepresentable {
    let isEnabled: Bool
    let onUpdate: (CGPoint, UIGestureRecognizer.State) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.maximumNumberOfTouches = 1
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        onUpdate(recognizer.location(in: recognizer.view), recognizer.state)
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    // The map's pinch and rotate must keep working while this recognizer is
    // mid-pan, and vice versa.
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

private extension MKPolyline {
    var routeCoordinates: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }
}

private enum Constants {
    static let initialCenter = CLLocationCoordinate2D(latitude: -33.8769, longitude: 151.2006)
    static let initialZoom: CGFloat = 14.5
    static let flyZoom: CGFloat = 15
    static let pitch3D: CGFloat = 55
    static let cameraAnimation: TimeInterval = 0.6
    static let searchSpanDegrees: CLLocationDegrees = 0.5

    static let routeStroke = StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
    static let routeLineWidth: Double = 5
    // Standard's lighting dims unlit layers, which reads as a washed-out line.
    static let routeEmissiveStrength: Double = 1
    static let maxWaypoints = 6
    static let minWaypointSeparation: CLLocationDistance = 150
    static let minStrokeLength: CLLocationDistance = 150
    // How close to the finish marker a stroke must start to extend the route.
    static let extendGrabRadius: CGFloat = 30
    static let minStrokeSamplePt: CGFloat = 3
    // How much longer than crow-flies a leg may route before it reads as a
    // dip into a side street rather than a road genuinely winding.
    static let maxLegDetourFactor: Double = 2.5
    // Spur pruning: how close a return point must be to where it left, the
    // shortest detour worth cutting, and the longest stretch still treated as
    // a spur rather than a deliberate out-and-back.
    static let spurReturnRadius: CLLocationDistance = 20
    static let minSpurLength: CLLocationDistance = 40
    static let maxSpurLength: CLLocationDistance = 400
    // Average recreational running pace, 5:30 min/km.
    static let runningSecondsPerKm: Double = 330
    static let estimatedClimbPerKm: Double = 4.4

    // The live session card's geometry, so the two bottom cards read as one.
    static let cardHeight: CGFloat = 160
    static let cardTopCorner: CGFloat = 36
    static let cardBottomCorner: CGFloat = 44

    static var cardShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: cardTopCorner,
            bottomLeading: cardBottomCorner,
            bottomTrailing: cardBottomCorner,
            topTrailing: cardTopCorner
        ))
    }

    // Scrubbing rides the route at street level, looking along it.
    static let followZoom: CGFloat = 17
    static let followPitch: CGFloat = 65
    static let lookAheadFraction: Double = 0.02

    static let markerSize: CGFloat = 25
    static let markerGlyphSize: CGFloat = 12
    static let dotSize: CGFloat = 14
    static let welcomeIconSize: CGFloat = 30
    static let orbSize: CGFloat = 64
    static let orbSpeed: Double = 1.2
    static let drawIconSize: CGFloat = 24
    static let welcomeTextWidth: CGFloat = 220
}

#Preview {
    ExerciseRouteGeneratorSheet()
}
