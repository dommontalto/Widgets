//
//  WaypointMapHarness.swift
//  Widgets
//
//  Created by Dom Montalto on 25/11/2026.
//

#if DEBUG
import SwiftUI

// Opens the app straight onto the full-screen map when it's launched with
// `-waypointMap`, so the map can be looked at without tapping through to it.
// `-waypointRain "Heavy drops"` picks a rain design by its menu title.
struct WaypointMapHarness: View {
    static let argument = "-waypointMap"

    @State private var correction = WaypointCorrection.decrease
    @State private var rain = WaypointRainStyle.allCases.first {
        $0.title == UserDefaults.standard.string(forKey: "waypointRain")
    } ?? .heavyDrops

    @State private var floating = WaypointFloatingClouds.allCases.first {
        $0.title == UserDefaults.standard.string(forKey: "waypointFloating")
    } ?? .puffs

    var body: some View {
        // `-waypointPage` shows it the way the Waypoint tab does, at its own height
        // inside a scrolling page.
        if ProcessInfo.processInfo.arguments.contains("-waypointPage") {
            ScrollView {
                WaypointMap(correction: $correction, rain: $rain, floating: $floating)
                    .padding(.top, .spacing12x)
            }
            .background(Color.defaultBackground.ignoresSafeArea())
        } else {
            WaypointMap(correction: $correction, rain: $rain, floating: $floating, fillsScreen: true)
                .background(Color.defaultBackground.ignoresSafeArea())
        }
    }
}
#endif
