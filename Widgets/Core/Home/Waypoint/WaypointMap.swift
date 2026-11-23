//
//  WaypointMap.swift
//  Widgets
//
//  Created by Dom Montalto on 24/11/2026.
//

import SwiftUI

// The waypoint bar and the terrain under it. Dragging sideways on either turns the
// map, pinching zooms, and the two buttons tilt it into 3D and bring north back up.
struct WaypointMap: View {
    var route = WaypointRoute.demo
    @Binding var correction: WaypointCorrection

    @State private var camera = WaypointCamera.intro
    @State private var is3D = true
    @State private var selection: WaypointMarker.ID?
    // Trails `correction` by the time it takes the old line to pull back.
    @State private var drawnCorrection = WaypointCorrection.decrease
    @State private var correctionDrawn = 1.0
    @State private var isVisible = false
    @State private var hasPlayedIntro = false
    @State private var dragStartHeading: Double?
    @State private var pinchStartZoom: Double?

    var body: some View {
        VStack(spacing: .spacing0x) {
            WaypointCompassStrip(
                heading: camera.heading,
                load: drawnCorrection.barLoad,
                loadColor: drawnCorrection.color,
                zoneColor: drawnCorrection.strainColor
            )
            .padding(.bottom, .spacing2x)

            WaypointMapScene(
                camera: camera,
                route: route,
                selection: selection,
                correction: correction,
                drawnCorrection: drawnCorrection,
                correctionDrawn: correctionDrawn,
                isPaused: !isVisible,
                onSelect: select,
                onCorrect: { correction = $0 }
            )
            .frame(height: Constants.height)
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture { select(nil) }
            .overlay(alignment: .bottomTrailing) { controls }

            BrightDividerV5(opacity: Constants.dividerOpacity)
        }
        .contentShape(Rectangle())
        .gesture(WaypointOrbitPan(handle: orbit))
        .simultaneousGesture(pinch)
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
                imageColor: isTurned ? Color.defaultCyan : nil,
                onTapCallback: recentre
            )
        }
        .padding(.trailing, .spacing3x)
        .padding(.bottom, .spacing4x)
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
        Int((camera.heading / WaypointCompassStrip.degreesPerTick).rounded(.down))
    }

    private var isTurned: Bool {
        abs(camera.heading.remainder(dividingBy: 360)) > Constants.turnedTolerance
    }

    private var restingZoom: Double {
        is3D ? WaypointCamera.raised.zoom : WaypointCamera.flat.zoom
    }

    private func orbit(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            dragStartHeading = camera.heading
        case .changed:
            guard let dragStartHeading else { return }
            let dragged = Double(pan.translation(in: pan.view).x)
            camera.heading = dragStartHeading - dragged / Constants.pointsPerDegree
        case .ended, .cancelled:
            let thrown = Double(pan.velocity(in: pan.view).x) * Constants.throwTime
            withAnimation(Constants.glide) {
                camera.heading -= thrown / Constants.pointsPerDegree
            }
            dragStartHeading = nil
        default:
            break
        }
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
        }
        select(nil)
    }

    private func select(_ marker: WaypointMarker?) {
        withAnimation(.brightEaseInOut) {
            selection = marker?.id == selection ? nil : marker?.id
        }
    }

    // Pulls the old line back to where it left the drift, then draws the new one out
    // while the labels and the waypoint bar move over to match.
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
        // How far a sideways drag has to travel to turn the map a degree.
        static let pointsPerDegree: Double = 2.4
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
                    Canvas { context, _ in
                        draw(&context, projection, time: timeline.date.timeIntervalSinceReferenceDate)
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
        drawBeacons(&context, projection)
        drawDots(&context, projection, time: time)
    }

    // Ranges of peaks standing round the edge of the map, furthest first so each one
    // hides the foot of the one behind. They only exist once the map is tilted: flat,
    // they'd be three rings on the ground.
    private func drawMountains(_ context: inout GraphicsContext, _ projection: WaypointProjection) {
        let raised = min(max(camera.lift, 0), 1)
        guard raised > 0 else { return }

        // Fixed bearings rather than ones measured from the camera, so the peaks
        // don't crawl as the map turns.
        let first = Int(((camera.heading - Constants.mountainSpan) / Constants.mountainStep).rounded(.down))
        let last = Int(((camera.heading + Constants.mountainSpan) / Constants.mountainStep).rounded(.up))
        let foot = -terrain.originHeight

        for ring in (0 ..< Constants.mountainRings).reversed() {
            let radius = Constants.mountainNear + Double(ring) * Constants.mountainGap
            let tallest = Constants.mountainHeight + Double(ring) * Constants.mountainRise
            var bands = Constants.mountainBands.map { _ in [CGPoint]() }
            var base: [CGPoint] = []

            for index in first ... last {
                let bearing = Double(index) * Constants.mountainStep * .pi / 180
                let x = sin(bearing) * radius
                let y = cos(bearing) * radius
                let height = WaypointTerrain.peak(bearing: bearing, ring: ring) * tallest
                base.append(projection.point(x, y, height: foot))
                for (band, share) in Constants.mountainBands.enumerated() {
                    bands[band].append(projection.point(x, y, height: foot + height * share))
                }
            }

            var face = Path()
            face.addLines(bands[0] + base.reversed())
            face.closeSubpath()
            context.fill(face, with: .color(Color.defaultBackground.opacity(raised)))

            let nearness = 1 - Double(ring) / Double(Constants.mountainRings)
            for (band, points) in bands.enumerated() {
                var line = Path()
                line.addLines(points)
                let opacity = (band == 0 ? Constants.ridgeOpacity : Constants.bandOpacity) * nearness * raised
                context.stroke(line, with: .color(Color.defaultCyan.opacity(opacity)), lineWidth: Constants.contourWidth)
            }
        }
    }

    // A beam of light standing on each milestone and on the goal, so they can be
    // picked out across the terrain.
    private func drawBeacons(_ context: inout GraphicsContext, _ projection: WaypointProjection) {
        let shown = stage(Constants.labelsAppear, 1) * min(max(camera.lift, 0), 1)
        guard shown > 0 else { return }

        for marker in route.markers {
            guard let rise = marker.kind.beaconRise else { continue }
            let base = ground(marker.position, projection)
            let top = ground(marker.position, projection, raisedBy: rise)
            var beam = Path()
            beam.move(to: base)
            beam.addLine(to: top)

            let shading = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [
                    marker.tint.opacity(Constants.beaconOpacity * shown * dimming(marker.id)),
                    marker.tint.opacity(.zero),
                ]),
                startPoint: base,
                endPoint: top
            )
            let style = StrokeStyle(lineWidth: Constants.beaconWidth, lineCap: .round)
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: Constants.glowBlur))
                layer.stroke(beam, with: shading, style: style)
            }
            context.stroke(beam, with: shading, style: style)
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

        let origin = projection.point(0, 0, height: 0)
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
                endPoint: projection.point(0, reach, height: 0)
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
        return projection.point(sin(angle) * reach, cos(angle) * reach, height: 0)
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

            // Dashes running along the suggested line, towards the milestone.
            let dashLength = Constants.flowDash.reduce(0, +)
            let travelled = (time * Constants.flowSpeed).truncatingRemainder(dividingBy: Double(dashLength))
            context.stroke(
                line.path,
                with: wash(.defaultWhite, Constants.correctionWash, along: line),
                style: StrokeStyle(
                    lineWidth: Constants.flowWidth,
                    lineCap: .round,
                    dash: Constants.flowDash,
                    dashPhase: -CGFloat(travelled)
                )
            )
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

        let origin = projection.point(0, 0, height: 0)
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

    private func ground(_ point: CGPoint, _ projection: WaypointProjection, raisedBy rise: Double = 0) -> CGPoint {
        let x = Double(point.x)
        let y = Double(point.y)
        return projection.point(x, y, height: WaypointTerrain.height(x: x, y: y) - terrain.originHeight + rise)
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
        // The flag flies from the top of the goal's beacon once the map is tilted.
        let point = ground(marker.position, projection, raisedBy: marker.kind == .goal ? marker.kind.beaconRise ?? 0 : 0)
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
        static let contourHigh: Double = .semiLowOpacity

        // Degrees either side of the heading that the ranges are drawn across.
        static let mountainSpan: Double = 110
        static let mountainStep: Double = 2
        // Kept as low as the hills inside them, and stepped well back, so they fill
        // the distance by receding rather than by towering.
        static let mountainRings = 5
        static let mountainNear: Double = 540
        static let mountainGap: Double = 90
        // In terrain heights, where the contours top out at 1.
        static let mountainHeight: Double = 0.9
        static let mountainRise: Double = 0.1
        // The ridge line, then the lines drawn part-way down each face.
        static let mountainBands: [Double] = [1, 0.66, 0.33]
        static let ridgeOpacity: Double = .lowOpacity
        static let bandOpacity: Double = .minimalOpacity

        static let beaconWidth: CGFloat = 2
        static let beaconOpacity: Double = .mediumOpacity

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
        static let flowWidth: CGFloat = 2
        static let flowDash: [CGFloat] = [2, 14]
        static let flowSpeed: Double = 22

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

    // How high a beam of light stands on the marker, in terrain heights.
    var beaconRise: Double? {
        switch self {
        case .milestone: 1
        case .goal: 1.6
        case .checkpoint, .strain: nil
        }
    }

    private enum Constants {
        static let half: CGFloat = 13
    }
}

// MARK: - Gesture

// Takes sideways drags only, so the page still scrolls when the drag is vertical,
// and makes the pager wait until this has had its chance at a horizontal one.
private struct WaypointOrbitPan: UIGestureRecognizerRepresentable {
    var handle: (UIPanGestureRecognizer) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        pan.maximumNumberOfTouches = 1
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        handle(recognizer)
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

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

    ScrollView {
        WaypointMap(correction: $correction)
    }
    .background(Color.defaultBackground)
}
