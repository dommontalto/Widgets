//
//  WaypointMap.swift
//  Widgets
//
//  Created by Dom Montalto on 24/11/2026.
//

import SwiftUI

// The terrain map. Dragging moves it, twisting two fingers turns it, pinching zooms,
// and the two buttons tilt it into 3D and bring it back to the user with north up.
struct WaypointMap: View {
    var route = WaypointRoute.demo
    @Binding var correction: WaypointCorrection
    @Binding var rain: WaypointRainStyle
    @Binding var floating: WaypointFloatingClouds
    // Set on the copy shown full screen: it takes all the height it's given and
    // swaps the expand button for a close one.
    var fillsScreen = false

    @Environment(\.dismiss) private var dismiss
    @State private var isExpanded = false

    @State private var camera = WaypointCamera.intro
    @State private var is3D = true
    @State private var selection: WaypointMarker.ID?
    // Trails `correction` by the time it takes the old line to pull back.
    @State private var drawnCorrection = WaypointCorrection.decrease
    @State private var correctionDrawn = 1.0
    @State private var isVisible = false
    @State private var hasPlayedIntro = false
    @State private var dragStartFocus: CGPoint?
    @State private var twistStartHeading: Double?
    @State private var pinchStartZoom: Double?
    @State private var thunder = 0

    var body: some View {
        VStack(spacing: .spacing0x) {
            WaypointMapScene(
                camera: camera,
                route: route,
                selection: selection,
                correction: correction,
                drawnCorrection: drawnCorrection,
                correctionDrawn: correctionDrawn,
                rain: rain,
                floating: floating,
                isPaused: !isVisible,
                onSelect: select,
                onCorrect: { correction = $0 }
            )
            .frame(height: fillsScreen ? nil : Constants.height)
            .frame(maxHeight: fillsScreen ? .infinity : nil)
            .clipped()
            // Full screen the terrain runs under the status bar and the home indicator;
            // the buttons laid over it still keep clear of them.
            .ignoresSafeArea(edges: fillsScreen ? .all : [])
            .contentShape(Rectangle())
            .onTapGesture { select(nil) }
            .gesture(WaypointPan(handle: move))
            .simultaneousGesture(pinch)
            .simultaneousGesture(twist)
            .overlay(alignment: .bottomLeading) { legend }
            .overlay(alignment: .bottomTrailing) { controls }
            .overlay(alignment: .topTrailing) { sizeButton }
            .overlay(alignment: .topLeading) { debugPicker }

            if !fillsScreen {
                BrightDividerV5(opacity: Constants.dividerOpacity)
            }
        }
        .fullScreenCover(isPresented: $isExpanded) {
            WaypointMap(route: route, correction: $correction, rain: $rain, floating: $floating, fillsScreen: true)
                .background(Color.defaultBackground.ignoresSafeArea())
        }
        // Full screen there's no page scrolling it into view, so it starts as soon
        // as it's shown.
        .onAppear {
            guard fillsScreen else { return }
            isVisible = true
            playIntro()
        }
        .onScrollVisibilityChange(threshold: Constants.visibleShare) { visible in
            isVisible = visible
            if visible { playIntro() }
        }
        .brightHapticV5(.soft, trigger: compassTick)
        .brightHapticV5(.impact, trigger: thunder)
        .task(id: isVisible) { await rumble() }
        .brightHapticV5(.light, trigger: selection)
        .brightHapticV5(.light, trigger: correction)
        .brightHapticV5(.soft, trigger: drawnCorrection)
        .onAppear { drawnCorrection = correction }
        .onChange(of: correction) { redrawCorrection() }
        .brightHapticV5(.medium, trigger: is3D)
    }

    private var controls: some View {
        VStack(spacing: .spacing105x) {
            BrightRoundButton(
                systemImage: "view.3d",
                size: .large,
                imageColor: is3D ? Color.defaultCyan : nil,
                onTapCallback: toggle3D
            )

            BrightRoundButton(
                systemImage: "dot.scope",
                size: .large,
                imageColor: isAway ? Color.defaultCyan : nil,
                onTapCallback: recentre
            )
        }
        .padding(.trailing, .spacing3x)
        .padding(.bottom, .spacing4x)
    }

    private var sizeButton: some View {
        BrightRoundButton(
            systemImage: fillsScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
            size: .large
        ) {
            if fillsScreen {
                dismiss()
            } else {
                isExpanded = true
            }
        }
        .padding(.trailing, .spacing3x)
        .padding(.top, .spacing3x)
    }

