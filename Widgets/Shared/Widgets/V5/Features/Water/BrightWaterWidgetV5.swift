//
//  BrightWaterWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 9/10/2026.
//

import Charts
import SwiftUI

// Today's water as a tank filling towards the goal, with rulers either side, the level
// marked across it and the total in the middle. Large adds this week's days below.
//
// Holding shows yesterday's level in its place.
struct BrightWaterWidgetV5: View {
    struct Drink: Identifiable, Hashable {
        let date: Date
        let litres: Double

        var id: Date { date }
    }

    let appearance: BrightWidgetAppearanceV5
    // Today's, oldest first.
    let drinks: [Drink]
    let goal: Double
    let yesterday: Double
    // Monday first, for large.
    var week: [Double?] = []
    let size: BrightWidgetSizeV5
    var allowsSelection = true

    @State private var isHolding = false

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            header

            tank
                .frame(maxHeight: .infinity)

            if size == .large {
                BrightDividerV5()
                    .padding(.horizontal, -.spacing205x)

                BrightThisWeekSectionV5(days: week, tint: appearance.tint) { compact($0) }
                    .padding(.top, .spacing1x)
            }
        }
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .onChange(of: allowsSelection) { _, allows in
            if !allows {
                isHolding = false
            }
        }
        .animation(.brightEaseInOut, value: isHolding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(appearance.title), \(full(level)) of \(full(goal))")
    }

    // MARK: - Header

    // Small stacks the latest drink under the title; medium and large spread it along
    // the top with yesterday's total.
    @ViewBuilder
    private var header: some View {
        if size == .small {
            VStack(alignment: .leading, spacing: .spacing05x) {
                title

                latestText(size: .body2, color: .lightTextColor)
            }
        } else {
            HStack(spacing: .spacing1x) {
                title

                Spacer(minLength: .spacing0x)

                yesterdayText

                Spacer(minLength: .spacing0x)

                latestText(size: .body4, color: .semiLightTextColor)
            }
        }
    }

    private var title: some View {
        HStack(spacing: .spacing05x) {
            Image(systemName: appearance.systemImage)
                .font(.standard(size: .subheading, weight: .light))
                .foregroundStyle(appearance.iconStyle)

            BrightText(appearance.title, size: .body1)
        }
        .lineLimit(1)
    }

    private var yesterdayText: some View {
        BrightText("\(compact(yesterday)) Yesterday", size: .body4, color: appearance.tint.opacity(.mediumOpacity))
            .monospacedDigit()
            .lineLimit(1)
    }

    // The latest drink, "+0.5L, Today, 2:00 PM", or "Yesterday" while held.
    @ViewBuilder
    private func latestText(size: FontSizes, color: Color) -> some View {
        if let text = subtitle {
            BrightText(text, size: size, color: color)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
        }
    }

    private var subtitle: String? {
        if isHolding {
            return "Yesterday"
        }
        return drinks.last.map { "+\(compact($0.litres)), \($0.date.formatted(.brightTimestamp))" }
    }

    // MARK: - Tank

    private var tank: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let levelY = height * (1 - min(level / max(goal, .leastNonzeroMagnitude), 1))

            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [appearance.tint.opacity(.veryLowOpacity), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: height - levelY)
                    .offset(y: levelY)

                HStack(spacing: .spacing0x) {
                    ruler(alignment: .leading)

                    VStack(alignment: .leading, spacing: .spacing0x) {
                        scaleLabel(compact(goal))

                        Spacer(minLength: .spacing0x)

                        scaleLabel("0")
                    }
                    .padding(.leading, .spacing05x)

                    Spacer(minLength: .spacing0x)

                    ruler(alignment: .trailing)
                }

                levelMarker
                    .offset(y: levelY - Constants.markerSize / 2)

                BrightText(full(level), size: size == .small ? .standout1 : .huge, color: appearance.tint, weight: .regular)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .overlay { touchLayer }
        }
    }

    // Ticks down the side, the ends longer, reaching in from the edge.
    private func ruler(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: .spacing0x) {
            ForEach(0 ..< Constants.tickCount, id: \.self) { index in
                if index > 0 {
                    Spacer(minLength: .spacing0x)
                }

                let isEnd = index == 0 || index == Constants.tickCount - 1
                Capsule()
                    .fill(Color.textColor.opacity(isEnd ? .lowOpacity : .veryLowOpacity))
                    .frame(width: isEnd ? Constants.rulerWidth : Constants.rulerWidth / 2, height: Constants.tickHeight)
            }
        }
        .frame(width: Constants.rulerWidth, alignment: Alignment(horizontal: alignment, vertical: .center))
    }

    private func scaleLabel(_ text: String) -> some View {
        BrightText(text, size: .body5, color: .lightTextColor)
            .monospacedDigit()
            .lineLimit(1)
    }

    // A line across the tank at the level, with an arrow pointing in from each side.
    private var levelMarker: some View {
        HStack(spacing: .spacing0x) {
            arrow(pointing: .degrees(90))

            Rectangle()
                .fill(Color.textColor.opacity(.lowOpacity))
                .frame(height: Constants.lineWidth)

            arrow(pointing: .degrees(-90))
        }
        .frame(height: Constants.markerSize)
        .padding(.horizontal, -Constants.markerSize / 2)
    }

    private func arrow(pointing angle: Angle) -> some View {
        Image(systemName: "triangle.fill")
            .font(.standard(size: .body6, weight: .regular))
            .foregroundStyle(Color.textColor)
            .rotationEffect(angle)
            .frame(width: Constants.markerSize, height: Constants.markerSize)
    }

    // MARK: - Holding

    // An empty chart laid over the tank, so holding it uses the same gesture as the charts
    // and the page still scrolls.
    @ViewBuilder
    private var touchLayer: some View {
        if allowsSelection, let first = drinks.first {
            Chart {
                PointMark(x: .value("Time", first.date), y: .value("Floor", 0))
                    .opacity(.zero)
            }
            .chartXScale(domain: first.date ... max(drinks.last?.date ?? first.date, first.date.addingTimeInterval(1)))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartXSelection(value: selection)
        }
    }

    private var selection: Binding<Date?> {
        Binding {
            isHolding ? drinks.first?.date : nil
        } set: { date in
            guard (date != nil) != isHolding else { return }
            isHolding = date != nil
            if isHolding {
                BrightHaptic.light.play()
            }
        }
    }

    // MARK: - Values

    private var level: Double {
        isHolding ? yesterday : drinks.reduce(0) { $0 + $1.litres }
    }

    // "2.13 L", for the total.
    private func full(_ litres: Double) -> String {
        [appearance.format(litres), appearance.unit].compactMap(\.self).joined(separator: " ")
    }

    // "3.4L", for the smaller labels.
    private func compact(_ litres: Double) -> String {
        appearance.format(litres) + (appearance.unit ?? "")
    }

    private enum Constants {
        static let tickCount = 11
        static let rulerWidth: CGFloat = 8
        static let tickHeight: CGFloat = 1
        static let lineWidth: CGFloat = 1
        static let markerSize: CGFloat = 14
    }
}

