//
//  LighthouseSettingsSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 16/9/2026.
//

import SwiftUI

// Lighthouse's own settings: how much of the week's allowance has gone, the
// whisper mode switches, and what it may read from the rest of the app.
struct LighthouseSettingsSheet: View {
    @State private var defaultsToWhisper = false
    @State private var usesWhisperContext = false
    @State private var sharesCycleData = false
    @State private var chatHistory = ChatHistory.hour

    var body: some View {
        BrightPageSheetView(
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: .spacing3x) {
                        header

                        section(Constants.limitsTitle) {
                            usageCard
                        }

                        section(Constants.whisperTitle) {
                            toggleCard(
                                Constants.defaultWhisperTitle,
                                detail: Constants.defaultWhisperDetail,
                                isOn: $defaultsToWhisper
                            )
                            toggleCard(
                                Constants.whisperContextTitle,
                                detail: Constants.whisperContextDetail,
                                isOn: $usesWhisperContext
                            )
                            historyCard
                        }

                        section(Constants.accessTitle) {
                            toggleCard(
                                Constants.cycleDataTitle,
                                detail: Constants.cycleDataDetail,
                                isOn: $sharesCycleData
                            )
                        }

                        actions
                    }
                    .padding(.top, .spacing2x)
                    .padding(.bottom, .spacing4x)
                }
            }
        )
    }

    private var header: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "gear")
                .font(.standard(size: .standout2, weight: .light))
                .foregroundStyle(Color.textColor)

            BrightText(Constants.title, size: .standout3)
        }
        .padding(.horizontal, .spacing2x)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(title, size: .body1, color: .semiLightTextColor, weight: .regular)
                .padding(.horizontal, .spacing2x)

            content()
        }
    }

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                BrightText("\(Constants.usedPercent)", size: .standout1)
                    .monospacedDigit()

                BrightText(Constants.usedLabel, size: .body1, color: .lightTextColor)
            }

            usageBar

            BrightText(Constants.resetsLabel, size: .body1, color: .lightTextColor)
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    private var usageBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: .cornerRadius8)
                    .fill(Color.textColor.opacity(.ultraLowOpacity))

                RoundedRectangle(cornerRadius: .cornerRadius8)
                    .fill(Color.defaultGreen)
                    .frame(width: proxy.size.width * Double(Constants.usedPercent) / 100)
            }
        }
        .frame(height: Constants.barHeight)
    }

    private func toggleCard(_ title: String, detail: String, isOn: Binding<Bool>) -> some View {
        card(title, detail: detail) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.defaultGreen)
                .brightHaptic(.light, trigger: isOn.wrappedValue)
        }
    }

    private var historyCard: some View {
        card(Constants.historyTitle, detail: Constants.historyDetail) {
            Menu {
                ForEach(ChatHistory.allCases) { option in
                    Button {
                        chatHistory = option
                    } label: {
                        Label {
                            Text(option.title)
                        } icon: {
                            if option == chatHistory {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                BrightPillButton(chatHistory.title, buttonSize: .small) {}
                    .allowsHitTesting(false)
            }
            .brightHaptic(.light, trigger: chatHistory)
        }
    }

    private func card<Accessory: View>(
        _ title: String,
        detail: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(alignment: .top, spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing1x) {
                BrightText(title, size: .body1)

                BrightText(detail, size: .body1, color: .lightTextColor)
            }

            Spacer(minLength: .spacing2x)

            accessory()
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    private var actions: some View {
        HStack(spacing: .spacing2x) {
            BrightPillButton(
                Constants.deleteChatsTitle,
                systemImage: "bubble",
                textColor: .defaultRed,
                buttonSize: .large
            ) {}

            BrightPillButton(Constants.resetTitle, buttonSize: .large) {}
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .spacing2x)
    }

    private enum ChatHistory: CaseIterable, Identifiable {
        case hour
        case day
        case week
        case forever

        var id: Self { self }

        var title: String {
            switch self {
            case .hour: "1 Hour"
            case .day: "24 Hours"
            case .week: "7 Days"
            case .forever: "Forever"
            }
        }
    }

    private enum Constants {
        static let title = "Settings"
        static let limitsTitle = "Weekly Limits"
        static let usedPercent = 34
        static let usedLabel = "% used"
        static let resetsLabel = "Usage resets 21 Sep, 10 AM"
        static let barHeight: CGFloat = 24
        static let whisperTitle = "Whisper Mode"
        static let defaultWhisperTitle = "Default to Whisper Mode"
        static let defaultWhisperDetail = "Always open new chats in whisper mode."
        static let whisperContextTitle = "Whisper Context"
        static let whisperContextDetail = "Use your past chat memories in whisper mode."
        static let historyTitle = "Chat history"
        static let historyDetail = "How long do you want your whisper chats to remain accessible?"
        static let accessTitle = "Lighthouse Data Access"
        static let cycleDataTitle = "Menstrual Cycle Data"
        static let cycleDataDetail = "Allow access to Menstrual cycle logs and data."
        static let deleteChatsTitle = "Delete Chats"
        static let resetTitle = "Reset Lighthouse"
    }
}

#Preview {
    LighthouseSettingsSheet()
}
