//
//  BrightChip.swift
//  Widgets
//
//  Ported from Bright.
//

import SwiftUI

struct BrightChip<Trailing: View>: View {
    let title: String
    var imageName: String?
    var systemImage: String?
    var size: FontSizes = .body1
    var tint: Color = .semiLightTextColor
    var fill: Color = .sheetModalCards
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

            BrightText(title, size: size, color: textColor)

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
