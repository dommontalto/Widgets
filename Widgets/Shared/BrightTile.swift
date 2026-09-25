//
//  BrightTile.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

// A fixed-size tappable tile over a blurred image: an icon up top, a title
// and subtitle at the foot, the icon and subtitle overlaid onto the image.
struct BrightTile<Icon: View>: View {
    let title: String
    let subtitle: String
    let backgroundImage: String
    let onTap: () -> Void
    let icon: Icon

    init(
        _ title: String,
        subtitle: String,
        backgroundImage: String,
        onTap: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.title = title
        self.subtitle = subtitle
        self.backgroundImage = backgroundImage
        self.onTap = onTap
        self.icon = icon()
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: .spacing0x) {
                icon
                    .foregroundStyle(.white)
                    .blendMode(.overlay)
                    .frame(width: .spacing6x, height: .spacing6x)

                Spacer(minLength: .spacing0x)

                BrightText(title, size: .subheading, color: .white, weight: .regular)

                BrightText(subtitle, size: .body1, color: .white)
                    .blendMode(.overlay)
            }
            .padding(.horizontal, .spacing3x)
            .padding(.vertical, .spacing2x)
            .frame(width: Constants.width, height: Constants.height, alignment: .leading)
            .background {
                Image(backgroundImage)
                    .resizable()
                    .scaledToFill()
                    // Blur feathers the image's edges, so it runs past the clip.
                    .scaleEffect(Constants.backgroundOverscan)
                    .blur(radius: Constants.backgroundBlur)
            }
            .overlay(Color.white.opacity(.ultraLowOpacity))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous)
                    .strokeBorder(Color.black.opacity(.minimalOpacity), lineWidth: Constants.stroke)
            }
            .contentShape(RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// A horizontally scrolling row of tiles, optionally blurred and faded at the trailing edge to hint there's more.
struct BrightTileRow<Content: View>: View {
    var blur = false
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing3x) {
                content
            }
            .padding(.vertical, blurBleed)
            .scrollTargetLayout()
            .visualEffect { [blur] effect, proxy in
                let visible = proxy.bounds(of: .scrollView) ?? proxy.frame(in: .local)
                return effect.layerEffect(
                    ShaderLibrary.brightEdgeBlur(
                        .float(visible.maxX - Constants.trailingBlur),
                        .float(visible.maxX),
                        .float(Constants.maxBlur)
                    ),
                    maxSampleOffset: CGSize(width: Constants.maxBlur, height: Constants.maxBlur),
                    isEnabled: blur
                )
            }
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
        .modifier(BrightTileRowEdge(fades: blur))
        .padding(.vertical, -blurBleed)
    }

    private var blurBleed: CGFloat {
        blur ? Constants.maxBlur : .spacing0x
    }
}

private struct BrightTileRowEdge: ViewModifier {
    let fades: Bool

    func body(content: Content) -> some View {
        if fades {
            hideSystemEdges(content)
                .mask {
                    HStack(spacing: .spacing0x) {
                        Color.black

                        LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: Constants.trailingFade)
                    }
                }
        } else {
            hideSystemEdges(content)
        }
    }

    @ViewBuilder private func hideSystemEdges(_ content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectHidden(true, for: .horizontal)
        } else {
            content
        }
    }
}

// Outside the structs: a generic type cannot hold static stored properties.
private enum Constants {
    static let width: CGFloat = 160
    static let height: CGFloat = 110
    static let stroke: CGFloat = 0.5
    static let backgroundBlur: CGFloat = 8
    static let backgroundOverscan: CGFloat = 1.2
    static let trailingFade: CGFloat = .spacing4x
    static let trailingBlur: CGFloat = .spacing8x
    static let maxBlur: CGFloat = .spacing1x
}
