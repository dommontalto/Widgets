//
//  ExerciseCompleteExertionWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

struct ExerciseCompleteExertionWidget: View {
    let exertion: ExerciseCompleteExertion

    // Set to make each peak open the exercise it was logged against.
    var onSelectExercise: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            average

            BrightDivider()
                .padding(.top, .spacing3x)

            BrightText("Peak RPE", size: .body1, weight: .regular)
                .padding(.top, .spacing3x)

            ForEach(Array(exertion.peaks.enumerated()), id: \.element.id) { index, peak in
                if index != 0 {
                    BrightDivider()
                }

                peakRow(peak)
                    .padding(.top, .spacing2x)
                    .padding(
                        .bottom,
                        index == exertion.peaks.count - 1 ? .spacing0x : .spacing2x
                    )
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    private var average: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("RPE AVG", size: .body1, weight: .regular)

            HStack(spacing: .spacing2x) {
                BrightText(String(exertion.average), size: .huge)
                    .monospacedDigit()

                BrightVerticalDivider(height: Constants.ruleHeight)

                BrightText(exertion.label, size: .body1, color: .semiLightTextColor, weight: .regular)

                Spacer(minLength: .spacing2x)

                gauge
            }
        }
    }

    // The scale runs cool to hot and grows as it climbs, so the height of the
    // wedge under the marker reads as the effort as much as its colour does.
    private var gauge: some View {
        ExerciseCompleteGaugeWedge()
            .fill(
                LinearGradient(
                    colors: [.defaultSkyBlueCyan, .defaultGreen, .defaultYellow, .defaultOrange, .defaultRed],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: Constants.gaugeWidth, height: Constants.gaugeHeight)
            .overlay(alignment: .leading) { marker }
    }

    // The bar carries the card's own colour around it, so it cuts the wedge in
    // two rather than sitting on top of an unbroken gradient.
    private var marker: some View {
        Capsule()
            .fill(Color.textColor)
            .frame(width: Constants.markerWidth, height: Constants.markerHeight)
            .padding(Constants.markerBorder)
            .background(Color.defaultSheetModalCards)
            .offset(x: markerOffset)
    }

    private var markerOffset: CGFloat {
        let fraction = min(1, max(0, Double(exertion.average) / Constants.rpeScale))
        let leading = Constants.gaugeWidth * fraction - Constants.markerBorder
        let widest = Constants.gaugeWidth - Constants.markerWidth - (Constants.markerBorder * 2)
        return min(max(leading, 0), widest)
    }

    @ViewBuilder
    private func peakRow(_ peak: ExerciseCompletePeak) -> some View {
        if let onSelectExercise {
            Button { onSelectExercise(peak.name) } label: { peakContent(peak) }
                .buttonStyle(.plain)
        } else {
            peakContent(peak)
        }
    }

    private func peakContent(_ peak: ExerciseCompletePeak) -> some View {
        HStack(spacing: .spacing2x) {
            thumbnail(for: peak.name)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(peak.name, size: .body1, color: .semiLightTextColor)
                BrightText(peak.detail, size: .body1, color: .textColor.opacity(.semiLowOpacity))
            }

            Spacer(minLength: .spacing2x)

            BrightText("RPE \(peak.rpe)", size: .body1, color: .defaultRed)
                .monospacedDigit()
                .padding(.horizontal, .spacing1x)
                .frame(height: Constants.tagHeight)
                .background(
                    Capsule().strokeBorder(
                        Color.defaultRed.opacity(.veryLowOpacity),
                        lineWidth: 1
                    )
                )
        }
        .contentShape(Rectangle())
    }

    // Drawn the way the library lists an exercise: the glyph on its own, no
    // tile behind it.
    private func thumbnail(for exercise: String) -> some View {
        let symbol = ExerciseDemoLibrary.exercise(named: exercise)?.symbol
            ?? ExerciseDemoLibrary.type(of: exercise).symbol

        return Image(systemName: symbol)
            .font(.standard(size: .standout3, weight: .light))
            .foregroundStyle(Color.lightTextColor)
            .frame(width: Constants.thumbWidth)
    }

    private enum Constants {
        static let ruleHeight: CGFloat = 30
        static let gaugeWidth: CGFloat = 95
        static let gaugeHeight: CGFloat = 23
        static let markerWidth: CGFloat = 3
        // Stands a touch proud of the wedge at either end.
        static let markerHeight: CGFloat = 25
        static let markerBorder: CGFloat = 2
        static let rpeScale: Double = 10
        static let thumbWidth: CGFloat = 40
        static let tagHeight: CGFloat = 30
    }
}

// A wedge that runs flat along the bottom and climbs from a sliver on the left
// to its full height on the right, rounded at both ends.
struct ExerciseCompleteGaugeWedge: Shape {
    // Height of the leading edge as a share of the trailing edge.
    var leadingRatio: CGFloat = 0.5

    func path(in rect: CGRect) -> Path {
        let leadingHeight = rect.height * leadingRatio
        let leadingRadius = leadingHeight / 2
        let trailingRadius = rect.height * Constants.trailingRadiusRatio

        let topLeading = CGPoint(x: rect.minX, y: rect.maxY - leadingHeight)
        let topTrailing = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomTrailing = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeading = CGPoint(x: rect.minX, y: rect.maxY)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - leadingRadius))
        path.addArc(tangent1End: topLeading, tangent2End: topTrailing, radius: leadingRadius)
        path.addArc(tangent1End: topTrailing, tangent2End: bottomTrailing, radius: trailingRadius)
        path.addArc(tangent1End: bottomTrailing, tangent2End: bottomLeading, radius: trailingRadius)
        path.addArc(tangent1End: bottomLeading, tangent2End: topLeading, radius: leadingRadius)
        path.closeSubpath()
        return path
    }

    private enum Constants {
        static let trailingRadiusRatio: CGFloat = 0.2
    }
}

#Preview {
    ExerciseWidgetSection(icon: .symbol("scope"), title: "Exertion breakdown") {
        ExerciseCompleteExertionWidget(exertion: ExerciseDemoComplete.strength.exertion!)
    }
        .padding(.spacing3x)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.defaultSheetBackground.ignoresSafeArea())
}