#Preview {
    let start = Calendar.current.startOfDay(for: .now)
    let drinks = [(7, 0.4), (9, 0.25), (11, 0.3), (13, 0.45), (14, 0.5)].map { hour, litres in
        BrightWaterWidgetV5.Drink(date: start.addingTimeInterval(Double(hour) * 60 * 60), litres: litres)
    }
    let appearance = BrightWidgetAppearanceV5(title: "Water", systemImage: "drop.fill", tint: .defaultCyan, unit: "L", decimals: 2)

    ScrollView {
        VStack(spacing: .spacing205x) {
            BrightWaterWidgetV5(appearance: appearance, drinks: drinks, goal: 4, yesterday: 3.4, size: .small)
                .frame(width: 174, height: 174)

            BrightWaterWidgetV5(appearance: appearance, drinks: drinks, goal: 4, yesterday: 3.4, size: .medium)
                .frame(width: 363, height: 174)

            BrightWaterWidgetV5(
                appearance: appearance,
                drinks: drinks,
                goal: 4,
                yesterday: 3.4,
                week: [4.52, 3.2, 1.92, 3.42, 1.9, nil, nil],
                size: .large
            )
            .frame(width: 363, height: 363)
        }
        .padding(.spacing205x)
    }
    .background(Color.defaultBackground)
}
