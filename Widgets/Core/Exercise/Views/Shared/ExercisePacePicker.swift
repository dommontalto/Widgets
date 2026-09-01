//
//  ExercisePacePicker.swift
//  Widgets
//
//  Created by Dom Montalto on 1/9/2026.
//

import SwiftUI

// A pace is two numbers, so it gets wheels rather than a text field: minutes and
// seconds per kilometre, written back as the same 5’30” the rest of the app reads.
struct ExercisePacePicker: View {
    @Binding var pace: String
    var onClose: () -> Void = {}

    @State private var minutes = Constants.defaultMinutes
    @State private var seconds = 0

    var body: some View {
        VStack(spacing: .spacing4x) {
            header

            wheels

            BrightPillButton("Set Pace", color: .defaultGreen, buttonSize: .large) {
                pace = String(format: "%d\u{2019}%02d\u{201D}", minutes, seconds)
                onClose()
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity)
        .onAppear(perform: load)
    }

    private var header: some View {
        HStack(spacing: .spacing2x) {
            HStack(spacing: .spacing105x) {
                Image(systemName: "clock")
                    .font(.standard(size: .standout3, weight: .medium))
                    .foregroundStyle(Color.defaultGreen)

                BrightText("Target Pace", size: .standout1)
            }

            Spacer(minLength: .spacing2x)

            BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)
        }
    }

    private var wheels: some View {
        HStack(spacing: .spacing4x) {
            wheel(selection: $minutes, values: Array(Constants.minuteRange), unit: "min")

            wheel(selection: $seconds, values: Array(stride(from: 0, to: 60, by: Constants.secondStep)), unit: "sec")
        }
        .frame(height: Constants.wheelHeight)
    }

    private func wheel(selection: Binding<Int>, values: [Int], unit: String) -> some View {
        HStack(spacing: .spacing1x) {
            Picker("", selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(String(format: "%02d", value))
                        .font(.standard(size: .standout2, weight: .light))
                        .monospacedDigit()
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(width: Constants.wheelWidth)

            BrightText(unit, size: .body1, color: .semiLightTextColor)
        }
    }

    private func load() {
        let parts = pace.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard let first = parts.first else { return }
        minutes = min(max(first, Constants.minuteRange.lowerBound), Constants.minuteRange.upperBound)
        guard parts.count > 1 else { return }
        seconds = (parts[1] / Constants.secondStep) * Constants.secondStep
    }

    private enum Constants {
        static let minuteRange = 2...20
        static let defaultMinutes = 5
        static let secondStep = 5
        static let wheelHeight: CGFloat = 150
        static let wheelWidth: CGFloat = 76
    }
}

#Preview {
    @Previewable @State var pace = "5\u{2019}30\u{201D}"

    Color.defaultBackground
        .ignoresSafeArea()
        .brightMiniSheet(isPresented: .constant(true)) {
            ExercisePacePicker(pace: $pace)
        }
}
