//
//  LighthouseMenuView.swift
//  Widgets
//
//  Created by Dom Montalto on 10/9/2026.
//

import SwiftUI

// The page beside the chat: the model in use, check-ins and configurations,
// then the chats that came before, with settings tucked in the bottom corner.
struct LighthouseMenuView: View {
    let model: LighthouseModel
    let onSwitchModel: () -> Void
    let onCheckIns: () -> Void
    let onConfigurations: () -> Void
    let onSettings: () -> Void
    let onNewChat: () -> Void

    @State private var historySort = HistorySort.newest

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
            shortcutRow(symbol: "rectangle.3.group.fill", title: Constants.configurationsTitle, action: onConfigurations)
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

                sortMenu
            }
            .frame(height: Constants.rowHeight)

            BrightDivider()

            ForEach(sortedHistory) { entry in
                historyRow(entry)
            }
        }
        .animation(.brightSnappy, value: historySort)
        .padding(.horizontal, .spacing1x)
        .padding(.top, .spacing2x)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(HistorySort.allCases) { sort in
                Button {
                    historySort = sort
                } label: {
                    Label {
                        Text(sort.title)
                    } icon: {
                        if sort == historySort {
                            Image(systemName: "checkmark")
                        } else {
                            Image(systemName: sort.symbol)
                        }
                    }
                }
            }
        } label: {
            BrightRoundButton(systemImage: "line.3.horizontal.decrease", size: .small) {}
                .allowsHitTesting(false)
        }
    }

    // The demo list is already newest first, so that order is the source
    // and the alphabetical one is derived from it.
    private var sortedHistory: [LighthouseHistoryEntry] {
        switch historySort {
        case .newest:
            LighthouseDemo.history
        case .alphabetical:
            LighthouseDemo.history.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }
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
            BrightPillButton(
                Constants.newChatTitle,
                systemImage: "bubble.left",
                buttonSize: .large,
                onTapCallback: onNewChat
            )

            Spacer()

            BrightRoundButton(systemImage: "gear", size: .large, onTapCallback: onSettings)
        }
        .padding(.horizontal, .spacing3x)
        .padding(.bottom, .spacing2x)
    }

    private enum HistorySort: CaseIterable, Identifiable {
        case newest
        case alphabetical

        var id: Self { self }

        var title: String {
            switch self {
            case .newest: "Newest"
            case .alphabetical: "Alphabetical"
            }
        }

        var symbol: String {
            switch self {
            case .newest: "clock"
            case .alphabetical: "textformat.abc"
            }
        }
    }

    private enum Constants {
        static let switchTitle = "Switch"
        static let checkInTitle = "Check in"
        static let configurationsTitle = "Configurations"
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
                onConfigurations: {},
                onSettings: {},
                onNewChat: {}
            )
            .background { LighthouseChatBackground() }
        }
}
