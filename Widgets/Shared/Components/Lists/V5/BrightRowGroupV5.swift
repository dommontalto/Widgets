//
//  BrightRowGroupV5.swift
//  Widgets
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var isInBrightRowGroup = false
}

extension ContainerValues {
    @Entry var brightRowHasIcon = false
}

struct BrightRowGroupV5<Content: View>: View {
    let header: String?
    let headerIcon: String?
    let footer: String?
    let color: Color
    let content: Content

    @Environment(\.displayScale) private var displayScale

    init(
        header: String? = nil,
        headerIcon: String? = nil,
        footer: String? = nil,
        color: Color = .defaultCards,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header
        self.headerIcon = headerIcon
        self.footer = footer
        self.color = color
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            if let header {
                HStack(spacing: .spacing1x) {
                    if let headerIcon {
                        Image(headerIcon)
                    }
                    BrightText(header, size: .body1, color: .semiLightTextColor)
                }
                .padding(.leading, .spacing2x)
            }

            VStack(spacing: .spacing0x) {
                Group(subviews: content) { rows in
                    ForEach(rows) { row in
                        row
                        if row.id != rows.last?.id {
                            BrightDividerV5(thickness: 1 / displayScale)
                                .padding(.leading, dividerInset(hasIcon: row.containerValues.brightRowHasIcon))
                                .padding(.trailing, .spacing3x)
                        }
                    }
                }
            }
            .environment(\.isInBrightRowGroup, true)
            .modifier(BrightCardModifierV5(color: color, cornerRadius: .cardCornerRadius))

            if let footer {
                BrightText(footer, size: .body1, color: .lightTextColor)
                    .padding(.horizontal, .spacing2x)
            }
        }
    }

    private func dividerInset(hasIcon: Bool) -> CGFloat {
        hasIcon ? .spacing3x + Constants.rowIconSize + .spacing2x : .spacing3x
    }

    private enum Constants {
        static var rowIconSize: CGFloat { 24 }
    }
}

#Preview {
    @Previewable @State var push = true
    @Previewable @State var email = false
    @Previewable @State var unit = 0

    VStack(spacing: .spacing5x) {
        BrightRowGroupV5(header: "ENERGY") {
            BrightRowV5("Calories", trailing: .tick(unit == 0)) { unit = 0 }
            BrightRowV5("Kilojoules", trailing: .tick(unit == 1)) { unit = 1 }
        }
        BrightRowGroupV5(footer: "We only email about your account and orders.") {
            BrightRowV5("Push Notifications", icon: .symbol("bell"), trailing: .toggle($push))
            BrightRowV5("Email Notifications", icon: .symbol("envelope"), trailing: .toggle($email))
        }
    }
    .padding(.spacing3x)
}
