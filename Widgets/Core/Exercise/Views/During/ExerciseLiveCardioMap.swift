//
//  ExerciseLiveCardioMap.swift
//  Widgets
//
//  Created by Dom Montalto on 27/8/2026.
//

import CoreLocation
import MapboxMaps
import SwiftUI

struct ExerciseLiveCardioMap: View {
    var plannedRoute: [CLLocationCoordinate2D] = []
    var trackedRoute: [CLLocationCoordinate2D] = []
    var is3D = false
    var recentreTick = 0

    @Environment(\.colorScheme) private var colorScheme

    @State private var viewport: Viewport = .idle

    var body: some View {
        MapboxMaps.Map(viewport: $viewport) {
            Puck2D(bearing: .heading)

            if plannedRoute.count >= 2 {
                PolylineAnnotation(lineCoordinates: plannedRoute)
                    .lineColor(StyleColor(UIColor(Color.defaultSkyBlueCyan.opacity(.lowOpacity))))
                    .lineWidth(Constants.routeLineWidth)
                    .lineJoin(.round)
                    .lineEmissiveStrength(Constants.routeEmissiveStrength)
            }

            if trackedRoute.count >= 2 {
                PolylineAnnotation(lineCoordinates: trackedRoute)
                    .lineColor(StyleColor(UIColor(Color.defaultSkyBlueCyan)))
                    .lineWidth(Constants.routeLineWidth)
                    .lineJoin(.round)
                    .lineEmissiveStrength(Constants.routeEmissiveStrength)
            }

            if let finish = plannedRoute.last, plannedRoute.count >= 2 {
                MapViewAnnotation(coordinate: finish) {
                    finishMarker
                }
                .allowOverlap(true)
            }
        }
        .mapStyle(.standard(lightPreset: colorScheme == .dark ? .night : .day))
        .ornamentOptions(OrnamentOptions(
            scaleBar: ScaleBarViewOptions(visibility: .hidden),
            compass: CompassViewOptions(visibility: .hidden)
        ))
        .ignoresSafeArea()
        .onAppear { frameRoute() }
        .onChange(of: plannedRoute.count) { _, _ in frameRoute() }
        .onChange(of: is3D) { _, _ in frameRoute() }
        .onChange(of: recentreTick) { _, _ in followPuck() }
    }

    private var finishMarker: some View {
        Image(systemName: "flag.pattern.checkered")
            .font(.system(size: Constants.markerGlyphSize, weight: .medium))
            .foregroundStyle(Color.defaultBlack)
            .frame(width: Constants.markerSize, height: Constants.markerSize)
            .background(Color.defaultSkyBlueCyan, in: Circle())
            .shadow(color: .black.opacity(.veryLowOpacity), radius: 4, y: 2)
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
        guard plannedRoute.count >= 2 else {
            followPuck()
            return
        }
        withViewportAnimation(.easeOut(duration: Constants.cameraAnimation)) {
            viewport = .overview(
                geometry: LineString(plannedRoute),
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
        static let markerSize: CGFloat = .spacing5x
        static let markerGlyphSize: CGFloat = 13
        static let followZoom: CGFloat = 15
        static let pitch3D: CGFloat = 65
        static let cameraAnimation: TimeInterval = 0.6
        static let overviewPadding: CGFloat = .spacing8x
    }
}

#Preview {
    ExerciseLiveCardioMap(
        plannedRoute: ExerciseDemoData.plannedRoute.coordinates,
        trackedRoute: Array(ExerciseDemoData.plannedRoute.coordinates.prefix(150))
    )
}