    // On the map rather than the page, so it's there full screen too.
    private var debugPicker: some View {
        Menu {
            Section("Rain") {
                ForEach(WaypointRainStyle.allCases) { option in
                    Button {
                        rain = option
                    } label: {
                        Label {
                            Text(option.title)
                        } icon: {
                            if option == rain {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: option.symbol)
                            }
                        }
                    }
                }
            }

            Section("Floating clouds") {
                ForEach(WaypointFloatingClouds.allCases) { option in
                    Button {
                        floating = option
                    } label: {
                        Label {
                            Text(option.title)
                        } icon: {
                            if option == floating {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: option.symbol)
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "ladybug.fill")
                .padding(.spacing2x)
                .contentShape(Rectangle())
        }
        .padding(.leading, .spacing1x)
        .padding(.top, .spacing1x)
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = pinchStartZoom ?? camera.zoom
                pinchStartZoom = start
                camera.zoom = min(max(start * Double(value.magnification), Constants.minZoom), Constants.maxZoom)
            }
            .onEnded { _ in
                pinchStartZoom = nil
            }
    }

    // Where the camera rests when the map is in 3D.
    private var tilted: WaypointCamera {
        fillsScreen ? .raised : .raisedOnPage
    }

    private var compassTick: Int {
        Int((camera.heading / Constants.degreesPerTick).rounded(.down))
    }

    // Turned off north or dragged off the user, so there's something to go back to.
    private var isAway: Bool {
        abs(camera.heading.remainder(dividingBy: 360)) > Constants.turnedTolerance
            || abs(camera.focusX) > Constants.turnedTolerance
            || abs(camera.focusY) > Constants.turnedTolerance
    }

    private var twist: some Gesture {
        RotateGesture()
            .onChanged { value in
                let start = twistStartHeading ?? camera.heading
                twistStartHeading = start
                camera.heading = start - value.rotation.degrees
            }
            .onEnded { _ in
                twistStartHeading = nil
            }
    }

    // What each line on the map is, since there are three of them leaving the same spot.
    private var legend: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            legendRow("Plan", color: Color.textColor.opacity(.semiLowOpacity))
            legendRow("Your path", color: .defaultYellow)
            legendRow("New route", color: drawnCorrection.color)
        }
        .padding(.leading, .spacing3x)
        .padding(.bottom, .spacing4x)
        .allowsHitTesting(false)
    }

    private func legendRow(_ title: String, color: Color) -> some View {
        HStack(spacing: .spacing1x) {
            Capsule()
                .fill(color)
                .frame(width: Constants.legendKeyWidth, height: Constants.legendKeyHeight)

            BrightText(title, size: .body4, color: .lightTextColor)
        }
    }

    private var restingZoom: Double {
        is3D ? tilted.zoom : WaypointCamera.flat.zoom
    }

    private func move(_ pan: UIPanGestureRecognizer) {
        let projection = WaypointProjection(camera: camera, anchor: .zero)

        switch pan.state {
        case .began:
            dragStartFocus = CGPoint(x: camera.focusX, y: camera.focusY)
        case .changed:
            guard let dragStartFocus else { return }
            let dragged = pan.translation(in: pan.view)
            let covered = projection.groundDistance(dragged: CGSize(width: dragged.x, height: dragged.y))
            focus(on: CGPoint(x: dragStartFocus.x - covered.x, y: dragStartFocus.y - covered.y))
        case .ended, .cancelled:
            let velocity = pan.velocity(in: pan.view)
            let thrown = projection.groundDistance(dragged: CGSize(
                width: Double(velocity.x) * Constants.throwTime,
                height: Double(velocity.y) * Constants.throwTime
            ))
            withAnimation(Constants.glide) {
                focus(on: CGPoint(x: camera.focusX - Double(thrown.x), y: camera.focusY - Double(thrown.y)))
            }
            dragStartFocus = nil
        default:
            break
        }
    }

    // Keeps the camera within reach of the route, so the map can't be dragged off
    // the edge of the terrain.
    private func focus(on point: CGPoint) {
        let distance = Double(hypot(point.x, point.y))
        let pull = distance > Constants.reach ? Constants.reach / distance : 1
        camera.focusX = Double(point.x) * pull
        camera.focusY = Double(point.y) * pull
    }

    private func toggle3D() {
        is3D.toggle()
        let target = is3D ? tilted : WaypointCamera.flat
        withAnimation(Constants.tilt) {
            camera.pitch = target.pitch
            camera.lift = target.lift
            camera.zoom = target.zoom
        }
    }

    private func recentre() {
        withAnimation(Constants.tilt) {
            camera.heading = (camera.heading / 360).rounded() * 360
            camera.zoom = restingZoom
            camera.focusX = 0
            camera.focusY = 0
        }
        select(nil)
    }

    private func select(_ marker: WaypointMarker?) {
        withAnimation(.brightEaseInOut) {
            selection = marker?.id == selection ? nil : marker?.id
        }
    }

    // Pulls the old line back to where it left the drift, then draws the new one out
    // while the labels move over to match.
    private func redrawCorrection() {
        withAnimation(Constants.retract) {
            correctionDrawn = 0
        } completion: {
            withAnimation(.brightDraw) {
                drawnCorrection = correction
                correctionDrawn = 1
            }
        }
    }

    // A thud a moment after each bolt. It waits for the same turns the map draws its
    // lightning from, so the two keep time; how long the thunder trails the flash
    // varies from strike to strike rather than being worked out from how far off the
    // bolt was.
    private func rumble() async {
        guard isVisible else { return }
        while !Task.isCancelled {
            let now = Date.timeIntervalSinceReferenceDate
            let next = ((now / WaypointWeather.strikeEvery).rounded(.down) + 1) * WaypointWeather.strikeEvery
            try? await Task.sleep(for: .seconds(next - now))
            guard !Task.isCancelled, is3D, let strike = WaypointWeather.strike(at: next + Constants.thunderCheck) else { continue }

            let delay = Constants.thunderDelay.lowerBound
                + WaypointTerrain.scatter(strike.index, 18) * (Constants.thunderDelay.upperBound - Constants.thunderDelay.lowerBound)
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            thunder += 1
        }
    }

    private func playIntro() {
        guard !hasPlayedIntro else { return }
        hasPlayedIntro = true
        withAnimation(Constants.intro) {
            camera = tilted
        }
    }

    private enum Constants {
        static let height: CGFloat = 480
        // How far the map turns between each haptic tick.
        static let degreesPerTick: Double = 9
        // How far from the user the map can be dragged.
        static let reach: Double = 170
        static let legendKeyWidth: CGFloat = 12
        static let legendKeyHeight: CGFloat = 4
        static let dividerOpacity: Double = .veryLowOpacity
        static let visibleShare: Double = 0.2
        static let minZoom: Double = 0.75
        static let maxZoom: Double = 2.2
        static let turnedTolerance: Double = 0.5
        static let throwTime: Double = 0.18
        static let glide: Animation = .easeOut(duration: 0.7)
        static let tilt: Animation = .spring(duration: 0.7, bounce: 0.2)
        static let intro: Animation = .easeInOut(duration: 1.8)
        static let retract: Animation = .easeIn(duration: 0.25)
        // Just inside a strike's turn, so the check lands on the right one.
        static let thunderCheck: Double = 0.01
        static let thunderDelay: ClosedRange<Double> = 0.15 ... 0.9
    }
}

// MARK: - Scene

private struct WaypointMapScene: View, Animatable {
    var camera: WaypointCamera
    let route: WaypointRoute
    let selection: WaypointMarker.ID?
    let correction: WaypointCorrection
    let drawnCorrection: WaypointCorrection
    var correctionDrawn: Double
    let rain: WaypointRainStyle
    let floating: WaypointFloatingClouds
    let isPaused: Bool
    let onSelect: (WaypointMarker?) -> Void
    let onCorrect: (WaypointCorrection) -> Void

    private let terrain = WaypointTerrain.demo

