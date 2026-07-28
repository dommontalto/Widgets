//
//  BrightTag.swift
//  Widgets
//
//  Created by Dom Montalto on 25/3/2026.
//

import SwiftUI

struct BrightTag: View {
    let title: String
    let systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacing1x) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: Constants.imageSize))
                        .foregroundStyle(isSelected ? Color.textColor : Color.lightTextColor)
                }
                BrightText(
                    title,
                    size: .body1,
                    color: isSelected ? .textColor : .lightTextColor
                )
            }
            .padding(.horizontal, .spacing2x)
            .frame(height: .spacing5x)
        }
        .buttonStyle(.plain)
        .modifier(GlassEffect(shape: .capsule))
        .opacity(isSelected ? 1 : .semiLowOpacity)
    }

    private enum Constants {
        static let imageSize: CGFloat = 17
    }
}
