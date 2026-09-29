//
//  SideMenuView.swift
//  Widgets
//
//  Created by Dom Montalto on 29/9/2026.
//

import SwiftUI

struct SideMenuView: View {
    let onMyOrders: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            BrightText("Welcome", size: .standout1)
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing8x)

            item(image: ImageNames.myOrdersV5, title: "My Orders", action: onMyOrders)

            Spacer(minLength: .spacing0x)
        }
        .padding(.horizontal, .spacing3x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.defaultBackground.ignoresSafeArea())
    }

    private func item(image: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: .spacing2x) {
                Image(image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.primary)
                    .frame(width: Constants.iconSize)

                BrightText(title, size: .subheading2, color: .semiLightTextColor)

                Spacer(minLength: .spacing0x)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private enum Constants {
        static let iconSize: CGFloat = 22
    }
}

#Preview {
    SideMenuView {}
}
