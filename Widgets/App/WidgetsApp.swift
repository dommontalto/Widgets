//
//  WidgetsApp.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

@main
struct WidgetsApp: App {
    @State private var showingLogoTest = true

    var body: some Scene {
        WindowGroup {
            MainDockView()
                .brightToastHostV5()
                .sheet(isPresented: $showingLogoTest) {
                    LogoTestSheet()
                }
        }
    }
}
