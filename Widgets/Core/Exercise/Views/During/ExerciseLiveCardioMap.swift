//
//  ExerciseLiveCardioMap.swift
//  Widgets
//
//  Created by Dom Montalto on 27/8/2026.
//

import CoreLocation
import MapboxMaps
import SwiftUI

// The page that sits right of the live cardio stats: the run drawn as it's
// covered, in the same sky blue as the screen's beam.
struct ExerciseLiveCardioMap: View {
    var route: [CLLocationCoordinate2D] = ExerciseDemoData.liveCardioRoute
    // How far along the run the marker sits, as a fraction of the route.
    var progress: Double = 1
    var is3D = false
    var recentreTick = 0

    @Environment(\.colorScheme) private var colorScheme

    @State private var viewport: Viewport = .idle

    var body: some View {
        MapboxMaps.Map(viewport: $viewport) {
            Puck2D(bearing: .heading)

            if route.count >= 2 {
                PolylineAnnotation(lineCoordinates: route)
                    .lineColor(StyleColor(UIColor(Color.defaultSkyBlueCyan)))
                    .lineWidth(Constants.routeLineWidth)
                    .lineJoin(.round)
                    // Standard's lighting dims unlit layers, which reads as a
                    // washed-out line.
                    .lineEmissiveStrength(Constants.routeEmissiveStrength)
            }

            if let current = coordinate(atFraction: progress) {
                MapViewAnnotation(coordinate: current) {
                    runnerMarker
                }
                .allowOverlap(true)
            }
        }
        .mapStyle(.standard(lightPreset: colorScheme == .dark ? .night : .day))
        // No compass or scale bar. The logo and attribution have to stay.
        .ornamentOptions(OrnamentOptions(
            scaleBar: ScaleBarViewOptions(visibility: .hidden),
            compass: CompassViewOptions(visibility: .hidden)
        ))
        .ignoresSafeArea()
        .onAppear { frameRoute() }
        .onChange(of: is3D) { _, _ in frameRoute() }
        .onChange(of: recentreTick) { _, _ in followPuck() }
    }

    private var runnerMarker: some View {
        Image(systemName: "figure.run")
            .font(.system(size: Constants.markerGlyphSize, weight: .medium))
            .foregroundStyle(Color.defaultBlack)
            .frame(width: Constants.markerSize, height: Constants.markerSize)
            .background(Color.defaultSkyBlueCyan, in: Circle())
            .shadow(color: .black.opacity(.veryLowOpacity), radius: 4, y: 2)
    }

    private func coordinate(atFraction fraction: Double) -> CLLocationCoordinate2D? {
        guard !route.isEmpty else { return nil }
        let index = Int((Double(route.count - 1) * min(max(fraction, 0), 1)).rounded())
        return route[index]
    }

    private func followPuck() {
        withViewportAnimation(.easeOut(duration: Constants.cameraAnimation)) {
            viewport = .followPuck(
                zoom: Constants.followZoom,
                bearing: .heading,
                pitch: is3D ? Constants.pitch3D : 0
            )
        }
    }

    private func frameRoute() {
        guard route.count >= 2 else {
            followPuck()
            return
        }
        withViewportAnimation(.easeOut(duration: Constants.cameraAnimation)) {
            viewport = .overview(
                geometry: LineString(route),
                pitch: is3D ? Constants.pitch3D : 0,
                geometryPadding: EdgeInsets(
                    top: Constants.overviewPadding,
                    leading: Constants.overviewPadding,
                    bottom: Constants.overviewPadding,
                    trailing: Constants.overviewPadding
                )
            )
        }
    }

    private enum Constants {
        static let routeLineWidth: Double = 5
        static let routeEmissiveStrength: Double = 1
        static let markerSize: CGFloat = .spacing6x
        static let markerGlyphSize: CGFloat = 17
        static let followZoom: CGFloat = 15
        static let pitch3D: CGFloat = 65
        static let cameraAnimation: TimeInterval = 0.6
        static let overviewPadding: CGFloat = .spacing8x
    }
}

#Preview {
    ExerciseLiveCardioMap()
}
