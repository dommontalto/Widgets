//
//  BrightDotSelectorV5.swift
//  Widgets
//
//  Created by Dom Montalto on 20/7/2026.
//

import SwiftUI

struct BrightDotSelectorItem {
    let title: String
    var systemImage: String? = nil
    var image: String? = nil
}

struct BrightDotSelectorV5: View {
    let items: [BrightDotSelectorItem]
    @Binding var selectedIndex: Int
    var hapticsEnabled: Bool = true
    var onSelect: ((Int) -> Void)?

    private static let rowHeight: CGFloat = .spacing4x
    private static let rowSpacing: CGFloat = .spacing3x
    private static let compactRowHeight: CGFloat = .spacing105x
    private static let compactRowSpacing: CGFloat = .spacing025x
    private static let tapWidth: CGFloat = .spacing8x
    private static let dashWidth: CGFloat = .spacing1x
    private static let dashHeight: CGFloat = 1
    private static let imageCircleSize: CGFloat = 23
    private static let imageSize: CGFloat = 13

    private var isCompact: Bool {
        items.allSatisfy { $0.image == nil && $0.systemImage == nil }
    }

    private var rowHeight: CGFloat {
        isCompact ? Self.compactRowHeight : Self.rowHeight
    }

    private var rowSpacing: CGFloat {
        isCompact ? Self.compactRowSpacing : Self.rowSpacing
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: rowSpacing) {
            ForEach(items.indices, id: \.self) { i in
                HStack(spacing: .spacing1x) {
                    if i == selectedIndex {
                        BrightPillButton(items[i].title, buttonSize: .small) {}
                            .allowsHitTesting(false)
                            .transition(.opacity.combined(with: .scale(scale: 0.6, anchor: .trailing)))
                            .fixedSize()
                    }
                    indicator(at: i)
                }
                .frame(width: Self.tapWidth, height: rowHeight, alignment: .trailing)
                .contentShape(Rectangle())
                .onTapGesture { select(i) }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    let index = Int(value.location.y / (rowHeight + rowSpacing))
                    let clamped = min(max(index, 0), items.count - 1)
                    if clamped != selectedIndex { select(clamped) }
                }
        )
        .animation(.brightBouncy, value: selectedIndex)
        .brightHapticV5(.soft, trigger: selectedIndex) { _, _ in hapticsEnabled }
    }

    @ViewBuilder
    private func indicator(at i: Int) -> some View {
        let item = items[i]
        if let image = item.image {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: Self.imageSize, height: Self.imageSize)
                .opacity(i == selectedIndex ? 1 : .lowOpacity)
                .frame(width: Self.imageCircleSize, height: Self.imageCircleSize)
                .modifier(BrightGlassEffectV5(shape: .circle))
        } else if let systemImage = item.systemImage {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(i == selectedIndex ? Color.textColor : Color.lightTextColor)
                .frame(width: Self.imageCircleSize, height: Self.imageCircleSize)
                .modifier(BrightGlassEffectV5(shape: .circle))
        } else {
            Capsule()
                .fill(i == selectedIndex ? Color.textColor : Color.semiLightTextColor.opacity(0.4))
                .frame(width: Self.dashWidth, height: Self.dashHeight)
        }
    }

    private func select(_ i: Int) {
        guard i != selectedIndex else { return }
        withAnimation(.brightBouncy) { selectedIndex = i }
        onSelect?(i)
    }
}
