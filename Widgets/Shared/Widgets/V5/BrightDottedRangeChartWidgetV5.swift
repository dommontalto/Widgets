//
//  BrightDottedRangeChartWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 9/10/2026.
//

import Charts
import SwiftUI

// A dot for each measure against its own normal range: the middle band is normal, the
// bands above and below are out of it. Each measure sits in its own column over its icon.
// Small and medium; medium names each column and counts what's out of range.
//
// Holding a column picks it out and rolls its name over to its reading.
struct BrightDottedRangeChartWidgetV5: View {
    struct Measure: Identifiable, Hashable {
        let label: String
        let systemImage: String
        let iconColor: Color
        let value: Double
        let normalRange: ClosedRange<Double>
        var unit: String?
        var decimals = 0
        // Leads with "+" when above zero, for readings that are a deviation.
        var isSigned = false

        var id: String { label }

        var isAbnormal: Bool {
            !normalRange.contains(value)
        }

        var reading: String {
            let number = value.formatted(.number.precision(.fractionLength(0 ... decimals)))
            let signed = isSigned && value > 0 ? "+\(number)" : number
            return [signed, unit].compactMap(\.self).joined(separator: " ")
        }
    }

    let appearance: BrightWidgetAppearanceV5
    let measures: [Measure]
    let size: BrightWidgetSizeV5
    var allowsSelection = true

    @State private var selectedID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            HStack(alignment: .top, spacing: .spacing1x) {
                header

                Spacer(minLength: .spacing0x)

                if size != .small, abnormalCount > 0 {
                    abnormalBadge
                }
            }