    var animatableData: AnimatablePair<WaypointCamera.AnimatableData, Double> {
        get { AnimatablePair(camera.animatableData, correctionDrawn) }
        set {
            camera.animatableData = newValue.first
            correctionDrawn = newValue.second
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let projection = WaypointProjection(
                camera: camera,
                anchor: CGPoint(x: size.width / 2, y: size.height - Constants.anchorInset)
            )

            ZStack {
                TimelineView(.animation(paused: isPaused)) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate

                    Canvas { context, size in
                        draw(&context, projection, size: size, time: time)
                    }
                }

                horizon

                user(projection)

                labels(projection, in: size)
            }
        }
    }

    // MARK: Drawing

    // Back to front: the sky, the land running out to it, then the map, then the
    // weather over the map. The rain and the lightning come out of the clouds, so the
    // clouds go over them, and the light a bolt throws goes over the clouds.
    private func draw(_ context: inout GraphicsContext, _ projection: WaypointProjection, size: CGSize, time: TimeInterval) {
        let tufts = tufts(at: time, projection)
        let strike = strike(at: time, projection, size: size)

        drawSky(&context, projection, size: size)
        drawLand(&context, projection)
        drawHaze(&context, projection, size: size)
        drawTerrain(&context, projection)
        drawShadows(&context, projection, tufts)
        drawFog(&context, projection, time: time)
        drawRadar(&context, projection, time: time)
        drawRoutes(&context, projection, time: time)
        drawDots(&context, projection, time: time)
        drawRain(&context, projection, time: time)
        if let strike { drawBolt(&context, projection, strike) }
        drawClouds(&context, projection, tufts, size: size)
        if let strike { drawFlash(&context, projection, strike, size: size) }
    }

    // How far the terrain has risen off the page, which is also how much of the sky
    // and the weather there is: flat, the map has neither.
    private var raised: Double {
        min(max(camera.lift, 0), 1)
    }

    // MARK: Sky and land

    private func drawSky(_ context: inout GraphicsContext, _ projection: WaypointProjection, size: CGSize) {
        guard raised > 0, let horizon = projection.horizonY, horizon > 0 else { return }
        context.fill(
            Path(CGRect(x: 0, y: 0, width: size.width, height: horizon)),
            with: .linearGradient(
                Gradient(colors: [Color.waypointSky.opacity(raised), Color.waypointHaze.opacity(raised)]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: horizon)
            )
        )
    }

    // The land carrying on past the last contour, drawn as its skyline at wider and
    // wider distances until it meets the horizon, furthest first so each one hides
    // the foot of the one behind. The heights come from the same terrain as the
    // contours and the routes. Flat, they'd be rings on the ground, so they only
    // show once the map is tilted.
    private func drawLand(_ context: inout GraphicsContext, _ projection: WaypointProjection) {
        guard raised > 0 else { return }

        // Fixed bearings rather than ones measured from the camera, so the skyline
        // doesn't crawl as the map turns.
        let first = Int(((camera.heading - Constants.landSpan) / Constants.landStep).rounded(.down))
        let last = Int(((camera.heading + Constants.landSpan) / Constants.landStep).rounded(.up))

        for ring in (0 ..< Constants.landRings).reversed() {
            let radius = Constants.landNear * pow(Constants.landGrowth, Double(ring))
            var ridge: [CGPoint] = []
            var foot: [CGPoint] = []

            for index in first ... last {
                let bearing = Double(index) * Constants.landStep * .pi / 180
                let point = CGPoint(x: sin(bearing) * radius, y: cos(bearing) * radius)
                ridge.append(ground(point, projection))
                foot.append(projection.point(Double(point.x), Double(point.y), height: -terrain.originHeight))
            }

            var face = Path()
            face.addLines(ridge + foot.reversed())
            face.closeSubpath()
            context.fill(face, with: .color(Color.defaultBackground.opacity(raised)))

            var skyline = Path()
            skyline.addLines(ridge)
            // The further ranges are fainter, going into the haze.
            let nearness = 1 - Double(ring) / Double(Constants.landRings)
            context.stroke(
                skyline,
                with: .color(Color.defaultCyan.opacity(Constants.ridgeOpacity * nearness * nearness * raised)),
                lineWidth: Constants.contourWidth
            )
        }
    }

    // The haze that lies along the horizon, over the furthest land.
    private func drawHaze(_ context: inout GraphicsContext, _ projection: WaypointProjection, size: CGSize) {
        guard raised > 0, let horizon = projection.horizonY, horizon > -Constants.hazeDepth else { return }
        // A little of the sky's light on the ground, so a cloud's shadow has something
        // to take away.
        context.fill(
            Path(CGRect(x: 0, y: max(horizon, 0), width: size.width, height: size.height)),
            with: .color(Color.waypointHaze.opacity(Constants.groundLight * raised))
        )
        context.fill(
            Path(CGRect(x: 0, y: horizon, width: size.width, height: Constants.hazeDepth)),
            with: .linearGradient(
                Gradient(colors: [Color.waypointHaze.opacity(raised), Color.waypointHaze.opacity(.zero)]),
                startPoint: CGPoint(x: 0, y: horizon),
                endPoint: CGPoint(x: 0, y: horizon + Constants.hazeDepth)
            )
        )
    }

    // The contours, in three strengths: lines on slopes turned to the sun are bright,
    // lines on slopes turned away are dim. Flat, every line reads the same; raised,
    // the peaks catch more light as well.
    private func drawTerrain(_ context: inout GraphicsContext, _ projection: WaypointProjection) {
        let topLevel = Double(max(terrain.levels.count - 1, 1))

        for (index, level) in terrain.levels.enumerated() {
            let height = level.height - terrain.originHeight
            let lifted = Constants.contourLow + (Constants.contourHigh - Constants.contourLow) * Double(index) / topLevel
            let opacity = Constants.contourFlat + (lifted - Constants.contourFlat) * camera.lift

            for (light, segments) in level.segments.enumerated() {
                var path = Path()
                var cursor = 0
                while cursor < segments.count {
                    path.move(to: projection.point(segments[cursor], segments[cursor + 1], height: height))
                    path.addLine(to: projection.point(segments[cursor + 2], segments[cursor + 3], height: height))
                    cursor += 4
                }
                let sunlight = 1 + (Constants.sunlight[light] - 1) * raised
                context.stroke(path, with: .color(Color.defaultCyan.opacity(opacity * sunlight)), lineWidth: Constants.contourWidth)
            }
        }
    }

    // Fog lying in the low ground, each bank a wide, flat puff that shifts a little.
    private func drawFog(_ context: inout GraphicsContext, _ projection: WaypointProjection, time: TimeInterval) {
        let shown = stage(Constants.labelsAppear, 1) * raised
        guard shown > 0 else { return }

        for (index, spot) in terrain.fogSpots.enumerated() {
            let sway = sin(time * Constants.fogPace + Double(index)) * Constants.fogSway
            let x = Double(spot.x) + sway
            let y = Double(spot.y)
            let height = WaypointTerrain.height(x: x, y: y) - terrain.originHeight
            drawPuff(
                &context, projection,
                x: x, y: y, height: height, radius: Constants.fogRadius,
                color: .waypointHaze, opacity: Constants.fogOpacity * shown, core: 0
            )
        }
    }

    // MARK: Clouds

    // The tufts of cloud that are in front of the camera right now, furthest first.
    // The field wraps round at its edges, and a tuft only forms where the cover is
    // thick enough, which is what gathers them into banks with gaps between.
    private func tufts(at time: TimeInterval, _ projection: WaypointProjection) -> [WaypointTuft] {
        guard raised > 0 else { return [] }

        var tufts: [WaypointTuft] = []
        let highCount = WaypointClouds.count + WaypointClouds.bankCount
        for index in 0 ..< highCount + floating.count {
            let isLow = index >= highCount
            let isBank = !isLow && index >= WaypointClouds.count
            let reach = isLow ? floating.reach : (isBank ? WaypointClouds.bankReach : WaypointClouds.reach)
            let isUpper = !isLow && index.isMultiple(of: 3)
            let drift = WaypointWeather.drift * (isUpper ? WaypointClouds.upperDrift : 1)
            let startX = WaypointTerrain.scatter(index, 4) * reach * 2
            let y = (WaypointTerrain.scatter(index, 5) * 2 - 1) * reach
            // The low ones are always there; the rest only form where the cover is thick.
            let cover = isLow ? 1 : WaypointTerrain.cover(x: startX, y: y)
            guard cover > WaypointClouds.coverLine else { continue }
            // The banks only stand where the tufts have run out.
            if isBank, abs(y) < WaypointClouds.bankStart, abs(startX - reach) < WaypointClouds.bankStart { continue }

            let x = (startX + time * drift).truncatingRemainder(dividingBy: reach * 2) - reach
            let height = isLow
                ? floating.base + WaypointTerrain.scatter(index, 6)
                : WaypointClouds.base + (isUpper ? WaypointClouds.layerGap : 0)
            let ahead = projection.ahead(x, y)
            guard ahead > Constants.cloudsBehind, projection.distance(x, y, height: height) > Constants.nearestCloud else { continue }

            // Thins out towards the edge it leaves by and the one it comes back in at,
            // and into the haze with distance.
            let edge = min((1 - abs(x) / reach) * Constants.edgeFade, 1)
            let haze = 1 - Constants.hazeShare * min(max(ahead / WaypointClouds.hazeReach, 0), 1)
            let size = isLow ? 0.3 : (cover - WaypointClouds.coverLine) / (1 - WaypointClouds.coverLine)
            let base = isLow ? floating.radius : (isBank ? WaypointClouds.bankRadius : WaypointClouds.radius)
            tufts.append(WaypointTuft(
                index: index,
                x: x,
                y: y,
                height: height,
                radius: base * (0.7 + size) * (1 + WaypointTerrain.scatter(index, 9) * WaypointClouds.variety),
                ahead: ahead,
                opacity: edge * haze * (isLow ? floating.opacity : 1),
                caps: isLow ? floating.caps : WaypointClouds.caps,
                tower: isLow ? floating.tower : WaypointClouds.tower
            ))
        }
        return tufts.sorted { $0.ahead > $1.ahead }
    }

    // Each tuft is a darker underside with a paler cap set towards the sun and a
    // little higher, so it reads as lit from one side and in shade beneath.
    private func drawClouds(_ context: inout GraphicsContext, _ projection: WaypointProjection, _ tufts: [WaypointTuft], size: CGSize) {
        let shown = stage(Constants.labelsAppear, 1) * raised
        guard shown > 0 else { return }

        for tuft in tufts {
            let centre = projection.point(tuft.x, tuft.y, height: tuft.height)
            let reach = CGFloat(tuft.radius * projection.scale(tuft.x, tuft.y, height: tuft.height))
            guard centre.x > -reach, centre.x < size.width + reach, centre.y > -reach, centre.y < size.height + reach else { continue }

            let opacity = WaypointClouds.opacity * tuft.opacity * shown
            drawPuff(
                &context, projection,
                x: tuft.x, y: tuft.y, height: tuft.height, radius: tuft.radius,
                color: .waypointCloudShade, opacity: opacity, core: WaypointClouds.core,
                roundness: Constants.cloudRoundness
            )
            // Caps heaped on the underside, each one higher, further in and smaller than
            // the last, so a tuft billows up into a rounded heap instead of lying flat.
            for cap in 0 ..< tuft.caps {
                let seed = tuft.index * Constants.capSeeds + cap
                let rise = Double(cap + 1) / Double(tuft.caps)
                let spread = Constants.capScatter * (1 - rise * Constants.capTaper)
                let offsetX = WaypointSun.x * Constants.capShift + (WaypointTerrain.scatter(seed, 21) * 2 - 1) * spread
                let offsetY = WaypointSun.y * Constants.capShift + (WaypointTerrain.scatter(seed, 22) * 2 - 1) * spread
                drawPuff(
                    &context, projection,
                    x: tuft.x + offsetX * tuft.radius,
                    y: tuft.y + offsetY * tuft.radius,
                    height: tuft.height + Constants.capRise + tuft.tower * rise,
                    radius: tuft.radius * (Constants.capSize + WaypointTerrain.scatter(seed, 23) * Constants.capVariety)
                        * (1 - rise * Constants.capTaper),
                    color: .waypointCloud, opacity: opacity * Constants.capOpacity, core: Constants.capCore,
                    roundness: Constants.cloudRoundness
                )
            }
        }
    }

    // A soft disc lying level in the world, so it's seen as a circle from straight
    // above and flattens towards the horizon. `roundness` is the least it flattens
    // to: fog lies nearly flat, while a cloud has body and stays rounded.
    private func drawPuff(
        _ context: inout GraphicsContext,
        _ projection: WaypointProjection,
        x: Double,
        y: Double,
        height: Double,
        radius: Double,
        color: Color,
        opacity: Double,
        core: Double,
        roundness: CGFloat = Constants.thinnestPuff
    ) {
        let centre = projection.point(x, y, height: height)
        let width = CGFloat(radius * projection.scale(x, y, height: height))
        guard width > Constants.smallestPuff else { return }

        let forward = projection.forward
        let far = projection.point(x + forward.x * radius, y + forward.y * radius, height: height)
        let depth = max(abs(far.y - centre.y), width * roundness)

        var puff = context
        puff.translateBy(x: centre.x, y: centre.y)
        puff.scaleBy(x: 1, y: min(depth / width, 1))
        puff.fill(
            circle(at: .zero, radius: width),
            with: .radialGradient(
                Gradient(colors: [color.opacity(opacity), color.opacity(.zero)]),
                center: .zero,
                startRadius: width * CGFloat(core),
                endRadius: width
            )
        )
    }

    // The shadows of the tufts over the map, thrown away from the sun and laid over
    // the ground they fall on, so they slide across the hills as the clouds drift.
    private func drawShadows(_ context: inout GraphicsContext, _ projection: WaypointProjection, _ tufts: [WaypointTuft]) {
        let shown = stage(Constants.labelsAppear, 1) * raised
        guard shown > 0 else { return }

        var shadows = Path()
        for tuft in tufts {
            let x = tuft.x - WaypointSun.x * WaypointSun.shadowReach
            let y = tuft.y - WaypointSun.y * WaypointSun.shadowReach
            guard x * x + y * y < Constants.shadowRange * Constants.shadowRange else { continue }

            var shadow = Path()
            for step in 0 ..< Constants.shadowSteps {
                let angle = Double(step) / Double(Constants.shadowSteps) * 2 * .pi
                let point = ground(CGPoint(x: x + cos(angle) * tuft.radius, y: y + sin(angle) * tuft.radius), projection)
                if step == 0 {
                    shadow.move(to: point)
                } else {
                    shadow.addLine(to: point)
                }
            }
            shadow.closeSubpath()
            shadows.addPath(shadow)
        }

        context.drawLayer { layer in
            layer.addFilter(.blur(radius: Constants.shadowBlur))
            layer.fill(shadows, with: .color(Color.waypointCloudShadow.opacity(shown)))
        }
    }

    // MARK: Rain

    // Rain falling to the ground it lands on, leaning with the wind. It's thickest
    // under the banks of cloud, and the drops nearest the camera are longer, wider
    // and brighter than the ones further off. A drop spends most of its turn
    // falling; in the styles that splash, it spends the rest as a ring spreading
    // over the ground where it landed.
    private func drawRain(_ context: inout GraphicsContext, _ projection: WaypointProjection, time: TimeInterval) {
        let shown = stage(Constants.labelsAppear, 1) * raised
        guard shown > 0 else { return }

        let fallShare = rain.hasSplashes ? Constants.fallShare : 1
        var nearStreaks = Path()
        var farStreaks = Path()
        var freshRings = Path()
        var fadingRings = Path()

        for drop in 0 ..< rain.dropCount {
            let startX = (WaypointTerrain.scatter(drop, 1) * 2 - 1) * Constants.rainReach
            let y = (WaypointTerrain.scatter(drop, 2) * 2 - 1) * Constants.rainReach
            // The cover is read where the cloud over this spot started out, since the
            // clouds have drifted on from there.
            let cover = WaypointTerrain.cover(x: startX - time * WaypointWeather.drift, y: y)
            guard cover > WaypointClouds.coverLine || WaypointTerrain.scatter(drop, 19) < rain.clearSkyShare else { continue }

            let turn = (time / rain.fallTime + WaypointTerrain.scatter(drop, 3)).truncatingRemainder(dividingBy: 1)
            let fallen = min(turn / fallShare, 1)
            let x = startX + rain.lean * fallen
            let floor = WaypointTerrain.height(x: x, y: y) - terrain.originHeight

            if turn < fallShare {
                let height = floor + (Constants.rainCeiling - floor) * (1 - fallen)
                let isNear = projection.scale(x, y, height: height) > Constants.nearRain
                let length = rain.dropLength * (isNear ? Constants.nearRainLength : 1)
                let tail = rain.lean * length / Constants.rainCeiling
                let foot = projection.point(x, y, height: height)
                let head = projection.point(x - tail, y, height: height + length)
                if isNear {
                    nearStreaks.move(to: foot)
                    nearStreaks.addLine(to: head)
                } else {
                    farStreaks.move(to: foot)
                    farStreaks.addLine(to: head)
                }
            } else {
                let grown = (turn - fallShare) / (1 - fallShare)
                let radius = Constants.splashSize * grown
                var ring = Path()
                for step in 0 ..< Constants.splashSteps {
                    let angle = Double(step) / Double(Constants.splashSteps) * 2 * .pi
                    // Each point of the ring sits on the ground under it, so a splash
                    // lies over a slope instead of floating level across it.
                    let point = ground(CGPoint(x: x + cos(angle) * radius, y: y + sin(angle) * radius), projection)
                    if step == 0 {
                        ring.move(to: point)
                    } else {
                        ring.addLine(to: point)
                    }
                }
                ring.closeSubpath()
                if grown < Constants.splashFadeAt {
                    freshRings.addPath(ring)
                } else {
                    fadingRings.addPath(ring)
                }
            }
        }

        // Pale like the clouds it falls from, not the cyan of the map's own lines.
        let color = Color.waypointCloud
        let opacity = rain.opacity * shown
        context.stroke(
            farStreaks,
            with: .color(color.opacity(opacity * Constants.farRainOpacity)),
            style: StrokeStyle(lineWidth: rain.dropWidth, lineCap: .round)
        )
        context.stroke(
            nearStreaks,
            with: .color(color.opacity(opacity)),
            style: StrokeStyle(lineWidth: rain.dropWidth + Constants.nearRainWidth, lineCap: .round)
        )
        context.stroke(freshRings, with: .color(color.opacity(opacity)), lineWidth: Constants.rainWidth)
        context.stroke(fadingRings, with: .color(color.opacity(Constants.fadingRingOpacity * shown)), lineWidth: Constants.rainWidth)
    }

    // MARK: Lightning

    // The bolt that's striking right now, if one is: which tuft it comes out of,
    // where it lands, and how bright it is. It flickers twice before it fades. The
    // tuft is chosen from where the clouds were when the strike began, so the bolt
    // stays with its cloud as the field drifts.
    private func strike(at time: TimeInterval, _ projection: WaypointProjection, size: CGSize) -> WaypointStrike? {
        guard raised > 0, camera.reveal >= 1, let turn = WaypointWeather.strike(at: time), turn.age < WaypointWeather.strikeLength else { return nil }

        let brightness: Double = if turn.age < Constants.flickerStart {
            1
        } else if turn.age < Constants.flickerEnd {
            0
        } else {
            1 - (turn.age - Constants.flickerEnd) / (WaypointWeather.strikeLength - Constants.flickerEnd)
        }
        guard brightness > 0 else { return nil }

        // Only from a cloud that's on screen, so the bolt is too.
        let margin = size.width * Constants.strikeMargin
        let inRange = tufts(at: time - turn.age, projection).filter { tuft in
            guard Constants.strikeRange.contains(tuft.ahead) else { return false }
            let centre = projection.point(tuft.x, tuft.y, height: tuft.height)
            return centre.x > margin && centre.x < size.width - margin && centre.y > 0
        }
        guard !inRange.isEmpty else { return nil }
        let chosen = inRange[Int(WaypointTerrain.scatter(turn.index, 10) * Double(inRange.count)) % inRange.count]
        guard let tuft = tufts(at: time, projection).first(where: { $0.index == chosen.index }) else { return nil }

        let groundX = tuft.x + (WaypointTerrain.scatter(turn.index, 11) * 2 - 1) * Constants.strikeDrift
        let groundY = tuft.y + (WaypointTerrain.scatter(turn.index, 20) * 2 - 1) * Constants.strikeDrift
        return WaypointStrike(seed: turn.index, tuft: tuft, groundX: groundX, groundY: groundY, brightness: brightness)
    }

    // A jagged line from the cloud to the ground, thick where it leaves the cloud and
    // thinner below, with thin branches splitting off to either side on the way down.
    private func drawBolt(_ context: inout GraphicsContext, _ projection: WaypointProjection, _ strike: WaypointStrike) {
        let tuft = strike.tuft
        let floor = WaypointTerrain.height(x: strike.groundX, y: strike.groundY) - terrain.originHeight
        let steps = Constants.boltSteps

        var trunk = Path()
        var tip = Path()
        var branches = Path()
        for step in 0 ... steps {
            let progress = Double(step) / Double(steps)
            let isEnd = step == 0 || step == steps
            let seed = strike.seed * steps * 2 + step
            let jitterX = isEnd ? 0 : (WaypointTerrain.scatter(seed, 12) * 2 - 1) * Constants.boltJitter
            let jitterY = isEnd ? 0 : (WaypointTerrain.scatter(seed, 13) * 2 - 1) * Constants.boltJitter
            let x = tuft.x + (strike.groundX - tuft.x) * progress + jitterX
            let y = tuft.y + (strike.groundY - tuft.y) * progress + jitterY
            let height = tuft.height + (floor - tuft.height) * progress
            let point = projection.point(x, y, height: height)

            if step == 0 {
                trunk.move(to: point)
            } else if step <= steps / 2 {
                trunk.addLine(to: point)
                if step == steps / 2 { tip.move(to: point) }
            } else {
                tip.addLine(to: point)
            }

            if Constants.branchSteps.contains(step) {
                let side: Double = WaypointTerrain.scatter(seed, 15) < 0.5 ? -1 : 1
                branches.move(to: point)
                for reach in 1 ... Constants.branchLength {
                    let drop = (floor - tuft.height) / Double(steps) * Double(reach) * Constants.branchFall
                    // Crooked like the bolt it leaves, not a straight spur.
                    let kink = (WaypointTerrain.scatter(seed * Constants.branchLength + reach, 24) * 2 - 1) * Constants.branchSpread
                    branches.addLine(to: projection.point(
                        x + (Double(reach) * Constants.branchSpread + kink) * side,
                        y,
                        height: height + drop
                    ))
                }
            }
        }

        let color = Color.defaultCyan.opacity(strike.brightness)
        let glow = StrokeStyle(lineWidth: Constants.boltGlowWidth, lineCap: .round, lineJoin: .round)
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: Constants.glowBlur))
            layer.stroke(trunk, with: .color(Color.defaultBlue.opacity(strike.brightness)), style: glow)
            layer.stroke(tip, with: .color(Color.defaultBlue.opacity(strike.brightness)), style: glow)
        }
        context.stroke(trunk, with: .color(color), style: StrokeStyle(lineWidth: Constants.trunkWidth, lineCap: .round, lineJoin: .round))
        context.stroke(tip, with: .color(color), style: StrokeStyle(lineWidth: Constants.tipWidth, lineCap: .round, lineJoin: .round))
        context.stroke(branches, with: .color(color), style: StrokeStyle(lineWidth: Constants.branchWidth, lineCap: .round, lineJoin: .round))
    }

    // What the bolt lights up: its own cloud from inside, the sky a little, and the
    // ground around where it lands. Added on top as light, over the clouds.
    private func drawFlash(_ context: inout GraphicsContext, _ projection: WaypointProjection, _ strike: WaypointStrike, size: CGSize) {
        var light = context
        light.blendMode = .plusLighter

        if let horizon = projection.horizonY, horizon > 0 {
            // Down to the horizon and then out over the haze below it, so the lit sky
            // has no edge.
            let depth = horizon + Constants.hazeDepth
            let flash = Color.waypointCloud.opacity(Constants.skyFlash * strike.brightness)
            light.fill(
                Path(CGRect(x: 0, y: 0, width: size.width, height: depth)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: flash, location: 0),
                        .init(color: flash, location: horizon / depth),
                        .init(color: Color.waypointCloud.opacity(.zero), location: 1),
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: depth)
                )
            )
        }

        let tuft = strike.tuft
        let crown = projection.point(tuft.x, tuft.y, height: tuft.height)
        let cloudGlow = CGFloat(tuft.radius * projection.scale(tuft.x, tuft.y, height: tuft.height)) * Constants.cloudFlashSize
        light.fill(
            circle(at: crown, radius: cloudGlow),
            with: .radialGradient(
                Gradient(colors: [
                    Color.waypointCloud.opacity(Constants.cloudFlash * strike.brightness),
                    Color.waypointCloud.opacity(.zero),
                ]),
                center: crown,
                startRadius: 0,
                endRadius: cloudGlow
            )
        )

        let floor = WaypointTerrain.height(x: strike.groundX, y: strike.groundY) - terrain.originHeight
        let landing = projection.point(strike.groundX, strike.groundY, height: floor)
        let groundGlow = Constants.groundFlashSize * CGFloat(projection.scale(strike.groundX, strike.groundY, height: floor))
        var ground = light
        ground.translateBy(x: landing.x, y: landing.y)
        ground.scaleBy(x: 1, y: Constants.groundFlashDepth)
        ground.fill(
            circle(at: .zero, radius: groundGlow),
            with: .radialGradient(
                Gradient(colors: [
                    Color.defaultBlue.opacity(Constants.groundFlash * strike.brightness),
                    Color.defaultBlue.opacity(.zero),
                ]),
                center: .zero,
                startRadius: 0,
                endRadius: groundGlow
            )
        )
    }

    private func drawRadar(_ context: inout GraphicsContext, _ projection: WaypointProjection, time: TimeInterval) {
        let reach = Constants.radarReach * stage(0, Constants.routesDrawn)
        guard reach > 0 else { return }

        let origin = ground(.zero, projection)
        var wedge = Path()
        wedge.move(to: origin)
        for step in 0 ... Constants.radarSteps {
            wedge.addLine(to: radarPoint(step, reach: reach, projection))
        }
        wedge.closeSubpath()
        context.fill(
            wedge,
            with: .linearGradient(
                Gradient(colors: [
                    Color.defaultGreen.opacity(Constants.radarNear),
                    Color.defaultGreen.opacity(Constants.radarFar),
                ]),
                startPoint: origin,
                endPoint: ground(CGPoint(x: 0, y: reach), projection)
            )
        )

        let phase = (time / Constants.pingPeriod).truncatingRemainder(dividingBy: 1)
        var ping = Path()
        ping.move(to: radarPoint(0, reach: reach * phase, projection))
        for step in 1 ... Constants.radarSteps {
            ping.addLine(to: radarPoint(step, reach: reach * phase, projection))
        }
        context.stroke(
            ping,
            with: .color(Color.defaultGreen.opacity(Constants.pingOpacity * (1 - phase))),
            lineWidth: Constants.pingWidth
        )
    }

    private func radarPoint(_ step: Int, reach: Double, _ projection: WaypointProjection) -> CGPoint {
        let angle = (Double(step) / Double(Constants.radarSteps) * 2 - 1) * Constants.radarHalfAngle
        return ground(CGPoint(x: sin(angle) * reach, y: cos(angle) * reach), projection)
    }

    private func drawRoutes(_ context: inout GraphicsContext, _ projection: WaypointProjection, time: TimeInterval) {
        let early = stage(0, Constants.routesDrawn)
        let late = stage(Constants.correctionStarts, 1)
        let rounded = StrokeStyle(lineWidth: Constants.routeWidth, lineCap: .round, lineJoin: .round)
        let butt = StrokeStyle(lineWidth: Constants.routeWidth)

        if let trail = track(route.trail, drawn: early, projection) {
            let shading = wash(.defaultGreen, Constants.trailWash, along: trail)
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: Constants.glowBlur))
                layer.stroke(trail.path, with: shading, style: rounded)
            }
            context.stroke(trail.path, with: shading, style: rounded)
        }

        if let planned = track(route.planned, drawn: early, projection) {
            context.stroke(planned.path, with: .color(Color.textColor.opacity(Constants.plannedOpacity)), style: butt)
        }

        if let ahead = track(route.ahead, drawn: late, projection) {
            context.stroke(ahead.path, with: wash(.defaultGreen, Constants.aheadWash, along: ahead), style: butt)
        }

        if let drift = track(route.drift, drawn: early, projection) {
            context.stroke(
                drift.path,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .defaultGreen, location: Constants.driftGreenEnds),
                        .init(color: .defaultYellow, location: Constants.driftYellowStarts),
                    ]),
                    startPoint: drift.start,
                    endPoint: drift.end
                ),
                style: rounded
            )
        }

        if let line = track(drawnCorrection.path, drawn: late * correctionDrawn, projection) {
            let shading = wash(drawnCorrection.color, Constants.correctionWash, along: line)
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: Constants.glowBlur))
                layer.stroke(line.path, with: shading, style: rounded)
            }
            context.stroke(line.path, with: shading, style: rounded)
        }

        let target = ground(drawnCorrection.callout, projection)
        var leader = Path()
        leader.move(to: CGPoint(x: target.x - Constants.leaderWidth, y: target.y - Constants.leaderRise))
        leader.addArc(
            tangent1End: CGPoint(x: target.x - Constants.leaderElbow, y: target.y - Constants.leaderRise),
            tangent2End: target,
            radius: Constants.leaderRadius
        )
        leader.addLine(to: target)
        let leaderOpacity = Constants.leaderOpacity * stage(Constants.labelsAppear, 1) * correctionDrawn * dimming(nil)
        context.stroke(leader, with: .color(Color.textColor.opacity(leaderOpacity)), lineWidth: Constants.leaderLineWidth)
    }

    private func drawDots(_ context: inout GraphicsContext, _ projection: WaypointProjection, time: TimeInterval) {
        var markers = context
        markers.opacity = stage(Constants.correctionStarts, 1)

        for marker in route.markers {
            let point = ground(marker.position, projection)

            switch marker.kind {
            case .milestone:
                markers.drawLayer { layer in
                    layer.addFilter(.blur(radius: Constants.glowBlur))
                    layer.fill(circle(at: point, radius: Constants.dotRadius), with: .color(marker.tint))
                }
                markers.fill(circle(at: point, radius: Constants.dotRadius), with: .color(marker.tint))
            case .checkpoint:
                markers.fill(
                    circle(at: point, radius: Constants.checkpointRadius),
                    with: .color(marker.tint.opacity(Constants.checkpointOpacity))
                )
            case .strain, .goal:
                break
            }

            if marker.id == selection {
                let phase = (time / Constants.pulsePeriod).truncatingRemainder(dividingBy: 1)
                markers.stroke(
                    circle(at: point, radius: Constants.pulseStart + Constants.pulseGrowth * CGFloat(phase)),
                    with: .color(tint(of: marker).opacity(Constants.pulseOpacity * (1 - phase))),
                    lineWidth: Constants.pulseWidth
                )
            }
        }

        let origin = ground(.zero, projection)
        context.fill(circle(at: origin, radius: Constants.originRing), with: .color(.defaultBackground))
        context.fill(circle(at: origin, radius: Constants.dotRadius), with: .color(.defaultGreen))
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: Constants.originGlowBlur))
            layer.fill(circle(at: origin, radius: Constants.dotRadius), with: .color(.defaultGreen))
        }
    }

    private func circle(at point: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
    }

    private func track(_ points: [CGPoint], drawn: Double, _ projection: WaypointProjection) -> WaypointProjectedTrack? {
        let count = Int((Double(points.count - 1) * drawn).rounded()) + 1
        guard count > 1 else { return nil }

        let projected = points.prefix(count).map { ground($0, projection) }
        var path = Path()
        path.addLines(projected)
        return WaypointProjectedTrack(path: path, start: projected[0], end: projected[count - 1])
    }

    private func wash(_ color: Color, _ stops: [WaypointWashStop], along track: WaypointProjectedTrack) -> GraphicsContext.Shading {
        .linearGradient(
            Gradient(stops: stops.map { Gradient.Stop(color: color.opacity($0.opacity), location: $0.location) }),
            startPoint: track.start,
            endPoint: track.end
        )
    }

    private func ground(_ point: CGPoint, _ projection: WaypointProjection) -> CGPoint {
        let x = Double(point.x)
        let y = Double(point.y)
        return projection.point(x, y, height: WaypointTerrain.height(x: x, y: y) - terrain.originHeight)
    }

    // How far through one part of the intro the camera's reveal has got.
    private func stage(_ start: Double, _ end: Double) -> Double {
        min(max((camera.reveal - start) / (end - start), 0), 1)
    }

    private func dimming(_ id: WaypointMarker.ID?) -> Double {
        selection == nil || selection == id ? Constants.fullOpacity : Constants.dimmedOpacity
    }

    // MARK: Overlays

    private var horizon: some View {
        LinearGradient(
            stops: [
                .init(color: .defaultBackground, location: Constants.horizonSolid),
                .init(color: Color.defaultBackground.opacity(.zero), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: Constants.horizonHeight)
        .frame(maxHeight: .infinity, alignment: .top)
        // Tilted, the sky is drawn there instead.
        .opacity(1 - raised)
        .allowsHitTesting(false)
    }

    private func user(_ projection: WaypointProjection) -> some View {
        Image(systemName: "location.north.fill")
            .font(.standardSFPro(size: .standout2, weight: .regular))
            .foregroundStyle(Color.lightTextColor)
            .rotationEffect(.degrees(-camera.heading))
            .rotation3DEffect(.degrees(camera.pitch), axis: (x: 1, y: 0, z: 0))
            .opacity(stage(0, Constants.routesDrawn))
            .position(ground(route.user, projection))
            .allowsHitTesting(false)
    }

    private func labels(_ projection: WaypointProjection, in size: CGSize) -> some View {
        ZStack {
            ForEach(route.markers) { marker in
                Button {
                    onSelect(marker)
                } label: {
                    label(for: marker)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .modifier(WaypointPin(alignment: marker.kind.pinAlignment, offset: marker.kind.pinOffset))
                .opacity(dimming(marker.id))
                .position(position(of: marker, projection, in: size))
            }

            correctionMenu
                .modifier(WaypointPin(
                    alignment: .trailing,
                    offset: CGSize(width: -Constants.leaderWidth - Constants.leaderGap, height: -Constants.leaderRise)
                ))
                .opacity(dimming(nil))
                .position(ground(drawnCorrection.callout, projection))
        }
        .opacity(stage(Constants.labelsAppear, 1))
    }

    private var correctionMenu: some View {
        Menu {
            ForEach(WaypointCorrection.allCases) { option in
                Button {
                    onCorrect(option)
                } label: {
                    Label {
                        Text(option.title)
                    } icon: {
                        if option == correction {
                            Image(systemName: "checkmark")
                        } else {
                            Image(systemName: option.symbol)
                        }
                    }
                }
            }
        } label: {
            BrightText(correction.title, size: .body2)
                .padding(.horizontal, .spacing105x)
                .frame(height: BrightButtonSizes.small.rawValue)
                .contentShape(Capsule())
                .modifier(BrightGlassEffectV5())
        }
    }

    @ViewBuilder
    private func label(for marker: WaypointMarker) -> some View {
        let isSelected = marker.id == selection

        switch marker.kind {
        case .milestone, .checkpoint:
            HStack(spacing: .spacing0x) {
                hitBox

                if marker.kind == .milestone || isSelected {
                    caption(marker, alignment: .leading, symbol: "mountain.2.fill", isSelected: isSelected)
                        .transition(.opacity)
                }
            }
        case .strain:
            HStack(spacing: .spacing105x) {
                caption(marker, alignment: .trailing, symbol: nil, isSelected: isSelected)

                Image(systemName: "exclamationmark.triangle")
                    .font(.standardSFPro(size: .heading, weight: .regular))
                    .foregroundStyle(tint(of: marker))
                    .frame(width: Constants.hitSize, height: Constants.hitSize)
            }
        case .goal:
            VStack(spacing: .spacing0x) {
                Image(systemName: "flag.pattern.checkered")
                    .font(.standardSFPro(size: .subheading2, weight: .regular))
                    .foregroundStyle(marker.tint)
                    .frame(width: Constants.hitSize, height: Constants.hitSize)

                BrightText(marker.subtitle, size: .body4, color: .semiLightTextColor)

                if isSelected {
                    BrightText(marker.detail, size: .body4, color: .lightTextColor)
                        .transition(.opacity)
                }
            }
            .lineLimit(1)
        }
    }

    private func caption(
        _ marker: WaypointMarker,
        alignment: HorizontalAlignment,
        symbol: String?,
        isSelected: Bool
    ) -> some View {
        VStack(alignment: alignment, spacing: .spacing0x) {
            HStack(spacing: .spacing05x) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.standardSFPro(size: .body4, weight: .regular))
                        .foregroundStyle(tint(of: marker))
                }

                BrightText(title(of: marker), size: .body2, color: tint(of: marker))
            }

            BrightText(subtitle(of: marker), size: .body4, color: tint(of: marker).opacity(Constants.subtitleOpacity))

            if isSelected {
                BrightText(marker.detail, size: .body4, color: .semiLightTextColor)
                    .transition(.opacity)
            }
        }
        .lineLimit(1)
    }

    // The milestone and the strain warning read differently depending on the load
    // that's been picked; every other marker says what the route gave it.
    private func title(of marker: WaypointMarker) -> String {
        marker.kind == .strain ? drawnCorrection.strainTitle : marker.title
    }

    private func subtitle(of marker: WaypointMarker) -> String {
        switch marker.kind {
        case .milestone: drawnCorrection.milestoneSubtitle
        case .strain: drawnCorrection.strainSubtitle
        case .checkpoint, .goal: marker.subtitle
        }
    }

    private func tint(of marker: WaypointMarker) -> Color {
        marker.kind == .strain ? drawnCorrection.strainColor : marker.tint
    }

    // Clear room over a dot drawn on the map, so the dot itself takes the tap.
    private var hitBox: some View {
        Color.clear
            .frame(width: Constants.hitSize, height: Constants.hitSize)
    }

    // The goal sits past the top of the map most of the time, so its flag stops at
    // the edge and points the way instead of leaving.
    private func position(of marker: WaypointMarker, _ projection: WaypointProjection, in size: CGSize) -> CGPoint {
        let point = ground(marker.position, projection)
        guard marker.kind == .goal else { return point }
        return CGPoint(
            x: min(max(point.x, Constants.goalInset), size.width - Constants.goalInset),
            y: min(max(point.y, Constants.goalTop), size.height - Constants.goalInset)
        )
    }

    private enum Constants {
        // How far up from the bottom edge the user's position is pinned.
        static let anchorInset: CGFloat = 75
        static let hitSize: CGFloat = 26

        static let contourWidth: CGFloat = 1
        static let contourFlat: Double = .minimalOpacity
        static let contourLow: Double = .ultraLowOpacity
        static let contourHigh: Double = .veryLowOpacity

        // How much of its usual strength a contour keeps on a slope turned away from
        // the sun, side on to it, and turned towards it.
        static let sunlight: [Double] = [0.45, 1, 2]

        // Degrees either side of the heading that the land is drawn across, and the
        // distances its skylines are drawn at: each one further out than the last by
        // the same factor, so they bunch up towards the horizon the way real ones do.
        static let landSpan: Double = 110
        static let landStep: Double = 2
        static let landRings = 11
        static let landNear: Double = 540
        static let landGrowth: Double = 1.3
        static let ridgeOpacity: Double = .lowOpacity
        static let hazeDepth: CGFloat = 70
        static let groundLight: Double = .minimalOpacity

        static let edgeFade: Double = 4
        // How far behind the camera's focus a tuft can be and still be worth drawing,
        // and how close to the eye one can come before it's skipped.
        static let cloudsBehind: Double = -500
        static let nearestCloud: Double = 220
        // How much of its strength a tuft has lost to the haze by the horizon.
        static let hazeShare: Double = 0.7
        // The paler cap on a tuft: how far towards the sun it sits, as a share of the
        // tuft's width, how far above the underside, and how big it is beside it.
        static let capShift: Double = 0.3
        static let capRise: Double = 0.35
        // Keeps one tuft's caps from repeating the next one's.
        static let capSeeds = 16
        static let capScatter: Double = 0.55
        // How much narrower and smaller the top cap is than the bottom one.
        static let capTaper: Double = 0.45
        static let capSize: Double = 0.55
        static let capVariety: Double = 0.3
        static let capOpacity: Double = .veryHighOpacity
        // Crisper than the underside, so the lumps of a heap read as lumps.
        static let capCore: Double = 0.6
        static let cloudRoundness: CGFloat = 0.62
        static let smallestPuff: CGFloat = 1.5
        // The least a puff flattens to, seen edge on.
        static let thinnestPuff: CGFloat = 0.22

        static let shadowRange: Double = 620
        static let shadowSteps = 14
        static let shadowBlur: CGFloat = 10

        static let fogRadius: Double = 75
        static let fogOpacity: Double = .semiLowOpacity
        static let fogPace: Double = 0.15
        static let fogSway: Double = 14

        // How far the rain reaches either side of the user, and the height it falls
        // from, in terrain heights.
        static let rainReach: Double = 340
        static let rainCeiling: Double = 5
        static let rainWidth: CGFloat = 1
        // A drop counts as near once it's drawn at about life size or larger.
        static let nearRain: Double = 1
        static let nearRainLength: Double = 1.3
        static let nearRainWidth: CGFloat = 0.3
        static let farRainOpacity: Double = 0.45
        // The share of a drop's turn spent falling, when the rest is its splash.
        static let fallShare: Double = 0.7
        static let splashSize: Double = 7
        static let splashSteps = 10
        static let splashFadeAt: Double = 0.5
        static let fadingRingOpacity: Double = .veryLowOpacity

        static let flickerStart: Double = 0.08
        static let flickerEnd: Double = 0.15
        // How far ahead a tuft has to be for a bolt from it to be in view.
        static let strikeRange: ClosedRange<Double> = 500 ... 2600
        // How far in from either side of the screen a striking cloud has to be.
        static let strikeMargin: CGFloat = 0.15
        // How far from under its cloud a bolt can land.
        static let strikeDrift: Double = 120
        static let boltSteps = 14
        static let boltJitter: Double = 40
        // The steps down the bolt that a branch splits off at, how many steps long a
        // branch is, how far it reaches sideways each step, and how much of the
        // bolt's own fall it keeps.
        static let branchSteps: Set<Int> = [4, 7, 10]
        static let branchLength = 4
        static let branchSpread: Double = 16
        static let branchFall: Double = 0.55
        static let trunkWidth: CGFloat = 3
        static let tipWidth: CGFloat = 1.8
        static let branchWidth: CGFloat = 1
        static let boltGlowWidth: CGFloat = 8
        static let skyFlash: Double = .finalBossLowOpacity
        static let cloudFlash: Double = .mediumOpacity
        static let cloudFlashSize: CGFloat = 3
        static let groundFlash: Double = .veryLowOpacity
        static let groundFlashSize: CGFloat = 130
        static let groundFlashDepth: CGFloat = 0.45

        static let radarReach: Double = 138
        static let radarHalfAngle: Double = .pi / 3
        static let radarSteps = 24
        static let radarNear: Double = .minimalOpacity
        static let radarFar: Double = .finalBossUltraLowOpacity
        static let pingPeriod: Double = 2.6
        static let pingOpacity: Double = .lowOpacity
        static let pingWidth: CGFloat = 1.5

        static let routeWidth: CGFloat = 4
        static let glowBlur: CGFloat = 4
        static let plannedOpacity: Double = .minimalOpacity
        static let driftGreenEnds: CGFloat = 0.22
        static let driftYellowStarts: CGFloat = 0.41
        static let trailWash = [
            WaypointWashStop(location: 0, opacity: .opaque),
            WaypointWashStop(location: 1, opacity: .zero),
        ]
        static let aheadWash = [
            WaypointWashStop(location: 0, opacity: .veryLowOpacity),
            WaypointWashStop(location: 0.5, opacity: .veryLowOpacity),
            WaypointWashStop(location: 1, opacity: .zero),
        ]
        static let correctionWash = [
            WaypointWashStop(location: 0, opacity: .finalBossUltraLowOpacity),
            WaypointWashStop(location: 0.45, opacity: .opaque),
            WaypointWashStop(location: 0.85, opacity: .finalBossUltraLowOpacity),
        ]

        static let leaderWidth: CGFloat = 31
        static let leaderElbow: CGFloat = 14
        static let leaderRise: CGFloat = 21
        static let leaderRadius: CGFloat = 8
        static let leaderGap: CGFloat = 2
        static let leaderLineWidth: CGFloat = 0.5
        static let leaderOpacity: Double = .lowOpacity

        static let dotRadius: CGFloat = 6
        static let originRing: CGFloat = 10
        static let originGlowBlur: CGFloat = 2
        static let checkpointRadius: CGFloat = 3
        static let checkpointOpacity: Double = .lowOpacity
        static let pulsePeriod: Double = 1.4
        static let pulseStart: CGFloat = 8
        static let pulseGrowth: CGFloat = 16
        static let pulseWidth: CGFloat = 1.5
        static let pulseOpacity: Double = .mediumOpacity

        static let subtitleOpacity: Double = .lowOpacity
        static let fullOpacity: Double = .opaque
        static let dimmedOpacity: Double = .semiLowOpacity

        static let horizonHeight: CGFloat = 65
        static let horizonSolid: CGFloat = 0.29

        static let goalInset: CGFloat = 60
        static let goalTop: CGFloat = 26

        // Shares of the intro: the routes behind the user draw first, then the way
        // ahead, then the labels fade in over the end of it.
        static let routesDrawn: Double = 0.55
        static let correctionStarts: Double = 0.4
        static let labelsAppear: Double = 0.7
    }
}

