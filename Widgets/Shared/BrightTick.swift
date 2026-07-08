//
//  BrightTick.swift
//  Widgets
//
//  Ported from Bright.
//

import SwiftUI

/// Selected-state tick for option rows: sky-blue circle with a white checkmark.
struct BrightTick: View {
    var size: CGFloat = .spacing4x

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.defaultSkyBlue)
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

/// Unselected counterpart to `BrightTick`: a dimmed outline circle.
struct BrightEmptyTick: View {
    var size: CGFloat = .spacing4x

    var body: some View {
        Circle()
            .strokeBorder(Color.lightTextColor.opacity(.semiLowOpacity), lineWidth: 1.5)
            .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: .spacing2x) {
        BrightTick()
        BrightEmptyTick()
    }
    .padding()
}
