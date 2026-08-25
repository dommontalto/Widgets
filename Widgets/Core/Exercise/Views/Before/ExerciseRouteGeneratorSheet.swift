//
//  ExerciseRouteGeneratorSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import MapKit
import SwiftUI

// Full-screen route builder over Apple Maps: tap two points or draw a stroke
// and the route snaps to walkable paths via MKDirections.
struct ExerciseRouteGeneratorSheet: View {
    private enum Mode {
        case tap
        case draw
    }

    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode?
    @State private var is3D = true
    @State private var cameraPosition: MapCameraPosition = .camera(Constants.initialCamera)
    @State private var currentCamera = Constants.initialCamera
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
    @State private var isEnteringDistance = false
    @State private var distanceText = ""
    @State private var distanceNudge = 0
    @FocusState private var isDistanceFocused: Bool
    @State private var generationTick = 0
    @State private var locator = RouteLocator()

    var body: some View {
        MapReader { proxy in
            map
                .gesture(RoutePanGesture(isEnabled: mode == .draw) { location, state in
                    handlePan(location, state: state, proxy: proxy)
                })
                .overlay { liveStroke }
                .onTapGesture { point in
                    guard mode != .draw, !isGenerating else { return }
                    if let coordinate = proxy.convert(point, from: .local) {
                        addTappedPoint(coordinate)
                    }
                }
        }
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) { topBar }
        .overlay(alignment: .bottom) { bottomControls }
        .brightHaptic(.success, trigger: generationTick)
        .onAppear { locator.request() }
        .onChange(of: locator.lastLocation) { _, location in
            if let location { fly(to: location.coordinate) }
        }
    }

    // MARK: - Map

    private var map: some View {
        Map(position: $cameraPosition, interactionModes: mode == .draw ? Constants.drawInteractions : .all) {
            if locator.isAuthorized {
                UserAnnotation()
            }

            if drawnPoints.count >= 2 {
                MapPolyline(coordinates: drawnPoints)
                    .stroke(Color.defaultPink.opacity(.lowOpacity), style: Constants.routeStroke)
            }

            if let route {
                MapPolyline(coordinates: route.coordinates)
                    .stroke(Color.defaultPink, style: Constants.routeStroke)

                if let start = route.coordinates.first {
                    Annotation("", coordinate: start) {
                        routeMarker("figure.run")
                    }
                }

                if let end = route.coordinates.last {
                    Annotation("", coordinate: end) {
                        routeMarker("flag.pattern.checkered")
                    }
                }
            } else {
                ForEach(tappedPoints.indices, id: \.self) { index in
                    Annotation("", coordinate: tappedPoints[index]) {
                        tappedDot
                    }
                }
            }
        }
        .mapControls {}
        .mapStyle(.standard(elevation: .realistic))
        .onMapCameraChange(frequency: .continuous) { context in
            currentCamera = context.camera

            // The map only moves mid-stroke when a second finger lands (pinch,
            // rotate or pitch) — the user is navigating, not drawing.
            if mode == .draw, !strokeScreenPoints.isEmpty || !drawnPoints.isEmpty {
                strokeScreenPoints = []
                drawnPoints = []
            }
        }
    }

    // Draw mode gives single-finger drags to the stroke; multi-finger map
    // gestures still pass through since only panning is switched off. The
    // stroke stays in screen space until the finger lifts: MapPolyline
    // rebuilds its overlay on every appended point, far too slowly to track a
    // finger, and the camera can't move mid-stroke (that cancels it) so the
    // screen is a stable frame of reference.
    private func handlePan(_ location: CGPoint, state: UIGestureRecognizer.State, proxy: MapProxy) {
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
            drawnPoints = strokeScreenPoints.compactMap { proxy.convert($0, from: .local) }
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
            BrightRoundButton(systemImage: "xmark", size: .large) {
                dismiss()
            }

            if isSearching {
                BrightSearchBar("Search", text: $searchText)
                    .onSubmit { performSearch() }
            }
        }
        .padding(.horizontal, .spacing4x)
    }

    private var bottomControls: some View {
        VStack(spacing: .spacing2x) {
            HStack(alignment: .bottom) {
                if mode == nil, route == nil {
                    searchAndLocate
                } else {
                    undoRedo
                }

                Spacer()

                modeColumn
            }
            .padding(.horizontal, .spacing4x)

            bottomCard
                .padding(.horizontal, .spacing2x)
        }
        .padding(.bottom, .spacing2x)
    }

    private var searchAndLocate: some View {
        HStack(spacing: .spacing1x) {
            darkButton("magnifyingglass") {
                withAnimation(.brightSnappy) { isSearching.toggle() }
            }

            darkButton("dot.scope") {
                locator.request()
            }
        }
    }

    private var undoRedo: some View {
        HStack(spacing: .spacing1x) {
            darkButton("arrow.uturn.left", isEnabled: !undoStack.isEmpty && !isGenerating) {
                undo()
            }

            darkButton("arrow.uturn.forward", isEnabled: !redoStack.isEmpty && !isGenerating) {
                redo()
            }
        }
    }

    private var modeColumn: some View {
        VStack(spacing: .spacing1x) {
            darkButton(is3D ? "view.2d" : "view.3d") {
                toggleDimension()
            }

            darkButton("hand.tap.fill", isActive: mode == .tap) {
                select(.tap)
            }

            darkButton("pencil.and.scribble", isActive: mode == .draw) {
                select(.draw)
            }

            darkButton("point.topleft.down.to.point.bottomright.curvepath", isActive: isEnteringDistance) {
                toggleDistanceEntry()
            }
        }
    }

    private func darkButton(
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
        .padding(.vertical, .spacing4x)
        .modifier(GlassEffect(
            shape: .roundedRect,
            cornerRadius: .cornerRadius40,
            tint: .defaultBlack.opacity(.lowOpacity),
            interactive: false
        ))
    }

    @ViewBuilder
    private var cardContent: some View {
        if isGenerating {
            BrightSolvingOrb(size: Constants.orbSize, speed: Constants.orbSpeed)

            BrightText("Generating route…", size: .body2, color: .defaultWhite)
        } else if isEnteringDistance {
            distanceEntry
        } else if let route {
            statsRow(route)
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

    private var distanceEntry: some View {
        HStack(spacing: .spacing2x) {
            TextField(
                "",
                text: $distanceText,
                prompt: Text("Distance in KM")
                    .foregroundStyle(Color.defaultWhite.opacity(.lowOpacity))
            )
            .font(.standard(size: .body1, weight: .light))
            .foregroundStyle(Color.defaultWhite)
            .keyboardType(.decimalPad)
            .focused($isDistanceFocused)
            .padding(.vertical, .spacing2x)
            .padding(.horizontal, .spacing3x)
            .background(Color.defaultWhite.opacity(.ultraLowOpacity), in: Capsule())
            .brightWiggle(trigger: distanceNudge)

            BrightRoundButton(
                systemImage: "checkmark",
                size: .large,
                color: .defaultGreen,
                imageColor: .defaultBlack
            ) {
                submitDistance()
            }
        }
    }

    private func statsRow(_ route: GeneratedRoute) -> some View {
        HStack(spacing: .spacing0x) {
            ForEach([route.formattedDistance, route.formattedDuration, route.formattedElevation], id: \.self) { stat in
                BrightText(stat, size: .standout2, color: .defaultWhite)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
            }
        }
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
        withAnimation(.easeInOut(duration: Constants.cameraAnimation)) {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: currentCamera.centerCoordinate,
                    distance: currentCamera.distance,
                    heading: currentCamera.heading,
                    pitch: is3D ? Constants.pitch3D : 0
                )
            )
        }
    }

    private func toggleDistanceEntry() {
        withAnimation(.brightSnappy) {
            isEnteringDistance.toggle()
        }
        isDistanceFocused = isEnteringDistance
        if !isEnteringDistance {
            distanceText = ""
        }
    }

    private func submitDistance() {
        let digits = distanceText.filter { "0123456789.".contains($0) }
        guard let kilometres = Double(digits), kilometres > 0 else {
            distanceNudge += 1
            return
        }

        withAnimation(.brightSnappy) {
            isEnteringDistance = false
        }
        isDistanceFocused = false
        distanceText = ""

        pushUndo()
        route = nil
        tappedPoints = []
        generate(through: loopWaypoints(kilometres: kilometres), framesResult: true)
    }

    // A rough circle through the start whose circumference matches the asked
    // distance, headed in a random direction; routing along real paths
    // stretches it, so the radius is scaled down to compensate.
    private func loopWaypoints(kilometres: Double) -> [CLLocationCoordinate2D] {
        let start = locator.lastLocation?.coordinate ?? currentCamera.centerCoordinate
        let radius = kilometres * 1000 / (2 * .pi) * Constants.loopRadiusScale
        let outboundBearing = Double.random(in: 0 ..< 360)
        let centre = coordinate(from: start, metres: radius, bearingDegrees: outboundBearing)

        // The start sits on the circle opposite the outbound bearing; the rest
        // of the waypoints walk the circle back around to it.
        let startAngle = outboundBearing + 180
        var waypoints = [start]
        for step in 1 ..< Constants.loopWaypointCount {
            let angle = startAngle + 360 * Double(step) / Double(Constants.loopWaypointCount)
            waypoints.append(coordinate(from: centre, metres: radius, bearingDegrees: angle))
        }
        waypoints.append(start)
        return waypoints
    }

    private func coordinate(
        from origin: CLLocationCoordinate2D,
        metres: Double,
        bearingDegrees: Double
    ) -> CLLocationCoordinate2D {
        let bearing = bearingDegrees * .pi / 180
        let latitudeDelta = metres * cos(bearing) / Constants.metresPerDegreeLatitude
        let longitudeDelta = metres * sin(bearing)
            / (Constants.metresPerDegreeLatitude * cos(origin.latitude * .pi / 180))
        return CLLocationCoordinate2D(
            latitude: origin.latitude + latitudeDelta,
            longitude: origin.longitude + longitudeDelta
        )
    }

    private func frame(_ coordinates: [CLLocationCoordinate2D]) {
        guard let first = coordinates.first else { return }

        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude
        for point in coordinates {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }

        let centre = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let height = straightLineDistance(
            from: CLLocationCoordinate2D(latitude: minLat, longitude: centre.longitude),
            to: CLLocationCoordinate2D(latitude: maxLat, longitude: centre.longitude)
        )
        let width = straightLineDistance(
            from: CLLocationCoordinate2D(latitude: centre.latitude, longitude: minLon),
            to: CLLocationCoordinate2D(latitude: centre.latitude, longitude: maxLon)
        )

        withAnimation(.easeOut(duration: Constants.cameraAnimation)) {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: centre,
                    distance: max(Constants.minFrameDistance, max(height, width) * Constants.frameDistanceFactor),
                    heading: 0,
                    pitch: 0
                )
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

    private func isNearRouteEnd(_ point: CGPoint, proxy: MapProxy) -> Bool {
        guard let end = route?.coordinates.last,
              let endPoint = proxy.convert(end, to: .local)
        else {
            return false
        }
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
        extending base: GeneratedRoute? = nil,
        framesResult: Bool = false
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

            withAnimation(.brightSnappy) {
                route = base.map { $0.appending(generated) } ?? generated
                drawnPoints = []
                isGenerating = false
            }
            if framesResult {
                frame(coordinates)
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
            center: currentCamera.centerCoordinate,
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

    private func fly(to coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeOut(duration: Constants.cameraAnimation)) {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: coordinate,
                    distance: Constants.flyDistance,
                    heading: 0,
                    pitch: is3D ? Constants.pitch3D : 0
                )
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
    static let initialCamera = MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: -33.8769, longitude: 151.2006),
        distance: 1600,
        heading: 0,
        pitch: pitch3D
    )
    static let pitch3D: CGFloat = 55
    static let flyDistance: CLLocationDistance = 1200
    static let cameraAnimation: TimeInterval = 0.6
    static let searchSpanDegrees: CLLocationDegrees = 0.5

    static let routeStroke = StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
    static let maxWaypoints = 6
    static let minWaypointSeparation: CLLocationDistance = 150
    static let minStrokeLength: CLLocationDistance = 150
    // Single-finger panning stays off in draw mode — that finger is the pen.
    static let drawInteractions: MapInteractionModes = [.zoom, .rotate, .pitch]
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

    // Auto-generated loops: waypoints per lap, how much the ideal circle
    // shrinks to offset real paths stretching it, and how the finished loop is
    // framed on screen.
    static let loopWaypointCount = 5
    static let loopRadiusScale: Double = 0.8
    static let metresPerDegreeLatitude: Double = 111_111
    static let frameDistanceFactor: Double = 2.2
    static let minFrameDistance: CLLocationDistance = 800

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
