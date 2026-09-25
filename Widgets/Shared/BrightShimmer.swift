//
//  BrightShimmer.swift
//  Widgets
//
//  Created by Dom Montalto on 25/9/2026.
//

import SwiftUI

// A bright band that sweeps left to right across whatever it wraps, over a
// dimmed copy of it. Driven by a repeating animation rather than a timeline,
// so it never updates per frame inside a view that is animating away.
struct BrightShimmer: ViewModifier {
    var isActive = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isSweeping = false

    func body(content: Content) -> some View {
        let isShimmering = isActive && !reduceMotion
        content
            .opacity(isShimmering ? .semiLowOpacity : .opaque)
            .overlay {
                content
                    .mask {
                        LinearGradient(
                            colors: [.clear, .black, .clear],
                            startPoint: UnitPoint(x: isSweeping ? 1 : -1, y: 0.5),
                            endPoint: UnitPoint(x: isSweeping ? 2 : 0, y: 0.5)
                        )
                    }
                    .opacity(isShimmering ? .opaque : .zero)
            }
            .animation(.brightEaseInOut, value: isShimmering)
            .onAppear {
                withAnimation(.linear(duration: Constants.sweepDuration).repeatForever(autoreverses: false)) {
                    isSweeping = true
                }
            }
    }

    private enum Constants {
        static let sweepDuration: TimeInterval = 1.4
    }
}

extension View {
    func brightShimmer(isActive: Bool = true) -> some View {
        modifier(BrightShimmer(isActive: isActive))
    }
}

#Preview {
    BrightText("Thinking…", size: .body1)
        .brightShimmer()
        .padding(.spacing3x)
}
