//
//  ExerciseDevicesSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 20/8/2026.
//

import SwiftUI

// Which devices a session runs on, and what else is feeding it readings.
struct ExerciseDevicesSheet: View {
    @Binding var source: ExerciseSessionSource

    // Demo only: the real screen watches for anything paired that reports heart
    // rate, and shows the detecting row until something answers.
    var devices: [ExerciseConnectedDevice] = ExerciseConnectedDevice.demo

    var body: some View {
        BrightPageView(
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultBackground,
            toolbar: {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: "Devices", file: #file)
                }
            },
            content: { content }
        )
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing4x) {
                sourceSection

                connectedSection
            }
            .padding(.spacing3x)
        }
    }

    // MARK: - Where it runs

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionLabel("Start session on:", symbol: "play.circle", tint: .textColor)

            VStack(spacing: .spacing0x) {
                ForEach(Array(ExerciseSessionSource.allCases.enumerated()), id: \.element.id) { index, option in
                    if index != 0 {
                        BrightDivider()
                    }

                    sourceRow(option)
                }
            }
            .padding(.horizontal, .spacing3x)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
        }
    }

    private func sourceRow(_ option: ExerciseSessionSource) -> some View {
        Button {
            source = option
        } label: {
            HStack(spacing: .spacing2x) {
                ExerciseDeviceGlyphs(symbols: option.symbols)

                BrightText(option.title, size: .body1, weight: .regular)

                Spacer(minLength: .spacing2x)

                BrightTick(isTicked: option == source)
            }
            .frame(height: Constants.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - What's feeding it

    private var connectedSection: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                sectionLabel(
                    "Connected Devices",
                    symbol: "waveform.path.ecg.rectangle",
                    tint: .defaultRed
                )

                BrightText(
                    "Devices used to measure heart rate and other metrics",
                    size: .body1,
                    color: .lightTextColor
                )
            }

            VStack(spacing: .spacing0x) {
                if devices.isEmpty {
                    detectingRow
                } else {
                    ForEach(Array(devices.enumerated()), id: \.element.id) { index, device in
                        if index != 0 {
                            BrightDivider()
                        }

                        deviceRow(device)
                    }
                }
            }
            .padding(.horizontal, .spacing3x)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
        }
    }

    private func deviceRow(_ device: ExerciseConnectedDevice) -> some View {
        HStack(spacing: .spacing2x) {
            ExerciseDeviceGlyphs(symbols: [device.symbol])

            BrightText(device.name, size: .body1, weight: .regular)

            Spacer(minLength: .spacing2x)

            HStack(spacing: .spacing1x) {
                Image(systemName: "checkmark")
                    .font(.standard(size: .body1, weight: .regular))

                BrightText("Connected", size: .body1, color: .defaultGreen, weight: .regular)
            }
            .foregroundStyle(Color.defaultGreen)
        }
        .frame(height: Constants.rowHeight)
    }

    private var detectingRow: some View {
        HStack(spacing: .spacing2x) {
            ExerciseDeviceGlyphs(symbols: ["dot.radiowaves.left.and.right"])

            BrightText("Detecting device", size: .body1, weight: .regular)

            Spacer(minLength: .spacing2x)
        }
        .frame(height: Constants.rowHeight)
    }

    private func sectionLabel(_ title: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: symbol)
                .font(.standard(size: .standout4, weight: .regular))
                .foregroundStyle(tint)

            BrightText(title, size: .body1, weight: .regular)
        }
    }

    private enum Constants {
        static let rowHeight: CGFloat = 62
    }
}

// A device reads as one glyph, a pairing as both with a plus between them.
struct ExerciseDeviceGlyphs: View {
    let symbols: [String]

    var body: some View {
        HStack(spacing: .spacing05x) {
            ForEach(Array(symbols.enumerated()), id: \.offset) { index, symbol in
                if index != 0 {
                    Image(systemName: "plus")
                        .font(.standard(size: .body2, weight: .light))
                }

                Image(systemName: symbol)
                    .font(.standard(size: .standout4, weight: .light))
            }
        }
        .foregroundStyle(Color.textColor)
    }
}

enum ExerciseSessionSource: String, CaseIterable, Identifiable {
    case phone
    case phoneAndWatch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .phone: "iPhone"
        case .phoneAndWatch: "iPhone & Apple Watch"
        }
    }

    var symbols: [String] {
        switch self {
        case .phone: ["iphone"]
        case .phoneAndWatch: ["iphone", "applewatch"]
        }
    }
}

struct ExerciseConnectedDevice: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String

    static let demo: [ExerciseConnectedDevice] = [
        ExerciseConnectedDevice(name: "Garmin", symbol: "watch.analog"),
        ExerciseConnectedDevice(name: "AirPods", symbol: "airpods"),
    ]
}

#Preview {
    @Previewable @State var source = ExerciseSessionSource.phoneAndWatch

    NavigationStack {
        ExerciseDevicesSheet(source: $source)
    }
}

#Preview("Detecting") {
    @Previewable @State var source = ExerciseSessionSource.phoneAndWatch

    NavigationStack {
        ExerciseDevicesSheet(source: $source, devices: [])
    }
}