// One tuft of cloud: where it is, how big, how far ahead of the camera, and how much
// of its strength the haze and the edge of the field have left it.
private struct WaypointTuft {
    let index: Int
    let x: Double
    let y: Double
    let height: Double
    let radius: Double
    let ahead: Double
    let opacity: Double
    let caps: Int
    let tower: Double
}

private struct WaypointStrike {
    let seed: Int
    let tuft: WaypointTuft
    let groundX: Double
    let groundY: Double
    let brightness: Double
}

private struct WaypointProjectedTrack {
    let path: Path
    let start: CGPoint
    let end: CGPoint
}

private struct WaypointWashStop {
    let location: Double
    let opacity: Double
}

// Hangs a label off a point on the map by one of its edges rather than its centre,
// so its length never moves the end that touches the marker.
private struct WaypointPin: ViewModifier {
    let alignment: Alignment
    let offset: CGSize

    func body(content: Content) -> some View {
        content
            .fixedSize()
            .frame(width: .zero, height: .zero, alignment: alignment)
            .offset(offset)
    }
}

private extension WaypointMarker {
    var tint: Color {
        switch kind {
        case .milestone: .defaultCyan
        case .checkpoint, .goal: .defaultGreen
        case .strain: .defaultYellow
        }
    }
}

private extension WaypointMarker.Kind {
    var pinAlignment: Alignment {
        switch self {
        case .milestone, .checkpoint: .leading
        case .strain: .trailing
        case .goal: .top
        }
    }

    // Slides the label so the part that marks the spot — the dot's hit box, the
    // warning triangle, the flag — lands centred on it.
    var pinOffset: CGSize {
        switch self {
        case .milestone, .checkpoint: CGSize(width: -Constants.half, height: 0)
        case .strain: CGSize(width: Constants.half, height: 0)
        case .goal: CGSize(width: 0, height: -Constants.half)
        }
    }

    private enum Constants {
        static let half: CGFloat = 13
    }
}

// MARK: - Gesture

// A drag that the scroll views around the map wait for, and so never get: the map
// moves under the finger instead of the page scrolling or changing.
private struct WaypointPan: UIGestureRecognizerRepresentable {
    var handle: (UIPanGestureRecognizer) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        handle(recognizer)
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            otherGestureRecognizer.view is UIScrollView
        }
    }
}

#Preview {
    @Previewable @State var correction = WaypointCorrection.decrease
    @Previewable @State var rain = WaypointRainStyle.heavyDrops
    @Previewable @State var floating = WaypointFloatingClouds.heaps

    ScrollView {
        WaypointMap(correction: $correction, rain: $rain, floating: $floating)
    }
    .background(Color.defaultBackground)
}
