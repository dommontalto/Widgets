//
//  BrightWidgetTapV5.swift
//  Widgets
//
//  Created by Dom Montalto on 11/11/2026.
//

import SwiftUI

// Opens a widget on a quick tap, anywhere on it including its bars and rings. It runs
// alongside the chart's own hold-to-read rather than on top of it: a plain tap gesture
// over a chart's selection hangs the app. Holding past the press is left to the chart.
private struct BrightWidgetTapV5: ViewModifier {
    let isEnabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        content.simultaneousGesture(gesture, isEnabled: isEnabled)
    }

    private var gesture: some Gesture {
        LongPressGesture(minimumDuration: Constants.maxPressDuration)
            .exclusively(before: TapGesture())
            .onEnded { value in
                guard case .second = value else { return }
                action()
            }
    }

    private enum Constants {
        static let maxPressDuration: Double = 0.3
    }
}

extension View {
    func brightWidgetTapV5(isEnabled: Bool = true, perform action: @escaping () -> Void) -> some View {
        modifier(BrightWidgetTapV5(isEnabled: isEnabled, action: action))
    }
}
