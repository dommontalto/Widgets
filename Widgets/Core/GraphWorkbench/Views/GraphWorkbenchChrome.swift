//
//  GraphWorkbenchChrome.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI

// The Workbench's HMI chrome: square-cornered, hairline-bordered panels over
// the constellation, with small tracked-out uppercase labels.
struct GraphWorkbenchPanel: ViewModifier {
    var isActive = false

    func body(content: Content) -> some View {
        content
            .background(Color.defaultBlack.opacity(.mediumOpacity))
            .background(.ultraThinMaterial)
            .overlay {
                Rectangle()
                    .strokeBorder(
                        isActive ? Color.defaultAmber : Color.defaultWhite.opacity(.minimalOpacity),
                        lineWidth: isActive ? Constants.activeBorder : Constants.border
                    )
            }
    }
}

struct GraphWorkbenchCaps: View {
    let text: String
    var color: Color = .lightTextColor

    init(_ text: String, color: Color = .lightTextColor) {
        self.text = text
        self.color = color
    }

    var body: some View {
        BrightText(text.uppercased(), size: .body6, color: color, weight: .medium, kerning: .mediumKerning)
            .lineLimit(1)
    }
}

struct GraphWorkbenchButton: View {
    let title: String?
    let systemImage: String
    var isActive = false
    let action: () -> Void

    init(_ title: String? = nil, systemImage: String, isActive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isActive = isActive
        self.action = action
    }

    @State private var tapTick = 0

    var body: some View {
        Button {
            tapTick += 1
            action()
        } label: {
            HStack(spacing: .spacing1x) {
                Image(systemName: systemImage)
                    .font(.standard(size: .body4, weight: .medium))
                    .foregroundStyle(isActive ? Color.defaultAmber : Color.semiLightTextColor)

                if let title {
                    GraphWorkbenchCaps(title, color: isActive ? .defaultAmber : .semiLightTextColor)
                }
            }
            .padding(.horizontal, title == nil ? .spacing0x : .spacing2x)
            .frame(minWidth: Constants.height, minHeight: Constants.height)
            .modifier(GraphWorkbenchPanel(isActive: isActive))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .brightHapticV5(.light, trigger: tapTick)
    }
}

struct GraphWorkbenchSectionLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: .spacing0x) {
            HStack(spacing: .spacing1x) {
                Image(systemName: systemImage)
                    .font(.standard(size: .body6, weight: .medium))
                    .foregroundStyle(Color.defaultAmber)

                GraphWorkbenchCaps(title)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .spacing3x)
            .padding(.vertical, .spacing105x)
            .background(Color.defaultWhite.opacity(.finalBossUltraLowOpacity))

            BrightDividerV5()
        }
    }
}

private enum Constants {
    static let height: CGFloat = 36
    static let border: CGFloat = 0.5
    static let activeBorder: CGFloat = 1
}
