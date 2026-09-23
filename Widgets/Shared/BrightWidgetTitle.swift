//
//  BrightWidgetTitle.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

// A small icon-and-title label over a widget, with the widget underneath.
struct BrightWidgetTitle<Content: View>: View {
    enum Icon {
        case asset(String)
        case symbol(String)
    }

    let icon: Icon
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            HStack(spacing: .spacing1x) {
                iconView
                    .frame(width: Constants.iconSize, height: Constants.iconSize)

                BrightText(title, size: .body1)
            }
            .padding(.leading, .spacing2x)

            content
        }
    }

    @ViewBuilder private var iconView: some View {
        switch icon {
        case let .asset(name):
            Image(name)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.textColor)
        case let .symbol(name):
            Image(systemName: name)
                .font(.standardSFPro(size: .subheading2, weight: .regular))
                .foregroundStyle(Color.textColor)
        }
    }
}

// Outside the struct: a generic type cannot hold static stored properties.
private enum Constants {
    static let iconSize: CGFloat = 24
}

#Preview {
    BrightWidgetTitle(icon: .symbol("trophy.fill"), title: "Personal Records") {
        RoundedRectangle(cornerRadius: .cardCornerRadius)
            .fill(Color.defaultCards)
            .frame(height: .spacing12x)
    }
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultBackground.ignoresSafeArea())
}
