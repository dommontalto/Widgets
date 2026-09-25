//
//  BrightWidgetTitle.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

// A small icon-and-title label over a widget, with the widget underneath.
struct BrightWidgetTitle<Content: View, Accessory: View>: View {
    enum Icon {
        case asset(String)
        case symbol(String)
    }

    let icon: Icon
    let title: String
    let onTap: (() -> Void)?
    let accessory: Accessory
    let content: Content

    init(
        icon: Icon,
        title: String,
        onTap: (() -> Void)? = nil,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.onTap = onTap
        self.accessory = accessory()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            HStack(spacing: .spacing2x) {
                if let onTap {
                    Button(action: onTap) { header }
                        .buttonStyle(.plain)
                } else {
                    header
                }

                if Accessory.self != EmptyView.self {
                    Spacer(minLength: .spacing0x)

                    accessory
                }
            }
            .padding(.leading, .spacing2x)

            content
        }
    }

    private var header: some View {
        HStack(spacing: .spacing1x) {
            iconView
                .frame(width: Constants.iconSize, height: Constants.iconSize)

            BrightText(title, size: .body1)

            if onTap != nil {
                Image(systemName: "chevron.forward")
                    .font(.standardSFPro(size: .body1, weight: .semibold))
                    .foregroundStyle(Color.lightTextColor)
            }
        }
        .contentShape(Rectangle())
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

extension BrightWidgetTitle where Accessory == EmptyView {
    init(
        icon: Icon,
        title: String,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(icon: icon, title: title, onTap: onTap, accessory: { EmptyView() }, content: content)
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
