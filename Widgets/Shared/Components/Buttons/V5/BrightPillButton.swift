//
//  BrightPillButton.swift
//  Bright
//
//  Created by Zoe Friedman on 8/8/2023.
//  Copyright © 2023 Bryan Jordan. All rights reserved.
//
import SwiftUI

struct BrightPillButton: View {
    let title: String
    let image: String?
    let systemImage: String?
    let color: Color?
    let textColor: Color?
    let size: FontSizes?
    let buttonSize: BrightButtonSizes
    let isClear: Bool
    // Unselected dims the whole capsule and drops the label to 60%. Defaults
    // to true, so a plain button is full strength. `BrightTagV5` and the page
    // pills in `BrightSwipePageViewV5` are this button at `.small`.
    let isSelected: Bool
    // Glass by default. `false` gives the capsule a flat fill instead — the
    // colour a chip takes on a sheet — for a rail of many tags, where each
    // glass capsule is a backdrop pass of its own every frame.
    let isGlass: Bool
    let isLoading: Bool
    let onTapCallback: () -> Void

    init(
        _ title: String,
        image: String? = nil,
        systemImage: String? = nil,
        color: Color? = nil,
        textColor: Color? = nil,
        size: FontSizes? = nil,
        buttonSize: BrightButtonSizes = .medium,
        isClear: Bool = false,
        isSelected: Bool = true,
        isGlass: Bool = true,
        isLoading: Bool = false,
        onTapCallback: @escaping (() -> Void)
    ) {
        self.title = title
        self.image = image
        self.systemImage = systemImage
        self.color = color
        self.textColor = textColor
        self.size = size
        self.buttonSize = buttonSize
        self.isClear = isClear
        self.isSelected = isSelected
        self.isGlass = isGlass
        self.isLoading = isLoading
        self.onTapCallback = onTapCallback
    }

    private var resolvedTextColor: Color {
        if let textColor { return textColor }
        if color != nil { return .black }
        return isSelected ? .textColor : .lightTextColor
    }

    private var resolvedSize: FontSizes {
        size ?? buttonSize.defaultFontSize
    }

    var body: some View {
        Button(action: onTapCallback) {
            ZStack {
                if isLoading {
                    BrightSolvingOrbV5(size: buttonSize.rawValue * Constants.orbScale)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    HStack(spacing: .spacing1x) {
                        if let systemImage {
                            Image(systemName: systemImage)
                                .font(.system(size: Constants.imageSize, weight: .medium))
                                .foregroundStyle(resolvedTextColor)
                        } else if let image {
                            // A template, so the asset takes the label's colour and
                            // dims with it, the way a symbol does.
                            Image(image)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: Constants.imageSize, height: Constants.imageSize)
                                .foregroundStyle(resolvedTextColor)
                        }
                        BrightText(title, size: resolvedSize, color: resolvedTextColor)
                    }
                    .fixedSize()
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, isLoading ? .spacing0x : (buttonSize == .large ? .spacing3x : .spacing105x))
            .frame(width: isLoading ? buttonSize.rawValue : nil, height: buttonSize.rawValue)
        }
        .disabled(isLoading)
        .animation(.brightBouncy, value: isLoading)
        .background((color ?? flatFill).opacity(.veryHighOpacity), in: Capsule())
        .modifier(OptionalGlass(isOn: isGlass, isClear: isClear))
        .opacity(isSelected ? .opaque : .semiLowOpacity)
    }

    // Under glass the capsule is clear and the glass is the fill; without
    // it, the flat chip colour stands in.
    private var flatFill: Color {
        isGlass ? .clear : .defaultSheetModalCards
    }

    private enum Constants {
        static let imageSize: CGFloat = 16
        static let orbScale: CGFloat = 0.6
    }
}

// Glass only when asked, so a flat pill is left exactly as it draws itself.
private struct OptionalGlass: ViewModifier {
    let isOn: Bool
    let isClear: Bool

    func body(content: Content) -> some View {
        if isOn {
            content.modifier(BrightGlassEffectV5(shape: .capsule, isClear: isClear))
        } else {
            content
        }
    }
}
