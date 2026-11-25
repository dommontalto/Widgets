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
struct WaypointMapHarness: View {
    static let argument = "-waypointMap"

    @State private var correction = WaypointCorrection.decrease
    var body: some View {
        // `-waypointPage` shows it the way the Waypoint tab does, at its own height
        // inside a scrolling page.
        if ProcessInfo.processInfo.arguments.contains("-waypointPage") {
            ScrollView {
                WaypointMap(correction: $correction)
                    .padding(.top, .spacing12x)
            }
            .background(Color.defaultBackground.ignoresSafeArea())
        } else {
            WaypointMap(correction: $correction, fillsScreen: true)
                .background(Color.defaultBackground.ignoresSafeArea())
        }
    }
}
#endif
