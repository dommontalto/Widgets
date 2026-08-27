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

    // Shared with the route generator and the completed map so all three read
    // the same way.
    @AppStorage("exerciseRouteMapIsDark") private var isDarkMap = false

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

            if let current = route.last {
                MapViewAnnotation(coordinate: current) {
                    runnerMarker
                }
                .allowOverlap(true)
            }
        }
        .mapStyle(.standard(lightPreset: isDarkMap ? .night : .day))
        // No compass or scale bar. The logo and attribution have to stay.
        .ornamentOptions(OrnamentOptions(
            scaleBar: ScaleBarViewOptions(visibility: .hidden),
            compass: CompassViewOptions(visibility: .hidden)
        ))
        .ignoresSafeArea()
        .onAppear { frameRoute() }
    }

    private var runnerMarker: some View {
        Image(systemName: "figure.run")
            .font(.system(size: Constants.markerGlyphSize, weight: .medium))
            .foregroundStyle(Color.defaultBlack)
            .frame(width: Constants.markerSize, height: Constants.markerSize)
            .background(Color.defaultSkyBlueCyan, in: Circle())
            .shadow(color: .black.opacity(.veryLowOpacity), radius: 4, y: 2)
    }

    private func frameRoute() {
        guard route.count >= 2 else {
            viewport = .followPuck(zoom: Constants.followZoom, bearing: .heading)
            return
        }
        viewport = .overview(
            geometry: LineString(route),
            geometryPadding: EdgeInsets(
                top: Constants.overviewPadding,
                leading: Constants.overviewPadding,
                bottom: Constants.overviewPadding,
                trailing: Constants.overviewPadding
            )
        )
    }

    private enum Constants {
        static let routeLineWidth: Double = 5
        static let routeEmissiveStrength: Double = 1
        static let markerSize: CGFloat = .spacing6x
        static let markerGlyphSize: CGFloat = 17
        static let followZoom: CGFloat = 15
        static let overviewPadding: CGFloat = .spacing8x
    }
}

#Preview {
    ExerciseLiveCardioMap()
}
