//
//  BrightHorizontalBlurV5.swift
//  Widgets
//

import SwiftUI

private struct BrightHorizontalBlurV5: ViewModifier {
    var width: CGFloat

    @State private var leading: CGFloat = 0
    @State private var trailing: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: [CGFloat].self) { geometry in
                let offset = geometry.contentOffset.x + geometry.contentInsets.leading
                let remaining = geometry.contentSize.width + geometry.contentInsets.leading + geometry.contentInsets.trailing
                    - geometry.containerSize.width - offset
                return [min(max(offset / width, 0), 1), min(max(remaining / width, 0), 1)]
            } action: { _, fades in
                leading = fades[0]
                trailing = fades[1]
            }
            .mask {
                HStack(spacing: .spacing0x) {
                    edge(fade: leading, startPoint: .leading, endPoint: .trailing)
                    Color.black
                    edge(fade: trailing, startPoint: .trailing, endPoint: .leading)
                }
            }
    }

    private func edge(fade: CGFloat, startPoint: UnitPoint, endPoint: UnitPoint) -> some View {
        LinearGradient(
            colors: [.black.opacity(1 - fade), .black],
            startPoint: startPoint,
            endPoint: endPoint
        )
        .frame(width: width)
    }
}

extension View {
    func brightHorizontalBlurV5(width: CGFloat = .spacing5x) -> some View {
        modifier(BrightHorizontalBlurV5(width: width))
    }
}
