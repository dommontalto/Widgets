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

#Preview {
    @Previewable @State var isEmptyTicked = false
    @Previewable @State var isPlusTicked = false

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
    }
    .buttonStyle(.plain)
    .padding()
}
