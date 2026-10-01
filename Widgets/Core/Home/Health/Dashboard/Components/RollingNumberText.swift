//
//  RollingNumberText.swift
//  Widgets
//
//  Created by Zoe Friedman on 1/2/2024.
//

import SwiftUI

struct RollingNumberText: View {
    let value: Int
    let size: FontSizes
    let color: Color

    @State private var displayed: Int = 0

    var body: some View {
        ZStack(alignment: .leading) {
            // Invisible sizer so the frame is locked to the final value's width.
            BrightText(
                value.withCommas,
                size: size,
                color: color,
                kerning: .mediumKerning
            )
            .hidden()

            BrightText(
                displayed.withCommas,
                size: size,
                color: color,
                kerning: .mediumKerning
            )
            .contentTransition(.numericText(value: Double(displayed)))
        }
        .onAppear {
            displayed = rollStart(for: value)
            withAnimation(.brightChartReveal) { displayed = value }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.brightChartReveal) { displayed = newValue }
        }
    }

    private func rollStart(for target: Int) -> Int {
        guard target > 0 else { return 0 }
        let digits = Set(String(target))
        return (1...9).first { !digits.contains(Character("\($0)")) } ?? 0
    }
}


struct RollingDecimalText: View {
    let value: Double
    let format: String
    let size: FontSizes
    let color: Color
    var weight: Font.Weight = .light

    @State private var displayed: Double = 0

    var body: some View {
        ZStack(alignment: .leading) {
            BrightText(
                String(format: format, value),
                size: size,
                color: color,
                weight: weight,
                kerning: .mediumKerning
            )
            .hidden()

            BrightText(
                String(format: format, displayed),
                size: size,
                color: color,
                weight: weight,
                kerning: .mediumKerning
            )
            .contentTransition(.numericText())
        }
        .onAppear {
            displayed = 0
            withAnimation(.brightChartReveal) { displayed = value }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.brightChartReveal) { displayed = newValue }
        }
    }
}
