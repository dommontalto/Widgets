//
//  BrightLeadingNumberWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

// A single latest reading, large in the bottom corner. Small and medium only.
struct BrightLeadingNumberWidgetV5: View {
    struct Detail: Hashable {
        let label: String
        let value: String
    }

    let appearance: BrightWidgetAppearanceV5
    let value: Double
    let latest: Date
    var details: [Detail] = []
    var allowsSelection = true

    private var title: String { appearance.title }
    private var systemImage: String { appearance.systemImage }
    private var tint: Color { appearance.tint }
    private var unit: String? { appearance.unit }

    // The number rolls up from zero the first time the widget shows.
    @State private var isRevealed = false
    @State private var touch: UnitPoint?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            header
                .brightDebugBackgroundV5(.red)

            ZStack(alignment: .topLeading) {
                Color.clear

                if isHeld {
                    detailList
                        .transition(.opacity)
                }
            }
            .frame(maxHeight: .infinity)
            .brightDebugBackgroundV5(.blue)

            reading
                .brightDebugBackgroundV5(.yellow)
        }
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay {
            if allowsSelection && !details.isEmpty {
                BrightWidgetTouchLayerV5(touch: $touch)
            }
        }
        .animation(.brightEaseInOut, value: isHeld)
        .brightHapticV5(.light, trigger: isHeld)
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .brightRevealV5($isRevealed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(display) \(unit ?? "")")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                BrightWidgetIconV5(systemImage: systemImage, style: appearance.iconStyle)

                BrightText(title, size: .body1, weight: .regular)
            }
            .lineLimit(1)

            BrightText("Latest: \(latest.formatted(.brightTime))", size: .body2, color: .lightTextColor)
        }
    }

    private var reading: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            BrightText(isRevealed ? display : display.zeroedDigits, size: .huge)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.brightBouncy, value: display)

            if let unit {
                BrightText(unit, size: .body3, color: .lightTextColor)
            }
        }
        .lineLimit(1)
        // Digits never use the room every line keeps below its baseline, so
        // it's pulled into the padding rather than lifting the number.
        .padding(.bottom, Font.standardUIFont(size: .huge, weight: .light)?.descender ?? 0)
    }

    private var display: String {
        appearance.format(value)
    }
}

extension BrightLeadingNumberWidgetV5 {
    // MARK: - Holding

    private var isHeld: Bool {
        touch != nil && !details.isEmpty
    }

    private var detailList: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            ForEach(details, id: \.self) { detail in
                HStack(spacing: .spacing1x) {
                    BrightText(detail.label, size: .body3, color: .lightTextColor)

                    Spacer(minLength: .spacing1x)

                    BrightText(detail.value, size: .body3, weight: .regular)
                        .monospacedDigit()
                }
                .lineLimit(1)
            }
        }
        .padding(.top, .spacing2x)
    }
}

#Preview {
    VStack(spacing: .spacing205x) {
        BrightLeadingNumberWidgetV5(
            appearance: BrightWidgetAppearanceV5(title: "Steps", systemImage: "shoeprints.fill", tint: .defaultOrange),
            value: 12_228,
            latest: .now
        )
        .frame(width: 174, height: 174)

        BrightLeadingNumberWidgetV5(
            appearance: BrightWidgetAppearanceV5(title: "Heart Rate", systemImage: "heart.fill", tint: .defaultRed, unit: "BPM"),
            value: 80,
            latest: .now
        )
        .frame(width: 363, height: 174)
    }
    .padding(.spacing205x)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultBackground)
}
