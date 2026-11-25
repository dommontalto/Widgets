//
//  WidgetsApp.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

@main
struct WidgetsApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains(WaypointMapHarness.argument) {
                WaypointMapHarness()
            } else {
                MainDockView()
                    .brightToastHostV5()
            }
            #else
            MainDockView()
                .brightToastHostV5()
            #endif
        }
    }
}
