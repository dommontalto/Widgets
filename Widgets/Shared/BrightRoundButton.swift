//
//  BrightRoundButton.swift
//  Bright
//
//  Created by Dom Montalto on 4/3/2026.
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

struct BrightRoundButton: View {
    private enum ImageSource {
        case system(String)
        case asset(String)
        case text(String)
    }

    private let imageSource: ImageSource
    let size: BrightButtonSizes
    let color: Color?
    let imageColor: Color?
    let imageRotation: Angle
    let haptic: BrightHaptic?
    let onTapCallback: (() -> Void)?

    @State private var tapTick = 0

    var systemImage: String {
        if case .system(let name) = imageSource { return name }
        return ""
    }

    init(
        systemImage: String,
        size: BrightButtonSizes = .medium,
        color: Color? = nil,
        imageColor: Color? = nil,
        imageRotation: Angle = .zero,
        haptic: BrightHaptic? = .light,
        onTapCallback: (() -> Void)? = nil
    ) {
        self.imageSource = .system(systemImage)
        self.size = size
        self.color = color
        self.imageColor = imageColor
        self.imageRotation = imageRotation
        self.haptic = haptic
        self.onTapCallback = onTapCallback
    }

    init(
        imageName: String,
        size: BrightButtonSizes = .medium,
        color: Color? = nil,
        imageColor: Color? = nil,
        imageRotation: Angle = .zero,
        haptic: BrightHaptic? = .light,
        onTapCallback: (() -> Void)? = nil
    ) {
        self.imageSource = .asset(imageName)
        self.size = size
        self.color = color
        self.imageColor = imageColor
        self.imageRotation = imageRotation
        self.haptic = haptic
        self.onTapCallback = onTapCallback
    }

    init(
        title: String,
        size: BrightButtonSizes = .medium,
        color: Color? = nil,
        onTapCallback: (() -> Void)? = nil
    ) {
        self.imageSource = .text(title)
        self.size = size
        self.color = color
        self.imageColor = nil
        self.imageRotation = .zero
        self.haptic = .light
        self.onTapCallback = onTapCallback
    }

    private func tapped() {
        tapTick += 1
        onTapCallback?()
    }

    /// At `.extraLarge` a passed colour reads as a tint rather than a fill: the
    /// glyph takes the colour at full strength over a 30% wash of it.
    private var isTinted: Bool {
        size == .extraLarge && color != nil
    }

    private var resolvedImageColor: Color {
        if let imageColor { return imageColor }
        guard let color else { return .textColor }
        return isTinted ? color : .defaultBlack
    }

    private var resolvedBackground: Color {
        guard let color else { return .clear }
        return isTinted ? color.opacity(.veryLowOpacity) : color
    }

    private var isChevronForward: Bool {
        if case .system(let name) = imageSource {
            return name == "chevron.left" || name == "chevron.right"
        }
        return false
    }

    @ViewBuilder
    private var imageView: some View {
        switch imageSource {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: size.rawValue * 0.5, weight: .medium))
                .scaledToFit()
        case .asset(let name):
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size.rawValue * 0.5, height: size.rawValue * 0.5)
        case .text(let title):
            BrightText(title, size: size.defaultFontSize, color: resolvedImageColor, weight: .regular)
        }
    }

    private var resolvedHaptic: BrightHaptic? {
        size == .extraLarge ? haptic : nil
    }

    var body: some View {
        Button(action: tapped) {
            imageView
                .rotationEffect(imageRotation)
                .frame(width: size.rawValue, height: size.rawValue)
                .foregroundStyle(resolvedImageColor)
                .background(resolvedBackground, in: Circle())
                .contentShape(Circle())
        }
        .modifier(BrightRoundButtonBackground(isGlass: !isChevronForward))
        .highPriorityGesture(TapGesture().onEnded { _ in
            tapped()
        })
        .allowsHitTesting(onTapCallback != nil)
        .brightHaptic(trigger: tapTick) { _, _ in resolvedHaptic }
    }
}

private struct BrightRoundButtonBackground: ViewModifier {
    let isGlass: Bool

    func body(content: Content) -> some View {
        if isGlass {
            content.modifier(GlassEffect())
        } else {
            content
        }
    }
}

#Preview {
    BrightRoundButton(systemImage: "plus")
}
