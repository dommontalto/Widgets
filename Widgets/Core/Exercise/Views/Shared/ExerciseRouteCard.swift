//
//  ExerciseRouteCard.swift
//  Widgets
//
//  Created by Dom Montalto on 27/8/2026.
//

import SwiftUI

// Tighter where the card meets the screen edge; an unanchored card takes
// the same radius all round.
enum ExerciseRouteCardGeometry {
    static let height: CGFloat = 160
    static let topCorner: CGFloat = 36
    static let bottomCorner: CGFloat = 44
}

struct ExerciseRouteCard<Content: View>: View {
    var topCorner: CGFloat = ExerciseRouteCardGeometry.topCorner
    var bottomCorner: CGFloat = ExerciseRouteCardGeometry.bottomCorner

    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: .spacing2x) {
            content()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .spacing3x)
        .frame(height: ExerciseRouteCardGeometry.height)
        .background(Color.defaultCards, in: shape)
        .modifier(GlassEffect(
            shape: .unevenRoundedRect(top: topCorner, bottom: bottomCorner),
            interactive: false
        ))
    }

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: topCorner,
            bottomLeading: bottomCorner,
            bottomTrailing: bottomCorner,
            topTrailing: topCorner
        ))
    }

}

struct ExerciseRouteStats: View {
    let distance: String
    let elevation: String
    let estimatedTime: String

    var body: some View {
        HStack(spacing: .spacing0x) {
            stat("Distance", value: distance)
            stat("Elevation", value: elevation)
            stat("Est. Time", value: estimatedTime)
        }
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(spacing: .spacing1x) {
            BrightText(title, size: .body2, color: .lightTextColor, weight: .regular)

            BrightText(value, size: .standout2)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}