            VStack(spacing: .spacing05x) {
                bands
                    .overlay { dots }
                    .overlay { touchLayer }
                    .frame(maxHeight: .infinity)

                columns
            }
        }
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .onChange(of: allowsSelection) { _, allows in
            if !allows {
                selectedID = nil
            }
        }
        .animation(.brightEaseInOut, value: selectedID)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(appearance.title), " + measures.map { "\($0.label) \($0.reading)\($0.isAbnormal ? ", abnormal" : "")" }.joined(separator: ", ")
        )
    }

    // MARK: - Header

    // Small has no names under its icons, so holding rolls the title over to the reading.
    private var header: some View {
        HStack(spacing: .spacing05x) {
            Image(systemName: appearance.systemImage)
                .font(.standard(size: .subheading, weight: .light))
                .foregroundStyle(appearance.iconStyle)

            BrightText(size == .small ? selectedMeasure.map { "\($0.label) \($0.reading)" } ?? appearance.title : appearance.title, size: .body1, weight: .regular)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .lineLimit(1)
    }

    private var abnormalBadge: some View {
        HStack(spacing: .spacing05x) {
            BrightText("\(abnormalCount) ABNORMAL", size: .body5, color: Constants.outerColor.opacity(.mediumOpacity))
                .monospacedDigit()

            Image(systemName: "exclamationmark.circle.fill")
                .font(.standard(size: .subheading, weight: .regular))
                .foregroundStyle(Constants.outerColor)
        }
        .lineLimit(1)
    }

    // MARK: - Bands

    // Out of range above, normal, out of range below, each washing down from a line
    // along its top.
    private var bands: some View {
        GeometryReader { geometry in
            let layout = BandLayout(height: geometry.size.height)

            ZStack(alignment: .topLeading) {
                band(Constants.outerColor, top: layout.upperTop, height: layout.outerHeight)
                band(Color.defaultCyan, top: layout.normalTop, height: layout.normalHeight)
                band(Constants.outerColor, top: layout.lowerTop, height: layout.outerHeight)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
    }

    private func band(_ color: Color, top: CGFloat, height: CGFloat) -> some View {
        LinearGradient(colors: [color.opacity(.veryMinimalOpacity), .clear], startPoint: .top, endPoint: .bottom)
            .frame(height: height)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(color.opacity(.lowOpacity))
                    .frame(height: Constants.lineWidth)
            }
            .offset(y: top)
    }

    // MARK: - Dots

    // Each measure's dot over its column: placed by its reading inside the normal band,
    // or centred in the band above or below when it's out of range.
    private var dots: some View {
        GeometryReader { geometry in
            let layout = BandLayout(height: geometry.size.height)

            ForEach(Array(measures.enumerated()), id: \.element) { index, measure in
                dot(for: measure)
                    .opacity(opacity(of: measure))
                    .position(
                        x: columnCentre(index, in: geometry.size.width),
                        y: layout.y(for: measure, inset: Constants.dotDiameter)
                    )
            }
        }
    }

    private func dot(for measure: Measure) -> some View {
        let color = measure.isAbnormal ? Constants.outerColor : Color.defaultCyan

        return Circle()
            .fill(Color.defaultHomeCards)
            .overlay {
                Circle()
                    .strokeBorder(color, lineWidth: Constants.dotRingWidth)
            }
            .frame(width: Constants.dotDiameter, height: Constants.dotDiameter)
            .shadow(color: color.opacity(.lowOpacity), radius: Constants.dotGlowRadius)
    }

    // MARK: - Columns

    // Each measure's icon under its dot; medium names it below, rolling over to its reading
    // while held.
    private var columns: some View {
        HStack(spacing: .spacing0x) {
            ForEach(measures) { measure in
                VStack(spacing: .spacing05x) {
                    Image(systemName: measure.systemImage)
                        .font(.standard(size: .body1, weight: .light))
                        .foregroundStyle(measure.iconColor)
                        .frame(height: Constants.iconHeight)

                    if size != .small {
                        BrightText(
                            selectedID == measure.id ? measure.reading : measure.label,
                            size: .body3,
                            color: selectedID == measure.id ? .textColor : .lightTextColor
                        )
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .lineLimit(1)
                    }
                }
                .opacity(opacity(of: measure))
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Holding

    // An empty chart laid over the bands, so holding them uses the same gesture as the
    // charts and the page still scrolls. Snaps to the column under the finger.
    @ViewBuilder
    private var touchLayer: some View {
        if allowsSelection {
            Chart {
                PointMark(x: .value("Column", 0.5), y: .value("Floor", 0))
                    .opacity(.zero)
            }
            .chartXScale(domain: 0 ... 1)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartXSelection(value: selection)
        }
    }

    private var selection: Binding<Double?> {
        Binding {
            selectedIndex.map { (Double($0) + 0.5) / Double(measures.count) }
        } set: { position in
            let id = position.map { position in
                measures[min(max(Int(position * Double(measures.count)), 0), measures.count - 1)].id
            }
            guard id != selectedID else { return }
            selectedID = id
            if id != nil {
                BrightHaptic.light.play()
            }
        }
    }

    // MARK: - Values

    private var selectedMeasure: Measure? {
        measures.first { $0.id == selectedID }
    }

    private var selectedIndex: Int? {
        measures.firstIndex { $0.id == selectedID }
    }

    private var abnormalCount: Int {
        measures.filter(\.isAbnormal).count
    }

    // The held column stays bright while the rest dim.
    private func opacity(of measure: Measure) -> Double {
        selectedID == nil || selectedID == measure.id ? .opaque : .ultraLowOpacity
    }

    private func columnCentre(_ index: Int, in width: CGFloat) -> CGFloat {
        width * (CGFloat(index) + 0.5) / CGFloat(max(measures.count, 1))
    }

    // Where the three bands sit in the plot: the outer two a share of its height each,
    // the normal one the rest.
    private struct BandLayout {
        let outerHeight: CGFloat
        let normalHeight: CGFloat
        let upperTop: CGFloat
        let normalTop: CGFloat
        let lowerTop: CGFloat

        init(height: CGFloat) {
            outerHeight = height * Constants.outerShare
            normalHeight = max(height - outerHeight * 2, 0)
            upperTop = .zero
            normalTop = outerHeight
            lowerTop = normalTop + normalHeight
        }

        func y(for measure: Measure, inset: CGFloat) -> CGFloat {
            let range = measure.normalRange
            if measure.value > range.upperBound {
                return upperTop + outerHeight / 2
            }
            if measure.value < range.lowerBound {
                return lowerTop + outerHeight / 2
            }
            let span = range.upperBound - range.lowerBound
            let share = span > 0 ? (measure.value - range.lowerBound) / span : 0.5
            let room = max(normalHeight - inset * 2, 0)
            return normalTop + inset + room * (1 - share)
        }
    }

    private enum Constants {
        static let outerColor = Color.defaultYellow
        static let outerShare: CGFloat = 0.22
        static let lineWidth: CGFloat = 1
        static let dotDiameter: CGFloat = 8
        static let dotRingWidth: CGFloat = 2
        static let dotGlowRadius: CGFloat = 3
        static let iconHeight: CGFloat = 20
    }
}

#Preview {
    let appearance = BrightWidgetAppearanceV5(title: "Sleep Vitals", systemImage: "moon.fill", tint: .defaultCyan)
    let measures: [BrightDottedRangeChartWidgetV5.Measure] = [
        .init(label: "RHR", systemImage: "heart.fill", iconColor: .defaultRed, value: 56, normalRange: 45 ... 62, unit: "BPM"),
        .init(label: "Resp.", systemImage: "lungs.fill", iconColor: .defaultCyan, value: 14.2, normalRange: 12 ... 17, unit: "br/min", decimals: 1),
        .init(label: "Temp.", systemImage: "thermometer.variable", iconColor: .defaultOrange, value: 0.7, normalRange: -0.5 ... 0.5, unit: "°C", decimals: 1, isSigned: true),
        .init(label: "HRV", systemImage: "waveform.path.ecg.rectangle.fill", iconColor: .defaultRed, value: 34, normalRange: 30 ... 70, unit: "ms"),
    ]

    VStack(spacing: .spacing205x) {
        BrightDottedRangeChartWidgetV5(appearance: appearance, measures: measures, size: .medium)
            .frame(width: 363, height: 174)

        BrightDottedRangeChartWidgetV5(appearance: appearance, measures: measures, size: .small)
            .frame(width: 174, height: 174)
    }
    .padding(.spacing205x)
    .background(Color.defaultBackground)
}
