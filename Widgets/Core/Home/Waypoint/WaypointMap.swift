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
            WaypointMap(route: route, correction: $correction, rain: $rain, fillsScreen: true)
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
        is3D ? WaypointCamera.raised.zoom : WaypointCamera.flat.zoom
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
        let target = is3D ? WaypointCamera.raised : WaypointCamera.flat
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

    private func playIntro() {
        guard !hasPlayedIntro else { return }
        hasPlayedIntro = true
        withAnimation(Constants.intro) {
            camera = .raised
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

                    Canvas { context, _ in
                        draw(&context, projection, time: time)
                    }
                }

                horizon

                user(projection)

                labels(projection, in: size)
            }
        }
    }

    // MARK: Drawing

    private func draw(_ context: inout GraphicsContext, _ projection: WaypointProjection, time: TimeInterval) {
        drawMountains(&context, projection)
        drawTerrain(&context, projection)
        drawRadar(&context, projection, time: time)
        drawRoutes(&context, projection, time: time)
        drawDots(&context, projection, time: time)
        // The rain and the lightning come out of the clouds, so the clouds go over them.
        drawRain(&context, projection, time: time)
        drawLightning(&context, projection, time: time)
        drawClouds(&context, projection, time: time)
    }

    // Bolts come down from the cloud base every so often: jagged, forked half-way,
    // lighting the sky around their tops, and flickering twice before they fade. They
    // strike the ground of the map, so they stand in the terrain like everything else.
    private func drawLightning(_ context: inout GraphicsContext, _ projection: WaypointProjection, time: TimeInterval) {
        guard camera.reveal >= 1 else { return }

        let strike = Int((time / WaypointWeather.strikeEvery).rounded(.down))
        let age = time - Double(strike) * WaypointWeather.strikeEvery
        guard age < Constants.strikeLength, WaypointTerrain.scatter(strike, 14) < WaypointWeather.strikeChance else { return }

        let brightness: Double = if age < Constants.flickerStart {
            1
        } else if age < Constants.flickerEnd {
            0
        } else {
            1 - (age - Constants.flickerEnd) / (Constants.strikeLength - Constants.flickerEnd)
        }
        guard brightness > 0 else { return }

        for bolt in 0 ..< WaypointWeather.bolts {
            drawBolt(&context, projection, seed: strike * Constants.boltSeeds + bolt, time: time, brightness: brightness)
        }
    }

    // Where a cloud is right now, the height of its base, and how solid it is: clouds
    // thin out towards the edge of the sky they leave by and the one they come back
    // in at.
    private func cloudSpot(_ cloud: Int, time: TimeInterval) -> (x: Double, y: Double, base: Double, edge: Double) {
        let drifted = WaypointTerrain.scatter(cloud, 4) * Constants.skyReach * 2 + time * WaypointWeather.drift
        let x = drifted.truncatingRemainder(dividingBy: Constants.skyReach * 2) - Constants.skyReach
        let y = (WaypointTerrain.scatter(cloud, 5) * 2 - 1) * Constants.skyReach
        let base = WaypointClouds.base + WaypointTerrain.scatter(cloud, 6) * WaypointClouds.layerDepth
        let edge = min((1 - abs(x) / Constants.skyReach) * Constants.edgeFade, 1)
        return (x, y, base, edge)
    }

    // The cloud a bolt comes out of: one picked by the seed, or the next one along
    // that's fully there, so lightning never starts from a cloud that has faded out.
    private func strikingCloud(seed: Int, time: TimeInterval) -> (x: Double, y: Double, base: Double, edge: Double)? {
        let first = Int(WaypointTerrain.scatter(seed, 10) * Double(WaypointClouds.cloudCount))
        for offset in 0 ..< WaypointClouds.cloudCount {
            let spot = cloudSpot((first + offset) % WaypointClouds.cloudCount, time: time)
            if spot.edge >= 1 { return spot }
        }
        return nil
    }

    private func drawBolt(
        _ context: inout GraphicsContext,
        _ projection: WaypointProjection,
        seed: Int,
        time: TimeInterval,
        brightness: Double
    ) {
        guard let cloud = strikingCloud(seed: seed, time: time) else { return }
        // From somewhere under the cloud's base, straight down to the ground below it.
        let x = cloud.x + (WaypointTerrain.scatter(seed, 11) * 2 - 1) * WaypointClouds.baseSpread * Constants.strikeSpread
        let y = cloud.y
        let top = cloud.base
        let floor = WaypointTerrain.height(x: x, y: y) - terrain.originHeight
        let forkStart = Constants.boltSteps / 2
        // Forks to one side or the other.
        let forkSide: Double = WaypointTerrain.scatter(seed, 15) < 0.5 ? -1 : 1

        var bolt = Path()
        var fork = Path()
        for step in 0 ... Constants.boltSteps {
            let isEnd = step == 0 || step == Constants.boltSteps
            let stepSeed = seed * Constants.boltSteps * 2 + step
            let stepX = x + (isEnd ? 0 : (WaypointTerrain.scatter(stepSeed, 12) * 2 - 1) * Constants.boltJitter)
            let stepY = y + (isEnd ? 0 : (WaypointTerrain.scatter(stepSeed, 13) * 2 - 1) * Constants.boltJitter)
            let height = top + (floor - top) * Double(step) / Double(Constants.boltSteps)
            let point = projection.point(stepX, stepY, height: height)

            if step == 0 {
                bolt.move(to: point)
            } else {
                bolt.addLine(to: point)
            }

            if step == forkStart {
                fork.move(to: point)
            } else if step > forkStart, step <= forkStart + Constants.forkSteps {
                let spread = Double(step - forkStart) * Constants.forkSpread * forkSide
                fork.addLine(to: projection.point(stepX + spread, stepY, height: height))
            }
        }

        let crown = projection.point(x, y, height: top)
        context.fill(
            circle(at: crown, radius: Constants.flashRadius),
            with: .radialGradient(
                Gradient(colors: [
                    Color.defaultBlue.opacity(Constants.flashOpacity * brightness),
                    Color.defaultBlue.opacity(.zero),
                ]),
                center: crown,
                startRadius: 0,
                endRadius: Constants.flashRadius
            )
        )

        let glow = StrokeStyle(lineWidth: Constants.boltGlowWidth, lineCap: .round, lineJoin: .round)
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: Constants.glowBlur))
            layer.stroke(bolt, with: .color(Color.defaultBlue.opacity(brightness)), style: glow)
        }
        context.stroke(
            bolt,
            with: .color(Color.defaultCyan.opacity(brightness)),
            style: StrokeStyle(lineWidth: Constants.boltWidth, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            fork,
            with: .color(Color.defaultCyan.opacity(brightness)),
            style: StrokeStyle(lineWidth: Constants.forkWidth, lineCap: .round, lineJoin: .round)
        )
    }

    // Rain falling from the clouds to the ground it lands on, leaning with the wind.
    // A drop spends most of its turn falling; in the styles that splash, it spends the
    // rest as a ring spreading over the ground where it landed.
    private func drawRain(_ context: inout GraphicsContext, _ projection: WaypointProjection, time: TimeInterval) {
        let shown = stage(Constants.labelsAppear, 1)
        guard shown > 0 else { return }

        let fallShare = rain.hasSplashes ? Constants.fallShare : 1
        var streaks = Path()
        var freshRings = Path()
        var fadingRings = Path()

        for drop in 0 ..< rain.dropCount {
            var startX = (WaypointTerrain.scatter(drop, 1) * 2 - 1) * Constants.skyReach
            var y = (WaypointTerrain.scatter(drop, 2) * 2 - 1) * Constants.skyReach
            var top = WaypointClouds.base
            if rain.fallsFromClouds {
                let cloud = cloudSpot(drop % WaypointClouds.cloudCount, time: time)
                guard cloud.edge >= 1 else { continue }
                startX = cloud.x + (WaypointTerrain.scatter(drop, 1) * 2 - 1) * Constants.shaftWidth
                y = cloud.y + (WaypointTerrain.scatter(drop, 2) * 2 - 1) * Constants.shaftWidth
                top = cloud.base
            }

            let turn = (time / rain.fallTime + WaypointTerrain.scatter(drop, 3)).truncatingRemainder(dividingBy: 1)
            let fallen = min(turn / fallShare, 1)
            let x = startX + rain.lean * fallen
            let floor = WaypointTerrain.height(x: x, y: y) - terrain.originHeight

            if turn < fallShare {
                let height = floor + (top - floor) * (1 - fallen)
                let tail = rain.lean * rain.dropLength / top
                streaks.move(to: projection.point(x, y, height: height))
                streaks.addLine(to: projection.point(x - tail, y, height: height + rain.dropLength))
            } else {
                let grown = (turn - fallShare) / (1 - fallShare)
                let radius = Constants.splashSize * grown
                var ring = Path()
                for step in 0 ..< Constants.splashSteps {
                    let angle = Double(step) / Double(Constants.splashSteps) * 2 * .pi
                    let point = projection.point(x + cos(angle) * radius, y + sin(angle) * radius, height: floor)
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

        let color = Color.defaultCyan
        context.stroke(
            streaks,
            with: .color(color.opacity(rain.opacity * shown)),
            style: StrokeStyle(lineWidth: rain.dropWidth, lineCap: .round)
        )
        context.stroke(freshRings, with: .color(color.opacity(rain.opacity * shown)), lineWidth: Constants.rainWidth)
        context.stroke(fadingRings, with: .color(color.opacity(Constants.fadingRingOpacity * shown)), lineWidth: Constants.rainWidth)
    }

    // The clouds, each a clump of soft puffs drifting east. Where a puff sits between
    // its cloud's base and top decides how far out it can be, which is what makes a
    // heap narrow as it rises and a storm cloud spread into an anvil, and whether
    // it's the darker grey of the underside. The dark ones are drawn first, so the
    // lit tops sit over them. Flat, with nothing raised, the clouds lie on the map
    // as haze.
    private func drawClouds(_ context: inout GraphicsContext, _ projection: WaypointProjection, time: TimeInterval) {
        let shown = stage(Constants.labelsAppear, 1)
        guard shown > 0 else { return }

        for isDark in [true, false] {
            let tone: Color = isDark ? .waypointCloudShade : .waypointCloud

            for cloud in 0 ..< WaypointClouds.cloudCount {
                let spot = cloudSpot(cloud, time: time)
                let x = spot.x
                let y = spot.y
                let base = spot.base
                let opacity = WaypointClouds.opacity * spot.edge * shown

                for puff in 0 ..< WaypointClouds.puffsPerCloud {
                    let seed = cloud * WaypointClouds.puffsPerCloud + puff
                    let rise = WaypointTerrain.scatter(seed, 17)
                    guard (rise < WaypointClouds.darkShare) == isDark else { continue }

                    let spread = WaypointClouds.baseSpread + (WaypointClouds.topSpread - WaypointClouds.baseSpread) * rise
                    let puffX = x + (WaypointTerrain.scatter(seed, 7) * 2 - 1) * spread
                    let puffY = y + (WaypointTerrain.scatter(seed, 8) * 2 - 1) * spread * WaypointClouds.depthShare
                    let height = base + rise * WaypointClouds.tower
                    let centre = projection.point(puffX, puffY, height: height)
                    let radius = WaypointClouds.puffRadius * (1 + WaypointTerrain.scatter(seed, 9) * Constants.puffVariety)
                        * projection.scale(puffX, puffY, height: height)
                    context.fill(
                        circle(at: centre, radius: CGFloat(radius)),
                        with: .radialGradient(
                            Gradient(colors: [tone.opacity(opacity), tone.opacity(.zero)]),
                            center: centre,
                            startRadius: CGFloat(radius * WaypointClouds.core),
                            endRadius: CGFloat(radius)
                        )
                    )
                }
            }
        }
    }

    // The land carrying on past the last contour, drawn as its skyline at a few
    // distances, furthest first so each one hides the foot of the one behind. The
    // heights come from the same terrain as the contours and the routes. Flat, they'd
    // be rings on the ground, so they only show once the map is tilted.
    private func drawMountains(_ context: inout GraphicsContext, _ projection: WaypointProjection) {
        let raised = min(max(camera.lift, 0), 1)
        guard raised > 0 else { return }

        // Fixed bearings rather than ones measured from the camera, so the skyline
        // doesn't crawl as the map turns.
        let first = Int(((camera.heading - Constants.mountainSpan) / Constants.mountainStep).rounded(.down))
        let last = Int(((camera.heading + Constants.mountainSpan) / Constants.mountainStep).rounded(.up))

        for ring in (0 ..< Constants.mountainRings).reversed() {
            let radius = Constants.mountainNear + Double(ring) * Constants.mountainGap
            var ridge: [CGPoint] = []
            var foot: [CGPoint] = []

            for index in first ... last {
                let bearing = Double(index) * Constants.mountainStep * .pi / 180
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
            let nearness = 1 - Double(ring) / Double(Constants.mountainRings)
            context.stroke(
                skyline,
                with: .color(Color.defaultCyan.opacity(Constants.ridgeOpacity * nearness * raised)),
                lineWidth: Constants.contourWidth
            )
        }
    }

    private func drawTerrain(_ context: inout GraphicsContext, _ projection: WaypointProjection) {
        let topLevel = Double(max(terrain.levels.count - 1, 1))

        for (index, level) in terrain.levels.enumerated() {
            let height = level.height - terrain.originHeight
            let segments = level.segments
            var path = Path()
            var cursor = 0
            while cursor < segments.count {
                path.move(to: projection.point(segments[cursor], segments[cursor + 1], height: height))
                path.addLine(to: projection.point(segments[cursor + 2], segments[cursor + 3], height: height))
                cursor += 4
            }

            // Flat, every line reads the same; raised, the peaks catch more light.
            let raised = Constants.contourLow + (Constants.contourHigh - Constants.contourLow) * Double(index) / topLevel
            let opacity = Constants.contourFlat + (raised - Constants.contourFlat) * camera.lift
            context.stroke(path, with: .color(Color.defaultCyan.opacity(opacity)), lineWidth: Constants.contourWidth)
        }
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

        // Degrees either side of the heading that the ranges are drawn across.
        static let mountainSpan: Double = 110
        static let mountainStep: Double = 2
        static let mountainRings = 4
        static let mountainNear: Double = 540
        static let mountainGap: Double = 90
        static let ridgeOpacity: Double = .lowOpacity

        // How far the sky reaches either side of the user.
        static let skyReach: Double = 320
        static let edgeFade: Double = 4
        // How much bigger than the smallest a cloud's largest puffs are.
        static let puffVariety: Double = 0.8
        static let rainWidth: CGFloat = 1
        // The share of a drop's turn spent falling, when the rest is its splash.
        static let fallShare: Double = 0.7
        static let splashSize: Double = 11
        static let splashSteps = 10
        static let splashFadeAt: Double = 0.5
        static let fadingRingOpacity: Double = .veryLowOpacity
        // How far either side of its cloud's middle a shaft of rain reaches.
        static let shaftWidth: Double = 12

        static let strikeLength: Double = 0.5
        // Keeps the bolts of one strike, and of the next, from landing in the same place.
        static let boltSeeds = 7
        static let flickerStart: Double = 0.08
        static let flickerEnd: Double = 0.15
        // How far out from the middle of its cloud, as a share of the cloud's width, a
        // bolt can start.
        static let strikeSpread: Double = 0.5
        static let boltSteps = 9
        static let boltJitter: Double = 13
        static let forkSteps = 3
        static let forkSpread: Double = 10
        static let boltWidth: CGFloat = 2
        static let forkWidth: CGFloat = 1
        static let boltGlowWidth: CGFloat = 6
        static let flashRadius: CGFloat = 190
        static let flashOpacity: Double = .veryLowOpacity

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

    ScrollView {
        WaypointMap(correction: $correction, rain: $rain)
    }
    .background(Color.defaultBackground)
}
