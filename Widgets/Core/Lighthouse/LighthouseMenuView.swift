//
//  LighthouseMenuView.swift
//  Widgets
//
//  Created by Dom Montalto on 10/9/2026.
//

import SwiftUI

// The page beside the chat: the model in use, check-ins and configurations,
// then the chats that came before.
struct LighthouseMenuView: View {
    let model: LighthouseModel
    let onSwitchModel: () -> Void
    let onCheckIns: () -> Void
    let onNewChat: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing3x) {
                modelCard

                shortcuts

                history
            }
            .padding(.horizontal, .spacing3x)
            .padding(.top, .spacing2x)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom, spacing: .spacing0x) {
            bottomBar
        }
    }

    private var modelCard: some View {
        HStack(spacing: .spacing2x) {
            Image(model.tierImageName)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.tierImageSize, height: Constants.tierImageSize)

            BrightText(model.selectedTier().name, size: .heading, color: .semiLightTextColor)

            Spacer(minLength: .spacing2x)

            BrightPillButton(Constants.switchTitle, buttonSize: .small, onTapCallback: onSwitchModel)
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    private var shortcuts: some View {
        VStack(spacing: .spacing0x) {
            shortcutRow(symbol: "person.badge.clock.fill", title: Constants.checkInTitle, action: onCheckIns)
            shortcutRow(symbol: "rectangle.3.group.fill", title: Constants.configurationsTitle) {}
            shortcutRow(
                symbol: "bubble.left.and.bubble.right",
                title: Constants.temporaryChatTitle
            ) {}
        }
        .padding(.horizontal, .spacing1x)
    }

    private func shortcutRow(symbol: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: .spacing0x) {
                HStack(spacing: .spacing2x) {
                    Image(systemName: symbol)
                        .font(.standard(size: .subheading, weight: .regular))
                        .foregroundStyle(Color.textColor)
                        .frame(width: Constants.glyphWidth)

                    BrightText(title, size: .body1)

                    Spacer(minLength: .spacing2x)

                    Image(systemName: "chevron.right")
                        .font(.standard(size: .body1, weight: .medium))
                        .foregroundStyle(Color.lightTextColor)
                }
                .frame(height: Constants.rowHeight)

                BrightDivider()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var history: some View {
        VStack(spacing: .spacing0x) {
            HStack(spacing: .spacing2x) {
                Image(systemName: "clock")
                    .font(.standard(size: .subheading, weight: .regular))
                    .foregroundStyle(Color.textColor)
                    .frame(width: Constants.glyphWidth)

                BrightText(Constants.historyTitle, size: .body1)

                Spacer(minLength: .spacing2x)

                BrightRoundButton(systemImage: "line.3.horizontal.decrease", size: .small) {}
            }
            .frame(height: Constants.rowHeight)

            BrightDivider()

            ForEach(LighthouseDemo.history) { entry in
                historyRow(entry)
            }
        }
        .padding(.horizontal, .spacing1x)
        .padding(.top, .spacing2x)
    }

    private func historyRow(_ entry: LighthouseHistoryEntry) -> some View {
        HStack(spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(entry.title, size: .body1, color: .semiLightTextColor)
                    .lineLimit(1)

                BrightText(entry.when, size: .body1, color: .lightTextColor)
            }

            Spacer(minLength: .spacing2x)

            Menu {
                Button("Rename", systemImage: "pencil") {}

                Button("Delete", systemImage: "trash", role: .destructive) {}
                    .tint(.defaultRed)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.standard(size: .body1, weight: .medium))
                    .foregroundStyle(Color.lightTextColor)
                    .frame(width: BrightButtonSizes.small.rawValue, height: BrightButtonSizes.small.rawValue)
                    .contentShape(Circle())
            }
        }
        .padding(.vertical, .spacing2x)
    }

    private var bottomBar: some View {
        HStack(spacing: .spacing0x) {
            BrightRoundButton(systemImage: "gear", size: .large) {}

            Spacer()

            BrightPillButton(
                Constants.newChatTitle,
                systemImage: "bubble.left",
                buttonSize: .large,
                onTapCallback: onNewChat
            )
        }
        .padding(.horizontal, .spacing3x)
        .padding(.bottom, .spacing2x)
    }

    private enum Constants {
        static let switchTitle = "Switch"
        static let checkInTitle = "Check in"
        static let configurationsTitle = "Configurations"
        static let temporaryChatTitle = "Temporary Chat"
        static let historyTitle = "History"
        static let newChatTitle = "New Chat"
        static let tierImageSize: CGFloat = 40
        static let glyphWidth: CGFloat = 24
        static let rowHeight: CGFloat = 48
    }
}

#Preview {
    Color.defaultBackground
        .ignoresSafeArea()
        .overlay {
            LighthouseMenuView(
                model: .chatGPT,
                onSwitchModel: {},
                onCheckIns: {},
                onNewChat: {}
            )
            .background { LighthouseChatBackground() }
        }
}
