//
//  ExerciseSourceView.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

// Where the session records and what each choice buys, opened from the device
// glyphs on a pre-session screen. Defaults to iPhone + Watch whenever the
// watch is reachable; the user can still force iPhone only.
struct ExerciseSourceView: View {
    private enum Constants {
        static let iconWidth: CGFloat = 28
        static let optionGlyphSize: FontSizes = .standout1
        static let deviceGlyphSize: CGFloat = 40
        static let selectedBorder: CGFloat = 2
    }

    @Environment(ExerciseBuilder.self) private var builder

    private var isWatchInSession: Bool {
        builder.source == .phoneAndWatch
    }

    var body: some View {
        BrightPageView(
            title: "Tracking",
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: .spacing4x) {
                        sourceSection

                        outcomeSection

                        optionsSection

                        devicesSection
                    }
                    .padding(.spacing3x)
                }
            }
        )
        .brightHaptic(.light, trigger: builder.source)
        .animation(.brightSnappy, value: builder.source)
    }

    // MARK: - Source

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionTitle("Start session on")

            HStack(spacing: .spacing2x) {
                sourceOption(
                    .phone,
                    caption: "Sparse heart rate, GPS from your phone"
                )

                sourceOption(
                    .phoneAndWatch,
                    caption: ExerciseDemoDevices.isWatchReachable
                        ? "\(ExerciseDemoDevices.pairedWatch.name) connected"
                        : "Watch not reachable"
                )
                .disabled(!ExerciseDemoDevices.isWatchReachable)
                .opacity(ExerciseDemoDevices.isWatchReachable ? 1 : .mediumOpacity)
            }

            BrightText(
                "Picks iPhone + Watch whenever your watch is reachable. Locked once a leg starts.",
                size: .body4,
                color: .lightTextColor
            )
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sourceOption(_ source: ExerciseSessionSource, caption: String) -> some View {
        let isSelected = builder.source == source
        return Button {
            builder.source = source
        } label: {
            VStack(alignment: .leading, spacing: .spacing105x) {
                HStack(spacing: .spacing05x) {
                    ForEach(Array(source.symbols.enumerated()), id: \.offset) { index, symbol in
                        if index != 0 {
                            Image(systemName: "plus")
                                .imageScale(.small)
                        }

                        Image(systemName: symbol)
                    }
                }
                .font(.standard(size: Constants.optionGlyphSize, weight: .light))
                .foregroundStyle(Color.textColor)

                Spacer(minLength: .spacing0x)

                BrightText(source.title, size: .body1)

                BrightText(caption, size: .body4, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.spacing2x)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .aspectRatio(1, contentMode: .fit)
            .modifier(CardModifier(color: .defaultCards, cornerRadius: .cardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous)
                    .strokeBorder(Color.defaultGreen, lineWidth: Constants.selectedBorder)
                    .opacity(isSelected ? 1 : 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Outcome

    private var outcomeSection: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionTitle("What you get")

            VStack(spacing: .spacing0x) {
                outcomeRow(
                    symbol: "heart.fill",
                    tint: .defaultRed,
                    title: "Heart rate",
                    value: isWatchInSession ? "Continuous from Watch" : "Every 5–10 min from Health",
                    isLast: false
                )

                outcomeRow(
                    symbol: "location.fill",
                    tint: .defaultSkyBlue,
                    title: "GPS and pace",
                    value: isWatchInSession ? "Watch" : "iPhone",
                    isLast: false
                )

                outcomeRow(
                    symbol: "hand.tap.fill",
                    tint: .defaultYellow,
                    title: "Log sets and pause",
                    value: isWatchInSession ? "Either device" : "iPhone",
                    isLast: false
                )

                outcomeRow(
                    symbol: "iphone.slash",
                    tint: .defaultBrightViolet,
                    title: "Leave the phone behind",
                    value: isWatchInSession ? "Yes" : "No",
                    isLast: true
                )
            }
            .padding(.vertical, .spacing1x)
            .modifier(CardModifier(color: .defaultCards, cornerRadius: .cardCornerRadius))
        }
    }

    private func outcomeRow(symbol: String, tint: Color, title: String, value: String, isLast: Bool) -> some View {
        VStack(spacing: .spacing0x) {
            HStack(spacing: .spacing2x) {
                Image(systemName: symbol)
                    .font(.standard(size: .subheading, weight: .light))
                    .foregroundStyle(tint)
                    .frame(width: Constants.iconWidth)

                BrightText(title, size: .body1)

                Spacer(minLength: .spacing2x)

                BrightText(value, size: .body2, color: .semiLightTextColor)
                    .multilineTextAlignment(.trailing)
                    .contentTransition(.opacity)
            }
            .padding(.horizontal, .spacing3x)
            .padding(.vertical, .spacing2x)

            if !isLast {
                Divider()
                    .padding(.leading, .spacing3x + Constants.iconWidth + .spacing2x)
            }
        }
    }

    // MARK: - Options

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionTitle("Options")

            VStack(spacing: .spacing0x) {
                if isWatchInSession {
                    toggleRow(
                        symbol: "moon.zzz.fill",
                        tint: .defaultBrightViolet,
                        title: "Wake watch quietly",
                        subtitle: "Records in the background with a compact screen",
                        isOn: Bindable(builder).wakesWatchQuietly,
                        isLast: false
                    )
                }

                toggleRow(
                    symbol: "arrow.trianglehead.2.clockwise.rotate.90",
                    tint: .defaultGreen,
                    title: "Remember my choice",
                    subtitle: "Use the same devices and options next session",
                    isOn: Bindable(builder).remembersSource,
                    isLast: true
                )
            }
            .padding(.vertical, .spacing1x)
            .modifier(CardModifier(color: .defaultCards, cornerRadius: .cardCornerRadius))
        }
    }

    private func toggleRow(
        symbol: String,
        tint: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        isLast: Bool
    ) -> some View {
        VStack(spacing: .spacing0x) {
            HStack(spacing: .spacing2x) {
                Image(systemName: symbol)
                    .font(.standard(size: .subheading, weight: .light))
                    .foregroundStyle(tint)
                    .frame(width: Constants.iconWidth)

                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(title, size: .body1)

                    BrightText(subtitle, size: .body4, color: .lightTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: .spacing2x)

                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(Color.defaultGreen)
                    .brightHaptic(.light, trigger: isOn.wrappedValue)
            }
            .padding(.horizontal, .spacing3x)
            .padding(.vertical, .spacing2x)

            if !isLast {
                Divider()
                    .padding(.leading, .spacing3x + Constants.iconWidth + .spacing2x)
            }
        }
    }

    // MARK: - Devices

    private var devicesSection: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionTitle("Devices you've tracked with")

            VStack(spacing: .spacing0x) {
                ForEach(Array(ExerciseDemoDevices.history.enumerated()), id: \.element.id) { index, device in
                    deviceRow(device, isLast: index == ExerciseDemoDevices.history.count - 1)
                }
            }
            .padding(.vertical, .spacing1x)
            .modifier(CardModifier(color: .defaultCards, cornerRadius: .cardCornerRadius))

            BrightText(
                isWatchInSession
                    ? "From Apple Health. Heart rate comes from your Watch while it is in the session."
                    : "From Apple Health. Pick one to read heart rate from while your Watch is out.",
                size: .body4,
                color: .lightTextColor
            )
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func deviceRow(_ device: ExerciseTrackingDevice, isLast: Bool) -> some View {
        let isPickable = device.readsHeartRate && !isWatchInSession
        let isPicked = builder.heartRateDeviceId == device.id
        return VStack(spacing: .spacing0x) {
            Button {
                builder.heartRateDeviceId = isPicked ? nil : device.id
            } label: {
                HStack(spacing: .spacing2x) {
                    Image(systemName: device.kind.symbol)
                        .font(.standard(size: .subheading, weight: .light))
                        .foregroundStyle(device.kind.tint)
                        .frame(width: Constants.deviceGlyphSize, height: Constants.deviceGlyphSize)
                        .background(device.kind.tint.opacity(.ultraLowOpacity), in: Circle())

                    VStack(alignment: .leading, spacing: .spacing05x) {
                        BrightText(device.name, size: .body1)
                            .lineLimit(1)

                        BrightText(deviceSubtitle(device), size: .body4, color: .lightTextColor)
                            .lineLimit(1)
                    }

                    Spacer(minLength: .spacing2x)

                    if isPickable {
                        BrightTick(isTicked: isPicked)
                    } else if !device.readsHeartRate {
                        BrightText("No live HR", size: .body5, color: .lightTextColor)
                    }
                }
                .padding(.horizontal, .spacing3x)
                .padding(.vertical, .spacing2x)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!isPickable)

            if !isLast {
                Divider()
                    .padding(.leading, .spacing3x + Constants.deviceGlyphSize + .spacing2x)
            }
        }
    }

    private func deviceSubtitle(_ device: ExerciseTrackingDevice) -> String {
        let sessions = device.sessionCount == 0
            ? "Daily readings"
            : "\(device.sessionCount) session\(device.sessionCount == 1 ? "" : "s")"
        return "via \(device.sourceApp) · \(sessions) · \(device.lastUsed.formatted(.brightDate))"
    }

    // MARK: - Shared

    private func sectionTitle(_ title: String) -> some View {
        BrightText(title, size: .body3, color: .lightTextColor)
            .textCase(.uppercase)
            .padding(.horizontal, .spacing1x)
    }
}

#Preview {
    NavigationStack {
        ExerciseSourceView()
            .environment(ExerciseBuilder())
    }
}
