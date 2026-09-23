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

// A horizontally scrolling row of tiles, faded at both edges to hint there's more.
struct BrightTileRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing2x) {
                content
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
        .mask {
            HStack(spacing: .spacing0x) {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        // Fully clear over the sliver a snapped scroll leaves of the tile before.
                        .init(color: .clear, location: Constants.leadingClear),
                        .init(color: .black, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: Constants.leadingFade)

                Color.black

                LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: Constants.trailingFade)
            }
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
    static let leadingFade: CGFloat = .spacing3x
    static let leadingClear: CGFloat = .spacing1x / leadingFade
    static let trailingFade: CGFloat = .spacing7x
}
