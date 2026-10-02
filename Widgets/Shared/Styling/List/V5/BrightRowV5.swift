//
//  BrightRowV5.swift
//  Widgets
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

enum BrightRowV5Icon {
    case asset(String)
    case symbol(String, tint: Color = .textColor)
    case template(String)
}

enum BrightRowV5Trailing {
    case automatic
    case chevron
    case none
    case tick(Bool)
    case value(String)
    case toggle(Binding<Bool>)
}

struct BrightRowV5<Custom: View>: View {
    let title: String
    let subtitle: String?
    let icon: BrightRowV5Icon?
    let color: Color
    let trailing: BrightRowV5Trailing?
    let action: (() -> Void)?
    let custom: Custom

    @Environment(\.isInBrightRowGroup) private var isGrouped

    init(
        _ title: String,
        subtitle: String? = nil,
        icon: BrightRowV5Icon? = nil,
        color: Color = .defaultCards,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing custom: () -> Custom
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trailing = nil
        self.action = action
        self.custom = custom()
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    row
                }
                .buttonStyle(BrightRowPressStyle(isCapsule: !isGrouped))
            } else {
                row
            }
        }
        .containerValue(\.brightRowHasIcon, icon != nil)
    }

    @ViewBuilder
    private var row: some View {
        if isGrouped {
            content
        } else {
            content
                .modifier(BrightCardModifierV5(color: color, isCapsule: true))
                .contentShape(.dragPreview, Capsule())
                .contentShape(.contextMenuPreview, Capsule())
        }
    }

    private var content: some View {
        HStack(spacing: .spacing2x) {
            if let icon {
                iconView(icon)
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
            }

            VStack(alignment: .leading, spacing: .spacing0x) {
                BrightText(title, size: .body1)
                    .lineLimit(1)
                if let subtitle {
                    BrightText(subtitle, size: .body1, color: .lightTextColor)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: .spacing2x)

            trailingView
        }
        .padding(.horizontal, .spacing3x)
        .frame(height: Constants.height)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func iconView(_ icon: BrightRowV5Icon) -> some View {
        switch icon {
        case let .asset(name):
            Image(name)
                .resizable()
                .scaledToFit()
        case let .symbol(name, tint):
            Image(systemName: name)
                .resizable()
                .scaledToFit()
                .foregroundStyle(tint)
        case let .template(name):
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.textColor)
        }
    }

    @ViewBuilder
    private var trailingView: some View {
        if let trailing {
            standardTrailing(trailing)
        } else {
            custom
        }
    }

    @ViewBuilder
    private func standardTrailing(_ trailing: BrightRowV5Trailing) -> some View {
        switch trailing {
        case .chevron:
            chevron
        case .none, .automatic:
            EmptyView()
        case let .tick(isTicked):
            BrightTickV5(isTicked: isTicked)
        case let .value(value):
            HStack(spacing: .spacing1x) {
                BrightText(value, size: .body1, color: .lightTextColor)
                    .monospacedDigit()
                if action != nil {
                    chevron
                }
            }
        case let .toggle(isOn):
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.defaultBrightGreen)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color(.tertiaryLabel))
    }

    private enum Constants {
        static var height: CGFloat { .rowHeight }
        static var iconSize: CGFloat { 24 }
    }
}

private struct BrightRowPressStyle: ButtonStyle {
    let isCapsule: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                highlight
                    .opacity(configuration.isPressed ? .opaque : 0)
                    .allowsHitTesting(false)
            }
            .animation(configuration.isPressed ? nil : .easeOut(duration: 0.25), value: configuration.isPressed)
    }

    @ViewBuilder
    private var highlight: some View {
        if isCapsule {
            Capsule(style: .continuous).fill(Color.textColor.opacity(.ultraLowOpacity))
        } else {
            Rectangle().fill(Color.textColor.opacity(.ultraLowOpacity))
        }
    }
}

extension BrightRowV5 where Custom == EmptyView {
    init(
        _ title: String,
        subtitle: String? = nil,
        icon: BrightRowV5Icon? = nil,
        color: Color = .defaultCards,
        trailing: BrightRowV5Trailing = .automatic,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        if case .automatic = trailing {
            self.trailing = action == nil ? BrightRowV5Trailing.none : .chevron
        } else {
            self.trailing = trailing
        }
        self.action = action
        self.custom = EmptyView()
    }
}

#Preview {
    @Previewable @State var isOn = true

    VStack(spacing: .spacing2x) {
        BrightRowV5("Activity", icon: .symbol("flame.fill", tint: .defaultOrange)) {}
        BrightRowV5("Lighthouse", icon: .symbol("sun.horizon"), trailing: {
            Toggle("", isOn: $isOn)
                .labelsHidden()
        })
        BrightRowV5("Heavy", icon: .symbol("drop.fill", tint: .defaultRed), trailing: .tick(true)) {}
        BrightRowV5("Calorie goal", icon: .symbol("flame"), trailing: .value("2,300")) {}
        BrightRowV5("Save meal", subtitle: "Add it to your saved meals", icon: .symbol("bookmark"), trailing: .toggle($isOn))
        BrightRowV5("Reset to default", icon: .symbol("arrow.counterclockwise", tint: .defaultRed), trailing: .none) {}
    }
    .padding(.spacing3x)
}
