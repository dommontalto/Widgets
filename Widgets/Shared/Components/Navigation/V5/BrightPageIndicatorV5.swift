//
//  BrightPageIndicatorV5.swift
//  Widgets
//
//  Created by Dom Montalto on 13/7/2026.
//

import SwiftUI

struct BrightPageIndicatorV5: View {
    let total: Int
    @Binding var activeIndex: Int?

    var body: some View {
        if activeIndex != nil {
            dots
        }
    }

    private var dots: some View {
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
        .brightHapticV5(.soft, trigger: activeIndex)
        .modifier(BrightGlassEffectV5())
    }
}

#Preview {
    BrightPageIndicatorV5(total: 3, activeIndex: .constant(0))
}
