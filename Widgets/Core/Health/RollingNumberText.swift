//
//  RollingNumberText.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

struct RollingNumberText: View {
    let value: Int
    let size: FontSizes
    let color: Color

    @Environment(\.lighthouseRampNumbersFromZero) private var rampFromZero
    // Holds the ramp at zero until the widget is loaded in.
    @Environment(\.lighthouseLoadIn) private var loadIn

    @State private var displayed: Int = 0
    @State private var rampValue: Double = 0

    var body: some View {
        ZStack(alignment: .leading) {
            // Invisible sizer so the frame is locked to the final value's width.
            BrightText(value.withCommas, size: size, color: color, kerning: .mediumKerning)
                .monospacedDigit()
                .hidden()

            if rampFromZero {
                CountingNumberText(number: rampValue, size: size, color: color)
            } else {
                BrightText(displayed.withCommas, size: size, color: color, kerning: .mediumKerning)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(displayed)))
            }
        }
        .onAppear {
            if rampFromZero {
                // Reflect the current load state instantly so a LazyVStack
                // remount lands at the right value without replaying.
                rampValue = loadIn ? Double(value) : 0
            } else {
                displayed = rollStart(for: value)
                withAnimation(.brightChartReveal) { displayed = value }
            }
        }
        // The load-in moment: count up from zero to the value, once.
        .onChange(of: loadIn) { _, now in
            guard rampFromZero, now else { return }
            rampValue = 0
            withAnimation(.easeOut(duration: 1.2)) { rampValue = Double(value) }
        }
        .onChange(of: value) { _, newValue in
            if rampFromZero {
                rampValue = loadIn ? Double(newValue) : 0
            } else {
                withAnimation(.brightChartReveal) { displayed = newValue }
            }
        }
    }

    // Start the roll on a digit the target doesn't contain so every glyph visibly changes.
    private func rollStart(for target: Int) -> Int {
        guard target > 0 else { return 0 }
        let digits = Set(String(target))
        return (1 ... 9).first { !digits.contains(Character("\($0)")) } ?? 0
    }
}

private struct CountingNumberText: View {
    let number: Double
    let size: FontSizes
    let color: Color

    var body: some View {
        BrightText(Int(number).withCommas, size: size, color: color, kerning: .mediumKerning)
            .monospacedDigit()
            .hidden()
            .modifier(RollingCountEffect(number: number, size: size, color: color))
    }
}

// Animatable so SwiftUI interpolates the number itself rather than cross-fading text.
private struct RollingCountEffect: ViewModifier, Animatable {
    var number: Double
    let size: FontSizes
    let color: Color

    var animatableData: Double {
        get { number }
        set { number = newValue }
    }

    func body(content: Content) -> some View {
        content.overlay(alignment: .leading) {
            BrightText(Int(number).withCommas, size: size, color: color, kerning: .mediumKerning)
                .monospacedDigit()
                .fixedSize()
        }
    }
}
