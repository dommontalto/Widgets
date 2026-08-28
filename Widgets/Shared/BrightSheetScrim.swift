//
//  BrightSheetScrim.swift
//  Widgets
//
//  Created by Dom Montalto on 28/8/2026.
//

import SwiftUI

struct BrightSheetScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .defaultSheetScrim.opacity(0), location: 0),
                .init(color: .defaultSheetScrim, location: 1),
            ],
            startPoint: UnitPoint(x: 0.5, y: 0),
            endPoint: UnitPoint(x: 0.5, y: Constants.solidBy)
        )
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private enum Constants {
        static let solidBy: CGFloat = 0.78
    }
}

#Preview {
    ZStack {
        Color.defaultSkyBlue.ignoresSafeArea()
        BrightSheetScrim()
    }
}
