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
    @State private var heldFraction: Double?
    @State private var isRevealed = false

    private static let genderOptions = ["men", "women"]
    private static let ageOptions = ["18-24", "25-34", "35-44", "45-54", "55-64", "65+"]

    private var hasData: Bool {
        topPct != nil || ranking?.topPct != nil || fallbackTopPercent != nil
    }

    private var topPercent: Double {
        topPct ?? ranking?.topPct ?? fallbackTopPercent ?? 0
    }

    private var userFraction: Double {
        min(max(1 - topPercent / 100, 0), 1)
    }

    private var isPlaced: Bool {
        hasData && isRevealed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            header
                .padding(.horizontal, .spacing1x)

            cohortRow
                .padding(.horizontal, .spacing1x)
                .padding(.top, .spacing3x)

            chart
                .padding(.top, .spacing2x)

            if hasData, delta7d != 0 {
                deltaRow
                    .frame(maxWidth: .infinity)
                    .padding(.top, .spacing4x)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        VStack(alignment: .leading, spacing: .spacing1x) {
            BrightText("Global Health Ranking", size: .standout3, weight: .medium)
                .lineLimit(1)

            BrightText(revealed(subtitle), size: .body1, color: .lightTextColor, weight: .regular)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .animation(.brightEaseInOut, value: subtitle)
        }
    }

    private var subtitle: String {
        guard hasData else { return "Your ranking appears once your data syncs" }
        if let heldFraction {
            return "Scoring here beats \(Self.percent(heldFraction * 100)) of users"
        }
        return "Your health is better than \(Self.percent(userFraction * 100)) of users"
    }

    private func revealed(_ text: String) -> String {
        isRevealed ? text : text.zeroedDigits
    }

    // MARK: - Cohort

    private var cohortRow: some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: "person.3.sequence.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.textColor, Color.lightTextColor, Color.textColor.opacity(.semiLowOpacity))
                .font(.standardSFPro(size: .subheading2, weight: .regular))

            BrightText("Cohort:", size: .body1, color: .lightTextColor, weight: .regular)
                .lineLimit(1)

            cohortMenu(selection: $gender, options: Self.genderOptions) { $0 == "women" ? "Female" : "Male" }

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

    // MARK: - Chart

    private var chart: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let userX = isPlaced ? xPosition(userFraction, width: width) : 0
            let lineX = isPlaced ? xPosition(heldFraction ?? userFraction, width: width) : 0

            VStack(spacing: .spacing0x) {
                youMarker
                    .position(x: min(max(userX, Constants.markerInset), width - Constants.markerInset), y: Constants.markerRoom / 2)
                    .frame(height: Constants.markerRoom)
                    .opacity(hasData ? .opaque : .zero)

                plotBox(width: width, lineX: lineX)
                    .frame(height: Constants.plotHeight)
                    .overlay { selectionLayer(width: width) }

                ZStack {
                    ForEach(0 ... Constants.tickCount, id: \.self) { index in
                        tick(isMajor: index % Constants.majorEvery == 0)
                            .position(x: xPosition(Double(index) / Double(Constants.tickCount), width: width), y: Constants.tickRow / 2)
                    }
                }
                .frame(height: Constants.tickRow)
                .padding(.top, .spacing2x)

                ZStack {
                    ForEach(Constants.axisLabels, id: \.title) { label in
                        BrightText(label.title, size: .body1, weight: .medium)
                            .fixedSize()
                            .position(x: xPosition(label.fraction, width: width), y: Constants.labelRow / 2)
                    }
                }
                .frame(height: Constants.labelRow)
                .padding(.top, .spacing1x)
            }
            .animation(.brightEaseInOut, value: heldFraction)
            .animation(.brightBouncy, value: userFraction)
            .animation(.brightBouncy, value: isPlaced)
        }
        .frame(height: Constants.markerRoom + Constants.plotHeight + .spacing2x + Constants.tickRow + .spacing1x + Constants.labelRow)
    }

    private var youMarker: some View {
        VStack(spacing: .spacing05x) {
            BrightText("You", size: .subheading, weight: .medium)

            Image(systemName: "arrow.down.circle.fill")
                .font(.standardSFPro(size: .heading, weight: .regular))
                .foregroundStyle(Color.textColor)
        }
        .fixedSize()
    }

    private func plotBox(width: CGFloat, lineX: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Color.textColor.opacity(.finalBossUltraLowOpacity)

            Group {
                BellCurve()
                    .fill(Self.curveFill)
                    .blur(radius: Constants.glowBlur)
                    .opacity(.lowOpacity)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: max(lineX, 0))
                    }

                BellCurve()
                    .fill(Self.curveFill)
                    .mask(alignment: .trailing) {
                        Rectangle().frame(width: max(width - lineX, 0))
                    }
            }
            .opacity(hasData ? .opaque : .ultraLowOpacity)
            .scaleEffect(y: isRevealed ? 1 : 0, anchor: .bottom)
            .animation(.brightReveal, value: isRevealed)

            if hasData {
                Rectangle()
                    .fill(Color.textColor.opacity(.lowOpacity))
                    .frame(width: Constants.lineWidth)
                    .offset(x: lineX - Constants.lineWidth / 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous)
                .strokeBorder(Self.borderGradient, lineWidth: Constants.borderWidth)
        }
    }

    @ViewBuilder
    private func tick(isMajor: Bool) -> some View {
        if isMajor {
            Capsule()
                .fill(Color.lightTextColor)
                .frame(width: .spacing05x, height: .spacing105x)
        } else {
            Circle()
                .fill(Color.textColor.opacity(.veryLowOpacity))
                .frame(width: .spacing1x, height: .spacing1x)
        }
    }

    private var deltaRow: some View {
        HStack(spacing: .spacing05x) {
            Image(systemName: delta7d > 0 ? "arrow.up" : "arrow.down")
                .font(.standardSFPro(size: .subheading, weight: .regular))
                .foregroundStyle(Color.textColor)

            BrightText("\(Self.percent(abs(delta7d))) this week".uppercased(), size: .body1, color: .lightTextColor, weight: .regular)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }

    private func xPosition(_ fraction: Double, width: CGFloat) -> CGFloat {
        Constants.axisInset + (width - Constants.axisInset * 2) * fraction
    }

    private static let curveFill = LinearGradient(
        colors: [.defaultBrightGreen, .defaultCyan],
        startPoint: .top,
        endPoint: .bottom
    )

    private static let borderGradient = LinearGradient(
        colors: [.defaultBrightGreen.opacity(.lowOpacity), .defaultSkyBlue.opacity(.lowOpacity)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Selection

    @ViewBuilder
    private func selectionLayer(width: CGFloat) -> some View {
        if hasData {
            Chart {
                ForEach(0 ... 100, id: \.self) { step in
                    PointMark(x: .value("Position", Double(xPosition(Double(step) / 100, width: width))), y: .value("Floor", 0))
                        .opacity(.zero)
                }
            }
            .chartXScale(domain: 0 ... Double(max(width, 1)))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartXSelection(value: selection(width: width))
        }
    }

    private func selection(width: CGFloat) -> Binding<Double?> {
        Binding {
            heldFraction.map { Double(xPosition($0, width: width)) }
        } set: { position in
            let fraction = position.map { position in
                let raw = (position - Constants.axisInset) / max(width - Constants.axisInset * 2, 1)
                return (min(max(raw, 0), 1) * 100).rounded() / 100
            }
            guard fraction != heldFraction else { return }
            heldFraction = fraction
            if fraction != nil {
                BrightHaptic.light.play()
            }
        }
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

    private enum Constants {
        static let plotHeight: CGFloat = 152
        static let markerRoom: CGFloat = .spacing9x
        static let markerInset: CGFloat = .spacing3x
        static let axisInset: CGFloat = .spacing5x
        static let tickRow: CGFloat = .spacing105x
        static let labelRow: CGFloat = .spacing3x
        static let tickCount = 10
        static let majorEvery = 5
        static let lineWidth: CGFloat = 2
        static let borderWidth: CGFloat = 0.5
        static let glowBlur: CGFloat = .spacing3x
        static let axisLabels = [AxisLabel(title: "0", fraction: 0), AxisLabel(title: "50", fraction: 0.5), AxisLabel(title: "100%", fraction: 1)]
    }
}

private struct AxisLabel {
    let title: String
    let fraction: Double
}

private struct BellCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        for step in 0 ... Constants.steps {
            let fraction = Double(step) / Double(Constants.steps)
            let z = (fraction - Constants.peak) * Constants.spread
            let height = exp(-z * z / 2) * Constants.peakHeight
            path.addLine(to: CGPoint(x: rect.minX + rect.width * fraction, y: rect.maxY - rect.height * height))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    private enum Constants {
        static let steps = 120
        static let peak = 0.5
        static let spread = 4.5
        static let peakHeight = 0.78
    }
}

#Preview {
    VaultSummaryWidget(ranking: .demo)
        .padding(.spacing3x)
        .background(Color.defaultBackground)
}
