//
//  BrightPageIndicator.swift
//  Widgets
//
//  Created by Dom Montalto on 13/7/2026.
//

import SwiftUI

struct BrightPageIndicator: View {
    let total: Int
    @Binding var activeIndex: Int?

    @State private var width: CGFloat = 0

    var body: some View {
        HStack(spacing: .spacing1x) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == activeIndex ? Color.textColor : Color.lightTextColor)
                    .frame(width: .spacing1x, height: .spacing1x)
            }
        }
        .animation(.brightEaseInOut, value: activeIndex)
        .padding(.horizontal, .spacing2x)
        .frame(height: .spacing5x)
        .contentShape(Capsule())
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { select(at: $0.location.x) }
        )
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: activeIndex)
        .modifier(GlassEffect())
    }

    private func select(at x: CGFloat) {
        guard width > 0, total > 0 else { return }
        let index = min(max(Int(x / width * CGFloat(total)), 0), total - 1)
        if index != activeIndex {
            activeIndex = index
        }
    }
}

#Preview {
    BrightPageIndicator(total: 3, activeIndex: .constant(0))
}
