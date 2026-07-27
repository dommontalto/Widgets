//
//  HeartWorkoutMapSheetView.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import MapKit
import SwiftUI

struct HeartWorkoutMapSheetView: View {
    let routePoints: [HeartWorkoutOverviewWidget.RoutePoint]
    let routeSegments: [HeartWorkoutOverviewWidget.RouteSegment]
    let region: MKCoordinateRegion
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    let duration: TimeDuration?
    let hrAvg: Double
    let avgPace: Int
    let altitudeGain: Amount
    let graphData: HeartWorkoutCombinedGraphData

    @State private var cameraPosition: MapCameraPosition
    @State private var selectedSecond: Double?
    @State private var selectedMetric: HeartWorkoutGraphMetric = .heartRate
    @State private var chaseHeading: Double?
    @State private var lastFraction: Double = 0
    @State private var followStart: Date?

    init(
        routePoints: [HeartWorkoutOverviewWidget.RoutePoint],
        routeSegments: [HeartWorkoutOverviewWidget.RouteSegment],
        region: MKCoordinateRegion,
        startCoordinate: CLLocationCoordinate2D?,
        endCoordinate: CLLocationCoordinate2D?,
        duration: TimeDuration?,
        hrAvg: Double,
        avgPace: Int,
        altitudeGain: Amount,
        graphData: HeartWorkoutCombinedGraphData
    ) {
        self.routePoints = routePoints
        self.routeSegments = routeSegments
        self.region = region
        self.startCoordinate = startCoordinate
        self.endCoordinate = endCoordinate
        self.duration = duration
        self.hrAvg = hrAvg
        self.avgPace = avgPace
        self.altitudeGain = altitudeGain
        self.graphData = graphData

        _cameraPosition = State(initialValue: .region(region))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            map
                .ignoresSafeArea()

            breakdown
                .padding(.horizontal, .spacing2x)
                .padding(.bottom, .spacing5x)
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: selectedSecond) { _, _ in
            updateCamera()
        }
    }

    private var breakdown: some View {
        HeartWorkoutPerformanceGraphWidget(
            hrAvg: hrAvg,
            duration: duration ?? TimeDuration(),
            avgPace: avgPace,
            altitudeGain: altitudeGain,
            data: graphData,
            selectedSecond: $selectedSecond,
            selectedMetric: $selectedMetric
        )
    }

    private var map: some View {
        Map(position: $cameraPosition) {
            ForEach(routeSegments.indices, id: \.self) { index in
                let segment = routeSegments[index]
                MapPolyline(segment.polyline)
                    .stroke(segment.style, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }

            if let end = endCoordinate {
                Annotation("", coordinate: end) {
                    routeMarker(color: .defaultWarningRed, size: Constants.markerSize)
                }
            }

            if let start = startCoordinate {
                Annotation("", coordinate: start) {
                    routeMarker(color: .defaultGreen, size: Constants.markerSize)
                }
            }

            if let selected = selectedCoordinate {
                Annotation("", coordinate: selected) {
                    routeMarker(color: .defaultBlue, size: Constants.selectedMarkerSize)
                        .shadow(color: .black.opacity(.mediumOpacity), radius: 4, y: 2)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {}
    }

    private func routeMarker(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }

    // MARK: - Camera

    private var selectedFraction: Double? {
        let total = max((duration ?? TimeDuration()).totalSeconds, 1)
        return selectedSecond.map { max(0, min(1, $0 / total)) }
    }

    private var selectedCoordinate: CLLocationCoordinate2D? {
        selectedFraction.flatMap { coordinate(atFraction: $0) }
    }

    private func coordinate(atFraction fraction: Double) -> CLLocationCoordinate2D? {
        guard routePoints.count >= 2 else { return nil }

        let position = fraction * Double(routePoints.count - 1)
        let lowerIndex = max(0, min(routePoints.count - 1, Int(floor(position))))
        let upperIndex = max(0, min(routePoints.count - 1, Int(ceil(position))))
        let t = position - Double(lowerIndex)

        let a = routePoints[lowerIndex].coordinate
        let b = routePoints[upperIndex].coordinate

        return CLLocationCoordinate2D(
            latitude: a.latitude + (b.latitude - a.latitude) * t,
            longitude: a.longitude + (b.longitude - a.longitude) * t
        )
    }

    private func updateCamera() {
        guard let fraction = selectedFraction, let current = coordinate(atFraction: fraction) else {
            chaseHeading = nil
            followStart = nil
            withAnimation(.easeOut(duration: Constants.entranceDuration)) {
                cameraPosition = .region(region)
            }
            return
        }

        let ahead = coordinate(atFraction: min(1, fraction + Constants.lookAheadFraction)) ?? current
        let targetHeading = bearing(from: current, to: ahead)

        let isJump = abs(fraction - lastFraction) > Constants.jumpThreshold
        lastFraction = fraction

        let now = Date()
        if followStart == nil {
            followStart = now
        }
        let isEntering = now.timeIntervalSince(followStart ?? now) < Constants.entranceDuration

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
            centerCoordinate: ahead,
            distance: Constants.followDistance,
            heading: heading,
            pitch: Constants.followPitch
        )

        if isEntering || isJump {
            withAnimation(.easeOut(duration: Constants.entranceDuration)) {
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

    private enum Constants {
        static let markerSize: CGFloat = 18
        static let selectedMarkerSize: CGFloat = 22
        static let followDistance: CLLocationDistance = 500
        static let followPitch: CGFloat = 65
        static let lookAheadFraction: Double = 0.02
        static let headingResponsiveness: Double = 0.3
        static let entranceDuration: TimeInterval = 0.5
        static let jumpThreshold: Double = 0.1
    }
}
