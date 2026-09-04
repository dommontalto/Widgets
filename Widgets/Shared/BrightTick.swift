//
//  BrightTick.swift
//  Bright
//
//  Created by Dom Montalto on 8/7/2026.
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

enum BrightTickStyle {
    case empty
    case plus

    var symbol: String {
        switch self {
        case .empty: "circle"
        case .plus: "plus.circle"
        }
    }

    var tint: Color {
        switch self {
        case .empty: .textColor.opacity(.ultraLowOpacity)
        case .plus: .defaultSkyBlue
        }
    }
}

struct BrightTick: View {
    var isTicked: Bool
    var style: BrightTickStyle = .empty
    var tickTint: Color = .defaultGreen

    var body: some View {
        Image(systemName: isTicked ? "checkmark.circle.fill" : style.symbol)
            .font(.standardSFPro(size: .standout2, weight: .light))
            .foregroundStyle(isTicked ? tickTint : style.tint)
            .contentTransition(.symbolEffect(.replace))
            .brightHaptic(trigger: isTicked) { _, isTicked in
                isTicked ? .success : .light
            }
    }
}

struct BrightCross: View {
    var isCrossed: Bool
    var style: BrightTickStyle = .empty
    var crossTint: Color = .defaultRed

    var body: some View {
        Image(systemName: isCrossed ? "xmark.circle.fill" : style.symbol)
            .font(.standardSFPro(size: .standout2, weight: .light))
            .foregroundStyle(isCrossed ? crossTint : style.tint)
            .contentTransition(.symbolEffect(.replace))
            .brightHaptic(trigger: isCrossed) { _, isCrossed in
                isCrossed ? .medium : .light
            }
    }
}

#Preview {
    @Previewable @State var isEmptyTicked = false
    @Previewable @State var isPlusTicked = false
    @Previewable @State var isCrossed = false

    VStack(spacing: .spacing4x) {
        Button {
            isEmptyTicked.toggle()
        } label: {
            BrightTick(isTicked: isEmptyTicked)
        }

        Button {
            isPlusTicked.toggle()
        } label: {
            BrightTick(isTicked: isPlusTicked, style: .plus)
        }

        Button {
            isCrossed.toggle()
        } label: {
            BrightCross(isCrossed: isCrossed)
        }
    }
    .buttonStyle(.plain)
    .padding()
}
