//
//  BrightWidgetIconV5.swift
//  Widgets
//
//  Created by Dom Montalto on 13/10/2026.
//

import SwiftUI

struct BrightWidgetIconV5<Style: ShapeStyle>: View {
    let systemImage: String
    let style: Style

    var body: some View {
        Image(systemName: systemImage)
            .resizable()
            .scaledToFit()
            .fontWeight(.light)
            .foregroundStyle(style)
            .frame(width: Constants.size, height: Constants.size)
    }

    private enum Constants {
        static var size: CGFloat { 18 }
    }
}
