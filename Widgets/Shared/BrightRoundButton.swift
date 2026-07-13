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
    }

    private let imageSource: ImageSource
    let size: BrightButtonSizes
    let color: Color?
    let imageRotation: Angle
    let onTapCallback: (() -> Void)?

    var systemImage: String {
        if case .system(let name) = imageSource { return name }
        return ""
    }

    init(
        systemImage: String,
        size: BrightButtonSizes = .medium,
        color: Color? = nil,
        imageRotation: Angle = .zero,
        onTapCallback: (() -> Void)? = nil
    ) {
        self.imageSource = .system(systemImage)
        self.size = size
        self.color = color
        self.imageRotation = imageRotation
        self.onTapCallback = onTapCallback
    }

    init(
        imageName: String,
        size: BrightButtonSizes = .medium,
        color: Color? = nil,
        imageRotation: Angle = .zero,
        onTapCallback: (() -> Void)? = nil
    ) {
        self.imageSource = .asset(imageName)
        self.size = size
        self.color = color
        self.imageRotation = imageRotation
        self.onTapCallback = onTapCallback
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
        }
    }

    var body: some View {
        Button(action: { onTapCallback?() }) {
            imageView
                .rotationEffect(imageRotation)
                .frame(width: size.rawValue, height: size.rawValue)
                .foregroundStyle(color ?? .textColor)
                .background((color ?? .clear).opacity(.veryLowOpacity), in: Circle())
                .contentShape(Circle())
        }
        .modifier(BrightRoundButtonBackground(isGlass: !isChevronForward))
        .highPriorityGesture(TapGesture().onEnded { _ in
            onTapCallback?()
        })
        .allowsHitTesting(onTapCallback != nil)
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
