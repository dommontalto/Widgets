//
//  BrightShimmerV5.swift
//  Widgets
//
//  Created by Dom Montalto on 25/9/2026.
//

import SwiftUI

private struct BrightShimmerV5: ViewModifier {
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
    func brightShimmerV5(isActive: Bool = true) -> some View {
        modifier(BrightShimmerV5(isActive: isActive))
    }
}

#Preview {
    BrightText("Thinking…", size: .body1)
        .brightShimmerV5()
        .padding(.spacing3x)
}
