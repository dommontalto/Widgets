//
//  VaultSummaryWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 14/10/2026.
//

import Charts
import SwiftUI

struct VaultSummaryWidget: View {
    var ranking: VaultRankingData?
    var fallbackTopPercent: Double?

    @State private var gender = "men"
    @State private var ageRange = "18-24"
    @State private var topPct: Double?
    @State private var delta7d: Double = 0
    @State private var heldBin: Int?
    @State private var plotWidth: CGFloat = 0
    @State private var isRevealed = false
    @State private var markerSize: CGSize = .zero

    private static let genderOptions = ["men", "women"]
    private static let ageOptions = ["18-24", "25-30", "31-35", "36-40",
                                     "41-45", "46-50", "51-55", "56-60", "60+"]

    private var hasData: Bool {
        topPct != nil || ranking?.topPct != nil || fallbackTopPercent != nil
    }

    private var topPercent: Double {
        topPct ?? ranking?.topPct ?? fallbackTopPercent ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            header
            distribution
            BrightDividerV5()
                .padding(.horizontal, -.spacing3x)
            cohortRow
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5())
        .brightRevealV5($isRevealed)
        .onChange(of: ranking?.topPct, initial: true) { _, _ in
            seedFromRanking()
        }
        .onChange(of: gender) { _, _ in refetch() }
        .onChange(of: ageRange) { _, _ in refetch() }
    }

    private func seedFromRanking() {
        guard let ranking else { return }
        topPct = ranking.topPct
        delta7d = ranking.delta7d ?? 0
        for axis in ranking.cohortAxes ?? [] {
            switch axis.axis?.lowercased() {
            case "sex":
                if let value = axis.value?.lowercased() {
                    gender = value == "female" ? "women" : "men"
                }
            case "age":
                if let value = axis.value, !value.isEmpty {
                    ageRange = value
                }
            default:
                break
            }
        }
    }

    private func refetch() {
        let sex = gender == "women" ? "female" : "male"
        let cohort = "sex:\(sex),age:\(ageRange)"
        let result = VaultRankingData.demo(cohort: cohort)
        withAnimation(.brightBouncy) {
            topPct = result.topPct ?? topPct
            delta7d = result.delta7d ?? delta7d
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing1x) {
                BrightWidgetIconV5(systemImage: "trophy", style: Color.textColor)

                BrightText("Cohort ranking", size: .body1, weight: .regular)

                Spacer(minLength: .spacing1x)

                if hasData, delta7d != 0 {
                    deltaPill
                }
            }
            .lineLimit(1)

            VStack(alignment: .leading, spacing: .spacing05x) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                    BrightText("Top", size: .standout3, color: .lightTextColor)

                    readingNumber(color: .clear)
                        .overlay {
                            Self.readingGradient
                                .mask { readingNumber(color: .textColor) }
                                .opacity(heldBin == nil ? .opaque : .zero)
                        }
                        .overlay {
                            readingNumber(color: .textColor)
                                .opacity(heldBin == nil ? .zero : .opaque)
                        }
                }
                .lineLimit(1)

                BrightText(subtitle, size: .body2, color: .lightTextColor)
                    .contentTransition(.numericText())
                    .lineLimit(1)
            }
            .animation(.brightEaseInOut, value: readingText)
            .animation(.brightEaseInOut, value: subtitle)
        }
    }

    private func readingNumber(color: Color) -> some View {
        BrightText(revealed(readingText), size: .giant, color: color, weight: .regular)
            .monospacedDigit()
            .contentTransition(.numericText())
    }

    private var deltaPill: some View {
        let tone: Color = delta7d > 0 ? .defaultCyan : .defaultRed

        return BrightText(
            "\(delta7d > 0 ? "+" : "−")\(Self.percent(abs(delta7d))) this week".uppercased(),
            size: .body3,
            color: tone
        )
        .monospacedDigit()
        .contentTransition(.numericText())
        .padding(.spacing1x)
        .background(tone.opacity(.minimalOpacity), in: Capsule())
    }

    private var readingText: String {
        guard hasData else { return "–" }
        if let heldBin {
            return Self.percent(bins[heldBin].topPercent)
        }
        return Self.percent(topPercent)
    }

    private var subtitle: String {
        guard hasData else { return "Your ranking appears once your data syncs" }
        if let heldBin {
            return "\(Self.percent(bins[heldBin].share * 100)) of \(cohortName) score here"
        }
        return "Ahead of \(Self.percent(100 - topPercent)) of \(cohortName)"
    }

    private var cohortName: String {
        "\(gender) aged \(Self.ageTitle(ageRange))"
    }

    private func revealed(_ text: String) -> String {
        isRevealed ? text : text.zeroedDigits
    }

    // MARK: - Distribution

    private struct Bin: Identifiable {
        let index: Int
        let share: Double
        let height: Double
        let topPercent: Double

        var id: Int { index }
    }

    private var bins: [Bin] {
        let count = Constants.binCount
        let width = Constants.zLimit * 2 / Double(count)
        let edges = (0 ... count).map { -Constants.zLimit + Double($0) * width }
        let shares = (0 ..< count).map { Self.cdf(edges[$0 + 1]) - Self.cdf(edges[$0]) }
        let tallest = shares.max() ?? 1
        return (0 ..< count).map { index in
            Bin(
                index: index,
                share: shares[index],
                height: shares[index] / tallest,
                topPercent: (1 - Self.cdf(edges[index])) * 100
            )
        }
    }

    private var userBin: Int? {
        guard hasData else { return nil }
        let z = Self.inverseCDF(min(max(1 - topPercent / 100, 0.0001), 0.9999))
        let index = Int((z + Constants.zLimit) / (Constants.zLimit * 2) * Double(Constants.binCount))
        return min(max(index, 0), Constants.binCount - 1)
    }

    private var distribution: some View {
        VStack(spacing: .spacing1x) {
            GeometryReader { geometry in
                let size = geometry.size
                let barWidth = slotWidth(in: size.width) * Constants.barFraction
                let plotHeight = size.height - Constants.markerRoom

                ZStack(alignment: .bottomLeading) {
                    BrightDashedLineV5(axis: .vertical)
                        .frame(height: plotHeight)
                        .offset(x: size.width / 2)

                    Color.textColor.opacity(.ultraLowOpacity)
                        .mask {
                            barStack(bins.filter { $0.index > (userBin ?? -1) }, barWidth: barWidth, plotHeight: plotHeight, size: size)
                        }

                    Self.spectrum
                        .mask {
                            barStack(bins.filter { $0.index <= (userBin ?? -1) }, barWidth: barWidth, plotHeight: plotHeight, size: size)
                        }
                        .shadow(color: Color.defaultGreen.opacity(.veryLowOpacity), radius: .spacing05x)
                }
                .frame(width: size.width, height: size.height, alignment: .bottomLeading)
                .overlay(alignment: .topLeading) {
                    if let userBin {
                        let centre = slotCentre(userBin, in: size.width)
                        let userTop = size.height - barHeight(bins[userBin], barWidth: barWidth, plotHeight: plotHeight)
                        let pillBottom = markerBottom(around: centre, barWidth: barWidth, plotHeight: plotHeight, size: size)

                        ZStack(alignment: .topLeading) {
                            BrightDashedLineV5(axis: .vertical)
                                .frame(height: max(userTop - pillBottom - Constants.markerGap * 2, 0))
                                .position(x: centre, y: (pillBottom + userTop) / 2)

                            youMarker
                                .onGeometryChange(for: CGSize.self, of: \.size) { markerSize = $0 }
                                .position(
                                    x: min(max(centre, markerSize.width / 2), size.width - markerSize.width / 2),
                                    y: pillBottom - markerSize.height / 2
                                )
                        }
                        .opacity(heldBin == nil && isRevealed ? .opaque : .zero)
                    }
                }
            }
            .frame(height: Constants.plotHeight)
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { plotWidth = $0 }
            .overlay { selectionLayer }
            .animation(.brightEaseInOut, value: heldBin)
            .animation(.brightBouncy, value: userBin)

            ZStack {
                BrightText("Bottom", size: .body5, color: .lightTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                BrightText("Median", size: .body5, color: .lightTextColor)
                BrightText("Top", size: .body5, color: .lightTextColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func barStack(_ bins: [Bin], barWidth: CGFloat, plotHeight: CGFloat, size: CGSize) -> some View {
        ZStack(alignment: .bottomLeading) {
            ForEach(bins) { bin in
                Capsule()
                    .fill(bin.index == userBin ? Self.solidBar : Self.fadingBar)
                    .frame(width: barWidth, height: isRevealed ? barHeight(bin, barWidth: barWidth, plotHeight: plotHeight) : barWidth)
                    .opacity(heldBin == nil || heldBin == bin.index ? .opaque : .ultraLowOpacity)
                    .offset(x: slotCentre(bin.index, in: size.width) - barWidth / 2)
                    .animation(.brightReveal.delay(Double(bin.index) * Constants.revealStagger), value: isRevealed)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .bottomLeading)
    }

    private var youMarker: some View {
        BrightText("YOU", size: .body6, weight: .regular)
            .padding(.horizontal, .spacing1x)
            .padding(.vertical, .spacing05x)
            .background(Color.textColor.opacity(.ultraLowOpacity), in: Capsule())
            .fixedSize()
    }

    private func barHeight(_ bin: Bin, barWidth: CGFloat, plotHeight: CGFloat) -> CGFloat {
        max(plotHeight * bin.height, barWidth)
    }

    private func markerBottom(around centre: CGFloat, barWidth: CGFloat, plotHeight: CGFloat, size: CGSize) -> CGFloat {
        let reach = markerSize.width / 2 + barWidth / 2 + Constants.markerGap
        let tallest = bins
            .filter { abs(slotCentre($0.index, in: size.width) - centre) < reach }
            .map { barHeight($0, barWidth: barWidth, plotHeight: plotHeight) }
            .max() ?? 0
        return size.height - tallest - Constants.markerGap * 2
    }

    private static let spectrum = LinearGradient(
        colors: [.defaultCyan, .defaultGreen],
        startPoint: .leading,
        endPoint: .trailing
    )

    private static let readingGradient = LinearGradient(
        colors: [.defaultCyan, .defaultGreen],
        startPoint: .leading,
        endPoint: .trailing
    )

    private static let solidBar = LinearGradient(colors: [.black], startPoint: .top, endPoint: .bottom)

    private static let fadingBar = LinearGradient(
        colors: [.black, .black.opacity(.veryLowOpacity)],
        startPoint: .top,
        endPoint: .bottom
    )

    private func slotWidth(in width: CGFloat) -> CGFloat {
        width / CGFloat(Constants.binCount)
    }

    private func slotCentre(_ index: Int, in width: CGFloat) -> CGFloat {
        slotWidth(in: width) * (CGFloat(index) + 0.5)
    }

    // MARK: - Selection

    @ViewBuilder
    private var selectionLayer: some View {
        if hasData {
            Chart {
                ForEach(bins) { bin in
                    PointMark(x: .value("Bin", Double(slotCentre(bin.index, in: plotWidth))), y: .value("Floor", 0))
                        .opacity(.zero)
                }
            }
            .chartXScale(domain: 0 ... Double(max(plotWidth, 1)))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartXSelection(value: selection)
        }
    }

    private var selection: Binding<Double?> {
        Binding {
            heldBin.map { Double(slotCentre($0, in: plotWidth)) }
        } set: { position in
            let index = position.map { position in
                min(max(Int(position / Double(max(plotWidth, 1)) * Double(Constants.binCount)), 0), Constants.binCount - 1)
            }
            guard index != heldBin else { return }
            heldBin = index
            if index != nil {
                BrightHaptic.light.play()
            }
        }
    }

    // MARK: - Cohort

    private var cohortRow: some View {
        HStack(spacing: .spacing1x) {
            BrightText("Compared with", size: .body2, color: .lightTextColor)
                .lineLimit(1)

            Spacer(minLength: .spacing1x)

            cohortMenu(selection: $gender, options: Self.genderOptions) { $0.capitalized }

            cohortMenu(selection: $ageRange, options: Self.ageOptions) { Self.ageTitle($0) }
        }
    }

    private func cohortMenu(selection: Binding<String>, options: [String], title: @escaping (String) -> String) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button {
                    selection.wrappedValue = option
                } label: {
                    Label {
                        Text(title(option))
                    } icon: {
                        if option == selection.wrappedValue {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            BrightText(title(selection.wrappedValue), size: .body1, weight: .regular)
                .contentTransition(.numericText())
                .lineLimit(1)
                .padding(.horizontal, .spacing2x)
                .padding(.vertical, .spacing1x)
                .modifier(BrightGlassEffectV5(shape: .capsule))
                .contentShape(Capsule())
                .animation(.brightBouncy, value: selection.wrappedValue)
        }
        .buttonStyle(.plain)
        .brightHapticV5(.light, trigger: selection.wrappedValue)
    }

    // MARK: - Formatting

    private static func ageTitle(_ range: String) -> String {
        range.replacingOccurrences(of: "-", with: "–")
    }

    private static func percent(_ value: Double) -> String {
        "\(number(value))%"
    }

    private static func number(_ value: Double) -> String {
        let rounded = value >= 10 ? value.rounded() : (value * 10).rounded() / 10
        return rounded.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(rounded))"
            : String(format: "%.1f", rounded)
    }

    // MARK: - Normal curve

    private static func cdf(_ z: Double) -> Double {
        0.5 * (1 + erf(z / 2.0.squareRoot()))
    }

    private static func inverseCDF(_ p: Double) -> Double {
        var low = -Constants.zLimit
        var high = Constants.zLimit
        for _ in 0 ..< 40 {
            let mid = (low + high) / 2
            if cdf(mid) < p {
                low = mid
            } else {
                high = mid
            }
        }
        return (low + high) / 2
    }

    private enum Constants {
        static let binCount = 21
        static let zLimit = 3.0
        static let barFraction: CGFloat = 0.62
        static let plotHeight: CGFloat = 150
        static let markerRoom: CGFloat = .spacing5x
        static let markerGap: CGFloat = .spacing05x
        static let revealStagger = 0.015
    }
}

#Preview {
    VaultSummaryWidget(ranking: .demo)
    .padding(.spacing3x)
    .background(Color.defaultBackground)
}
