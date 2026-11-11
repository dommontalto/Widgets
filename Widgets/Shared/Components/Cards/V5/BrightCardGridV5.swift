//
//  BrightCardGridV5.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

// Two columns of small cards, each tapped or held by the screen that lays it out.
struct BrightCardGridV5<Content: View>: View {
    var spacing: CGFloat = .spacing2x
    @ViewBuilder let content: Content

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2), spacing: spacing) {
            content
        }
    }
}

// A card for the grid: a small mark beside the title, then a large value with its unit and a
// dimmer line under it, on the page's own colour inside a hairline outline.
struct BrightCardGridItemV5<Icon: View, Accessory: View>: View {
    let title: String
    let value: String?
    let unit: String?
    let detail: String?
    let detailSystemImage: String?
    let color: Color
    let icon: Icon
    let titleAccessory: Accessory

    init(
        _ title: String,
        value: String? = nil,
        unit: String? = nil,
        detail: String? = nil,
        detailSystemImage: String? = nil,
        color: Color = .clear,
        @ViewBuilder icon: () -> Icon,
        @ViewBuilder titleAccessory: () -> Accessory
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.detail = detail
        self.detailSystemImage = detailSystemImage
        self.color = color
        self.icon = icon()
        self.titleAccessory = titleAccessory()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                icon
                    .frame(height: Constants.iconSize)

                BrightText(title, size: .subheading)
                    .lineLimit(1)

                titleAccessory
            }

            if let value {
                HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                    BrightText(value, size: .huge2)
                        .monospacedDigit()
                        .lineLimit(1)

                    if let unit {
                        BrightText(unit, size: .heading, color: .lightTextColor)
                            .lineLimit(1)
                    }
                }
            }

            if let detail {
                HStack(spacing: .spacing05x) {
                    if let detailSystemImage {
                        Image(systemName: detailSystemImage)
                            .font(.standard(size: .heading, weight: .regular))
                            .foregroundStyle(Color.lightTextColor)
                    }

                    BrightText(detail, size: .heading, color: .lightTextColor)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing3x)
        .modifier(BrightCardModifierV5(color: color, cornerRadius: .cardCornerRadius))
    }
}

extension BrightCardGridItemV5 where Accessory == EmptyView {
    init(
        _ title: String,
        value: String? = nil,
        unit: String? = nil,
        detail: String? = nil,
        detailSystemImage: String? = nil,
        color: Color = .clear,
        @ViewBuilder icon: () -> Icon
    ) {
        self.init(title, value: value, unit: unit, detail: detail, detailSystemImage: detailSystemImage, color: color, icon: icon) { EmptyView() }
    }
}

// Outside the structs: a generic type cannot hold static stored properties.
private enum Constants {
    static let iconSize: CGFloat = .spacing3x
}

#Preview {
    BrightCardGridV5 {
        ForEach(["Heart", "Sleep", "Metabolism"], id: \.self) { title in
            BrightCardGridItemV5(title, value: "12", unit: "markers") {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.defaultRed)
            }
        }
    }
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultBackground.ignoresSafeArea())
}
