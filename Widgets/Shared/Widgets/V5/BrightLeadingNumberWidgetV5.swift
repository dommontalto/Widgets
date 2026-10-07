//
//  BrightLeadingNumberWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

// A single latest reading, large in the bottom corner. Small and medium only.
struct BrightLeadingNumberWidgetV5: View {
    let appearance: BrightWidgetAppearanceV5
    let value: Double
    let latest: Date

    private var title: String { appearance.title }
    private var systemImage: String { appearance.systemImage }
    private var tint: Color { appearance.tint }
    private var unit: String? { appearance.unit }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            header
                .background(Color.red.opacity(.veryLowOpacity)) // DEBUG

            Spacer(minLength: .spacing0x)
                .background(Color.blue.opacity(.veryLowOpacity)) // DEBUG

            reading
                .background(Color.yellow.opacity(.veryLowOpacity)) // DEBUG
        }
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(display) \(unit ?? "")")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing05x) {
                Image(systemName: systemImage)
                    .font(.standard(size: .subheading, weight: .light))
                    .foregroundStyle(tint)

                BrightText(title, size: .body1, weight: .regular)
            }
            .lineLimit(1)

            BrightText("Latest: \(latest.formatted(.brightTime))", size: .body2, color: .lightTextColor)
        }
    }

    private var reading: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            BrightText(display, size: .huge)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.brightEaseInOut, value: display)

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
        Int(value.rounded()).formatted()
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
