//
//  BrightRulerPicker.swift
//  Widgets
//
//  Created by Dom Montalto on 21/8/2026.
//

import SwiftUI

// A ruler dragged under a fixed centre: a fine tick per step, a heavier one on
// the majors, and the picked step drawn solid. Ported from the cycle-tracking
// onboarding ruler in the Bright iOS app.
struct BrightRulerPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var majorEvery = 10
    // Spell the majors out under the rail when the steps need naming.
    var showsLabels = false

    @State private var tempValue = 0
    @State private var dragOffset: CGFloat = 0
    @State private var internalValue = 0

    var body: some View {
        GeometryReader { geo in
            let center = geo.size.width / 2

            ZStack {
                ForEach(Array(range), id: \.self) { tick in
                    let x = center + CGFloat(tick - internalValue) * Constants.stepWidth + dragOffset

                    tickColumn(tick)
                        .position(x: x, y: geo.size.height / 2)
                }
            }
            .contentShape(Rectangle())
            .gesture(drag)
        }
        .mask(edgeFade)
        .onAppear {
            internalValue = value
            tempValue = value
        }
    }

    // MARK: - Ticks

    private func tickColumn(_ tick: Int) -> some View {
        VStack(spacing: .spacing0x) {
            tickMark(tick)

            if showsLabels {
                BrightText(
                    "\(tick)",
                    size: .body1,
                    color: tick.isMultiple(of: majorEvery) ? .semiLightTextColor : .clear
                )
                .monospacedDigit()
                // Padding rather than an offset, so the column's height counts
                // the label and the edge-fade mask can't slice its bottom off.
                .padding(.top, Constants.labelGap)
            }
        }
    }

    private func tickMark(_ tick: Int) -> some View {
        let isPicked = tick == tempValue
        let isMajor = tick.isMultiple(of: majorEvery)

        return RoundedRectangle(cornerRadius: Constants.tickRadius)
            .fill(tickColor(isPicked: isPicked, isMajor: isMajor))
            .frame(
                width: isPicked || isMajor ? Constants.majorTickWidth : Constants.minorTickWidth,
                height: isPicked || isMajor ? Constants.majorTickHeight : Constants.minorTickHeight
            )
            .frame(height: Constants.majorTickHeight, alignment: .top)
    }

    private func tickColor(isPicked: Bool, isMajor: Bool) -> Color {
        if isPicked { return .textColor }
        return isMajor
            ? Color.textColor.opacity(.veryLowOpacity)
            : Color.semiLightTextColor.opacity(.semiLowOpacity)
    }

    // The rail runs to the screen edges, so its ends dissolve rather than cut.
    private var edgeFade: some View {
        HStack(spacing: .spacing0x) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                .frame(width: Constants.edgeFade)

            Color.black

            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: Constants.edgeFade)
        }
    }

    // MARK: - Drag

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                withAnimation(.brightSpring) {
                    let offsetSteps = gesture.translation.width / Constants.stepWidth
                    var projected = CGFloat(internalValue) - offsetSteps

                    let lower = CGFloat(range.lowerBound)
                    let upper = CGFloat(range.upperBound)

                    // Past either end the rail keeps moving, but on a log curve
                    // so it reads as resistance rather than range.
                    if projected < lower {
                        let overshoot = lower - projected
                        projected = lower - log(overshoot + 1) * Constants.overshootDamping
                    } else if projected > upper {
                        let overshoot = projected - upper
                        projected = upper + log(overshoot + 1) * Constants.overshootDamping
                    }

                    dragOffset = (CGFloat(internalValue) - projected) * Constants.stepWidth

                    let newTemp = min(max(Int(projected.rounded()), range.lowerBound), range.upperBound)
                    if newTemp != tempValue {
                        BrightHaptic.light.play()
                        tempValue = newTemp
                        value = newTemp
                    }
                }
            }
            .onEnded { gesture in
                let offsetSteps = gesture.translation.width / Constants.stepWidth
                let projected = Int((CGFloat(internalValue) - offsetSteps).rounded())
                let finalValue = min(max(projected, range.lowerBound), range.upperBound)

                withAnimation(.brightSpring) {
                    internalValue = finalValue
                    tempValue = finalValue
                    value = finalValue
                    dragOffset = 0
                }
            }
    }

    private enum Constants {
        static let stepWidth: CGFloat = 12
        static let tickRadius: CGFloat = 3
        static let majorTickWidth: CGFloat = 1.5
        static let minorTickWidth: CGFloat = 0.5
        static let majorTickHeight: CGFloat = 26
        static let minorTickHeight: CGFloat = 14
        static let labelGap: CGFloat = 8
        static let edgeFade: CGFloat = .spacing12x
        static let overshootDamping: CGFloat = 2
    }
}

#Preview {
    @Previewable @State var value = 5

    BrightRulerPicker(value: $value, range: 0 ... 100)
        .frame(height: 60)
}
