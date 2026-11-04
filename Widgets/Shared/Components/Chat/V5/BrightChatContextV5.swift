//
//  BrightChatContextV5.swift
//  Widgets
//

import SwiftUI

struct BrightChatContextV5: View {
    @State private var isExpanded = false

    var body: some View {
        Button {
            withAnimation(.brightSpring) { isExpanded.toggle() }
        } label: {
            HStack(spacing: .spacing1x) {
                BrightLiveScreenV5(
                    height: isExpanded ? Constants.expandedHeight : Constants.height,
                    cornerRadius: isExpanded ? Constants.expandedCornerRadius : Constants.cornerRadius,
                    borderCornerRadius: isExpanded ? Constants.expandedBorderCornerRadius : Constants.borderCornerRadius
                )

                BrightText(Constants.title, size: .body4, color: .lightTextColor)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .brightHapticV5(.light, trigger: isExpanded)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum Constants {
        static let height: CGFloat = 110
        static let expandedHeight: CGFloat = 260
        static let cornerRadius: CGFloat = 10
        static let expandedCornerRadius: CGFloat = 24
        static let borderCornerRadius: CGFloat = 13
        static let expandedBorderCornerRadius: CGFloat = 27
        static let title = "Context"
    }
}

#Preview {
    BrightChatContextV5()
        .padding(.spacing3x)
        .background(Color.defaultBackground)
}
