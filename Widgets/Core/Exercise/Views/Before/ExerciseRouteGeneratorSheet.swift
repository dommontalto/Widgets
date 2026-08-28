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

    // Set when the map is opened from a session plan: closing hands the route
    // back instead of dismissing the presentation.
    var onClose: ((ExercisePlannedRoute?) -> Void)?
    var initialRoute: ExercisePlannedRoute?
    var targetDistanceKm: Double?
    var autoGeneratesOnOpen = false

    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode?
    @State private var is3D = true
    @Environment(\.colorScheme) private var colorScheme

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
    @State private var route: ExercisePlannedRoute?
    @State private var isGenerating = false
    @State private var isAwaitingGenerateFix = false
    @State private var undoStack: [Snapshot] = []
    @State private var redoStack: [Snapshot] = []
    @State private var placeCompleter = PlaceSearchCompleter()
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var generationTick = 0
    @State private var scrubProgress: Double = 0
    @State private var isScrubbing = false
    @State private var isCameraAnimating = false
    @State private var locator = ExerciseRouteLocator()
    @State private var isAwaitingFix = false

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
        .overlay(alignment: .top) {
            VStack(spacing: .spacing2x) {
                topBar

                if isSearching, !placeCompleter.suggestions.isEmpty {
                    suggestionList
                }
            }
            // The suggestions land from a delegate callback, outside any
            // withAnimation, so the show/hide has to be driven from here.
            .animation(.brightSnappy, value: placeCompleter.suggestions)
        }
        .onChange(of: searchText) { _, text in
            placeCompleter.update(query: text, around: camera.center)
        }
        .brightHaptic(.success, trigger: generationTick)
        .onChange(of: scrubProgress) { _, _ in followRoute() }
        .onAppear {
            if let initialRoute, initialRoute.coordinates.count >= 2 {
                route = initialRoute
                viewport = .overview(
                    geometry: LineString(initialRoute.coordinates),
                    pitch: Constants.pitch3D,
                    geometryPadding: EdgeInsets(
                        top: Constants.overviewPadding,
                        leading: Constants.overviewPadding,
                        bottom: Constants.overviewPadding,
                        trailing: Constants.overviewPadding
                    )
                )
                locator.request()
            } else {
                locate()
            }

            if autoGeneratesOnOpen {
                generateFromTarget()
            }
        }
        .onChange(of: locator.lastLocation) { _, location in
            guard let location else { return }
            if isAwaitingGenerateFix {
                isAwaitingGenerateFix = false
                generate(targetMetres: targetMetres, from: location.coordinate)
            }
            guard isAwaitingFix else { return }
            isAwaitingFix = false
            fly(to: location.coordinate)
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

                if let end = route.coordinates.last, strokeScreenPoints.isEmpty {
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
        .mapStyle(.standard(lightPreset: colorScheme == .dark ? .night : .day))
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
            camera.pitch = event.cameraState.pitch
            syncDimension(to: event.cameraState.pitch)

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
        .overlay {
            if let head = strokeScreenPoints.last {
                routeMarker("flag.pattern.checkered")
                    .position(head)
            }
        }
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
                BrightSearchBar(
                    "Search",
                    text: $searchText,
                    height: BrightButtonSizes.large.rawValue,
                    autoFocuses: true
                )
                .frame(maxWidth: .infinity)
                .onSubmit { performSearch() }
            } else {
                Spacer(minLength: .spacing2x)
            }

            mapButton("magnifyingglass") {
                if isSearching {
                    closeSearch()
                } else {
                    withAnimation(.brightSnappy) { isSearching = true }
                }
            }
        }
        .padding(.horizontal, .spacing3x)
    }

    private var suggestionList: some View {
        VStack(spacing: .spacing0x) {
            ForEach(Array(placeCompleter.suggestions.enumerated()), id: \.offset) { offset, suggestion in
                suggestionRow(suggestion)

                if offset != placeCompleter.suggestions.count - 1 {
                    ExerciseLogDivider()
                        .padding(.horizontal, .spacing3x)
                }
            }
        }
        .padding(.vertical, .spacing1x)
        .modifier(GlassEffect(shape: .roundedRect, cornerRadius: .cornerRadius20, interactive: false))
        .padding(.horizontal, .spacing3x)
        .transition(.blurReplace)
    }

    private func suggestionRow(_ suggestion: MKLocalSearchCompletion) -> some View {
        Button {
            select(suggestion)
        } label: {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(suggestion.title, size: .body2)
                    .lineLimit(1)

                if !suggestion.subtitle.isEmpty {
                    BrightText(suggestion.subtitle, size: .body4, color: .lightTextColor)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .spacing3x)
            .padding(.vertical, .spacing105x)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func close() {
        if let onClose {
            onClose(route)
        } else {
            dismiss()
        }
    }

    private var targetMetres: Double {
        (targetDistanceKm ?? 0) * 1000
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
                if !isGenerating {
                    HStack(spacing: .spacing2x) {
                        if route != nil {
                            BrightPillButton("Clear Route", systemImage: "xmark") {
                                clearRoute()
                            }
                        }

                        if targetMetres > 0 {
                            BrightPillButton("Generate", systemImage: "sparkles") {
                                generateFromTarget()
                            }
                        }
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
                locate()
            }

            mapButton(is3D ? "view.3d" : "view.2d") {
                toggleDimension()
            }
            .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))

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
            color: isActive ? .defaultGreen : nil,
            onTapCallback: isEnabled ? onTap : nil
        )
        .opacity(isEnabled ? .opaque : .semiLowOpacity)
    }

    // MARK: - Bottom card

    private var bottomCard: some View {
        ExerciseRouteCard {
            cardContent
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        if isGenerating {
            BrightSolvingOrb(size: Constants.orbSize, speed: Constants.orbSpeed)

            BrightText("Generating route…", size: .body2)
        } else if let route {
            statsRow(route)

            routeScrubber
                .padding(.top, .spacing1x)
                .padding(.horizontal, .spacing1x)
        } else if mode == .draw {
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: Constants.drawIconSize, weight: .medium))
                .foregroundStyle(Color.textColor)

            BrightText("Draw on the map to create a route.", size: .body2)
        } else {
            Image(systemName: "map.fill")
                .font(.system(size: Constants.welcomeIconSize))
                .foregroundStyle(Color.defaultGreen)

            BrightText(
                "Welcome to route generator.\nTap on two points or draw to auto generate a route.",
                size: .body2,
                color: .lightTextColor
            )
            .multilineTextAlignment(.center)
            .frame(maxWidth: Constants.welcomeTextWidth)
        }
    }

    private func statsRow(_ route: ExercisePlannedRoute) -> some View {
        ExerciseRouteStats(
            distance: route.formattedDistance,
            elevation: route.formattedElevation,
            estimatedTime: route.formattedDuration
        )
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
        withAnimation(.brightEaseInOut) { is3D.toggle() }
        isCameraAnimating = true
        withViewportAnimation(.easeOut(duration: Constants.cameraAnimation)) {
            viewport = .camera(
                center: camera.center,
                zoom: camera.zoom,
                bearing: camera.bearing,
                pitch: is3D ? Constants.pitch3D : 0
            )
        } completion: { _ in
            Task { isCameraAnimating = false }
        }
    }

    // Written only when it crosses, since onCameraChanged fires every frame,
    // and deferred so it lands after the frame that reported the move.
    private func syncDimension(to pitch: CGFloat) {
        let isFlat = pitch <= Constants.flatPitch
        guard !isCameraAnimating, is3D == isFlat else { return }
        Task { withAnimation(.brightEaseInOut) { is3D = !isFlat } }
    }

    private func addTappedPoint(_ coordinate: CLLocationCoordinate2D) {
        pushUndo()

        if mode == nil {
            withAnimation(.brightSnappy) { mode = .tap }
        }

        if let route, let end = route.coordinates.last {
            generate(through: [end, coordinate], extending: route)
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
        extending base: ExercisePlannedRoute? = nil
    ) {
        guard waypoints.count >= 2 else { return }
        isGenerating = true

        Task {
            guard let built = await ExerciseRouteGenerator.route(through: waypoints) else {
                isGenerating = false
                return
            }

            var combined = base.map { $0.appending(built) } ?? built
            if let last = combined.coordinates.indices.last {
                combined.steps.removeAll { $0.maneuver == .arrive }
                combined.steps.append(ExercisePlannedRouteStep(maneuver: .arrive, coordinateIndex: last))
            }

            scrubProgress = 0
            withAnimation(.brightSnappy) {
                route = combined
                drawnPoints = []
                isGenerating = false
            }
            generationTick += 1
        }
    }

    // MARK: - Target generation

    private func generateFromTarget() {
        guard targetMetres > 0, !isGenerating else { return }
        if let start = locator.cachedLocation?.coordinate {
            generate(targetMetres: targetMetres, from: start)
        } else {
            isAwaitingGenerateFix = true
            locator.request()
        }
    }

    private func generate(targetMetres: Double, from start: CLLocationCoordinate2D) {
        pushUndo()
        isGenerating = true
        scrubProgress = 0
        withAnimation(.brightSnappy) {
            route = nil
            tappedPoints = []
            drawnPoints = []
        }

        Task {
            let generated = await ExerciseRouteGenerator.outAndBack(targetMetres: targetMetres, from: start)
            withAnimation(.brightSnappy) {
                route = generated
                isGenerating = false
            }
            generationTick += 1
            frame(generated)
        }
    }

    private func frame(_ route: ExercisePlannedRoute) {
        guard route.coordinates.count >= 2 else { return }
        isCameraAnimating = true
        withViewportAnimation(.easeOut(duration: Constants.cameraAnimation)) {
            viewport = .overview(
                geometry: LineString(route.coordinates),
                pitch: is3D ? Constants.pitch3D : 0,
                geometryPadding: EdgeInsets(
                    top: Constants.overviewPadding,
                    leading: Constants.overviewPadding,
                    bottom: Constants.overviewPadding,
                    trailing: Constants.overviewPadding
                )
            )
        } completion: { _ in
            Task { isCameraAnimating = false }
        }
    }

    private func straightLineDistance(of points: [CLLocationCoordinate2D]) -> Double {
        ExerciseRouteGenerator.straightLineDistance(of: points)
    }

    private func straightLineDistance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        ExerciseRouteGenerator.straightLineDistance(from: a, to: b)
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
            closeSearch()
            fly(to: coordinate(of: item))
        }
    }

    private func select(_ suggestion: MKLocalSearchCompletion) {
        Task {
            guard let item = try? await MKLocalSearch(request: MKLocalSearch.Request(completion: suggestion))
                .start().mapItems.first else { return }
            closeSearch()
            fly(to: coordinate(of: item))
        }
    }

    private func coordinate(of item: MKMapItem) -> CLLocationCoordinate2D {
        if #available(iOS 26, *) {
            item.location.coordinate
        } else {
            legacyCoordinate(of: item)
        }
    }

    @available(iOS, deprecated: 26.0)
    private func legacyCoordinate(of item: MKMapItem) -> CLLocationCoordinate2D {
        item.placemark.coordinate
    }

    // Clearing the text also empties the suggestions via onChange.
    private func closeSearch() {
        withAnimation(.brightSnappy) {
            isSearching = false
            searchText = ""
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

    // The cached fix moves the camera on the tap itself; the fresh one that
    // lands seconds later corrects it.
    private func locate() {
        isAwaitingFix = true
        locator.request()
        if let coordinate = locator.cachedLocation?.coordinate {
            fly(to: coordinate)
        }
    }

    private func fly(to coordinate: CLLocationCoordinate2D) {
        isCameraAnimating = true
        withViewportAnimation(.fly(duration: Constants.cameraAnimation)) {
            viewport = .camera(
                center: coordinate,
                zoom: Constants.flyZoom,
                bearing: 0,
                pitch: is3D ? Constants.pitch3D : 0
            )
        } completion: { _ in
            Task { isCameraAnimating = false }
        }
    }
}

// MARK: - Support

// Deliberately not @Observable: nothing here should invalidate the view.
private final class CameraStore {
    var center = Constants.initialCenter
    var zoom = Constants.initialZoom
    var bearing: CLLocationDirection = 0
    var pitch: CGFloat = Constants.pitch3D
}

private struct Snapshot {
    let tappedPoints: [CLLocationCoordinate2D]
    let route: ExercisePlannedRoute?
}

// Streams place suggestions for the typed fragment, biased to where the
// camera currently sits so nearby places rank first.
@Observable
private final class PlaceSearchCompleter: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()

    var suggestions: [MKLocalSearchCompletion] = []

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func update(query: String, around center: CLLocationCoordinate2D) {
        let fragment = query.trimmingCharacters(in: .whitespaces)
        guard !fragment.isEmpty else {
            completer.cancel()
            suggestions = []
            return
        }

        completer.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: Constants.searchSpanDegrees,
                longitudeDelta: Constants.searchSpanDegrees
            )
        )
        completer.queryFragment = fragment
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = Array(completer.results.prefix(Constants.maxSuggestions))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
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

private enum Constants {
    static let initialCenter = CLLocationCoordinate2D(latitude: -33.8769, longitude: 151.2006)
    static let initialZoom: CGFloat = 14.5
    static let flyZoom: CGFloat = 15
    static let pitch3D: CGFloat = 55
    // Mapbox rarely lands on an exact 0 at the bottom of a pitch drag.
    static let flatPitch: CGFloat = 1
    static let cameraAnimation: TimeInterval = 0.6
    static let searchSpanDegrees: CLLocationDegrees = 0.5
    static let maxSuggestions = 5

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
    static let overviewPadding: CGFloat = .spacing8x


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
