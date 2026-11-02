//
//  VaultTestHero.swift
//  Widgets
//

import SwiftUI

// A category's artwork as a page header that stretches when pulled down.
struct VaultTestHero: View {
    let category: VaultTestCategory
    let title: String
    let subtitle: String
    let pull: CGFloat

    var body: some View {
        Color.clear
            .frame(height: Constants.heroHeight)
            .background { heroImage }
            .clipped()
            .mask { fade }
            .scaleEffect(1 + pull / Constants.heroHeight, anchor: .bottom)
            .overlay(alignment: .top) {
                VStack(spacing: .spacing2x) {
                    VaultTestCategoryIcon(category: category, symbolSize: .huge)
                        .frame(width: Constants.iconSize, height: Constants.iconSize)

                    BrightText(title, size: .standout1, weight: .regular)
                        .multilineTextAlignment(.center)

                    BrightText(subtitle, size: .standout3)
                }
                .blendMode(.overlay)
                .padding(.horizontal, .spacing3x)
                .padding(.top, Constants.heroContentTop)
            }
    }

    private var heroImage: some View {
        ZStack {
            background(blur: Constants.backgroundBlur)

            background(blur: Constants.fadeBlur)
                .mask {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                }
        }
    }

    private func background(blur: CGFloat) -> some View {
        Image(category.backgroundName)
            .resizable()
            .scaledToFill()
            // Blur feathers the image's edges, so it runs past the clip.
            .scaleEffect(Constants.backgroundOverscan)
            .blur(radius: blur)
    }

    private var fade: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: Constants.fadeStart),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private enum Constants {
        static let heroHeight: CGFloat = 286
        static let heroContentTop: CGFloat = 98
        static let iconSize: CGFloat = 46
        static let backgroundBlur: CGFloat = 8
        static let fadeBlur: CGFloat = 22
        static let backgroundOverscan: CGFloat = 1.2
        static let fadeStart: CGFloat = 0.25
    }
}

struct VaultTestCategoryIcon: View {
    let category: VaultTestCategory
    let symbolSize: FontSizes

    @ViewBuilder
    var body: some View {
        if let iconName = category.iconName {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: category.systemImage)
                .font(.standard(size: symbolSize, weight: .medium))
        }
    }
}
