//
//  BrightChip.swift
//  Widgets
//
//  Ported from Bright.
//

import SwiftUI

/// Small rounded chip with an optional leading image, optional selected state
/// and optional trailing accessory. Pass `onTap` to make it tappable; leave it
/// nil for a static display chip.
struct BrightChip<Trailing: View>: View {
    let title: String
    var imageName: String?
    var systemImage: String?
    var size: FontSizes = .body1
    /// Text/icon colour when not selected.
    var tint: Color = .semiLightTextColor
    /// Background colour when not selected.
    var fill: Color = .sheetModalCards
    /// Selected-state colour (faint fill + stroke).
    var accent: Color = .defaultGreen
    var isSelected: Bool = false
    var onTap: (() -> Void)?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        if let onTap {
            Button(action: onTap) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: .spacing1x) {
            if let imageName {
                Image(imageName)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: Constants.imageSize))
                    .foregroundStyle(textColor)
            }

            BrightText(title, size: size, color: textColor, weight: .light)

            trailing()
        }
        .padding(.leading, .spacing2x)
        .padding(.trailing, hasTrailing ? .spacing1x : .spacing2x)
        .padding(.vertical, .spacing1x)
        .modifier(CardModifier(
            color: isSelected ? accent.opacity(.veryLowOpacity) : fill,
            cornerRadius: .cornerRadius20
        ))
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius20)
                .stroke(isSelected ? accent : Color.clear, lineWidth: 0.5)
        )
    }

    private var textColor: Color {
        isSelected ? .textColor : tint
    }

    private var hasTrailing: Bool {
        Trailing.self != EmptyView.self
    }
}

private enum Constants {
    static let imageSize: CGFloat = 14
}

extension BrightChip where Trailing == EmptyView {
    init(
        title: String,
        imageName: String? = nil,
        systemImage: String? = nil,
        size: FontSizes = .body1,
        tint: Color = .semiLightTextColor,
        fill: Color = .sheetModalCards,
        accent: Color = .defaultGreen,
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            imageName: imageName,
            systemImage: systemImage,
            size: size,
            tint: tint,
            fill: fill,
            accent: accent,
            isSelected: isSelected,
            onTap: onTap,
            trailing: { EmptyView() }
        )
    }
}

#Preview {
    VStack(spacing: .spacing2x) {
        BrightChip(title: "Cramps", systemImage: "sparkles")
        BrightChip(title: "Cramps", systemImage: "sparkles", isSelected: true, onTap: {})
        BrightChip(title: "LIVER", size: .body3, tint: .defaultBlue, fill: .defaultLighthouseBlue)
    }
    .padding()
    .background(Color.sheetBackground)
}
