//
//  BrightCardGrid.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

// Two columns of small cards, each tapped or held by the screen that lays it out.
struct BrightCardGrid<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        LazyVGrid(columns: Constants.columns, spacing: .spacing2x) {
            content
        }
    }
}

// A card for the grid: a 36pt mark up top, then a title and a dimmer subtitle.
struct BrightCardGridItem<Icon: View, Accessory: View>: View {
    let title: String
    let subtitle: String
    let color: Color
    let icon: Icon
    let titleAccessory: Accessory

    init(
        _ title: String,
        subtitle: String,
        color: Color = .defaultCards,
        @ViewBuilder icon: () -> Icon,
        @ViewBuilder titleAccessory: () -> Accessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.icon = icon()
        self.titleAccessory = titleAccessory()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            icon
                .frame(height: Constants.iconSize)

            VStack(alignment: .leading, spacing: .spacing05x) {
                HStack(spacing: .spacing1x) {
                    BrightText(title, size: .subheading2)
                        .lineLimit(1)

                    titleAccessory
                }

                BrightText(subtitle, size: .body3, color: .lightTextColor)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing3x)
        .modifier(CardModifier(color: color, cornerRadius: .cornerRadius24))
    }
}

extension BrightCardGridItem where Accessory == EmptyView {
    init(
        _ title: String,
        subtitle: String,
        color: Color = .defaultCards,
        @ViewBuilder icon: () -> Icon
    ) {
        self.init(title, subtitle: subtitle, color: color, icon: icon) { EmptyView() }
    }
}

// Outside the structs: a generic type cannot hold static stored properties.
private enum Constants {
    static let iconSize: CGFloat = .spacing6x
    static let columns = Array(repeating: GridItem(.flexible(), spacing: .spacing2x), count: 2)
}

#Preview {
    BrightCardGrid {
        ForEach(["Heart", "Sleep", "Metabolism"], id: \.self) { title in
            BrightCardGridItem(title, subtitle: "12 markers") {
                Image(systemName: "heart.fill")
                    .font(.system(size: .spacing5x))
                    .frame(width: .spacing6x, height: .spacing6x)
            }
        }
    }
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultBackground.ignoresSafeArea())
}
