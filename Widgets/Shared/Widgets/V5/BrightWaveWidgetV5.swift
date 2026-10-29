//
//  BrightWaveWidgetV5.swift
//  Widgets
//

import Charts
import SwiftUI

struct BrightWaveWidgetV5<Accessory: View>: View {
    let title: String
    let fraction: Double?
    var delta: Double = 0
    let emptySubtitle: String
    var unit = "percentile"
    var style = BrightWaveStyle.health
    @ViewBuilder var accessory: () -> Accessory

    @State private var heldFraction: Double?
    @State private var isRevealed = false

    private var hasData: Bool { fraction != nil }

    private var userFraction: Double {
        min(max(fraction ?? 0, 0), 1)
    }

    private var isPlaced: Bool {
        hasData && isRevealed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            header
                .padding(.horizontal, .spacing1x)

            accessory()
                .padding(.horizontal, .spacing1x)
                .padding(.top, .spacing2x)

            chart
                .padding(.top, .spacing2x)

            if hasData, delta != 0 {
                deltaRow
                    .frame(maxWidth: .infinity)
                    .padding(.top, .spacing4x)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Not brightRevealV5: its withAnimation on appear animates a pushed screen's whole first layout.
        .task {
            guard !isRevealed else { return }
            try? await Task.sleep(for: WaveConstants.revealDelay)
            isRevealed = true
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            BrightText(title, size: .heading, weight: .medium)
                .lineLimit(1)

            if hasData {
                HStack(spacing: .spacing1x) {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.defaultBlack, Color.defaultGreen)
                        .font(.standardSFPro(size: .standout3, weight: .regular))

                    HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                        BrightText(shownValue.ordinalSuffix(), size: .standout2, weight: .regular)
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        BrightText(unit, size: .body2, color: .lightTextColor, weight: .regular)
                    }
                }
                .animation(.brightEaseInOut, value: shownValue)
            } else {
                BrightText(emptySubtitle, size: .body1, color: .lightTextColor, weight: .regular)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private var shownValue: Int {
        isRevealed ? Int(((heldFraction ?? userFraction) * 100).rounded()) : 0
    }

    // MARK: - Chart

    private var chart: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let userX = isPlaced ? xPosition(userFraction, width: width) : width
            let lineX = isPlaced ? xPosition(heldFraction ?? userFraction, width: width) : width

            VStack(spacing: .spacing0x) {
                youMarker
                    .position(x: min(max(userX, WaveConstants.markerInset), width - WaveConstants.markerInset), y: WaveConstants.markerRoom / 2)
                    .frame(height: WaveConstants.markerRoom)
                    .opacity(hasData ? .opaque : .zero)

                plotBox(width: width, lineX: lineX)
                    .frame(height: WaveConstants.plotHeight)
                    .overlay { selectionLayer(width: width) }

                ZStack {
                    ForEach(0 ... WaveConstants.tickCount, id: \.self) { index in
                        tick(isMajor: index % WaveConstants.majorEvery == 0)
                            .position(x: xPosition(Double(index) / Double(WaveConstants.tickCount), width: width), y: WaveConstants.tickRow / 2)
                    }
                }
                .frame(height: WaveConstants.tickRow)
                .padding(.top, .spacing2x)

                ZStack {
                    ForEach(WaveConstants.axisLabels, id: \.title) { label in
                        BrightText(label.title, size: .body1, weight: .medium)
                            .fixedSize()
                            .position(x: xPosition(label.fraction, width: width), y: WaveConstants.labelRow / 2)
                    }
                }
                .frame(height: WaveConstants.labelRow)
                .padding(.top, .spacing1x)
            }
            .animation(.brightEaseInOut, value: heldFraction)
            .animation(.brightBouncy, value: userFraction)
            .animation(.brightReveal, value: isPlaced)
        }
        .frame(height: WaveConstants.markerRoom + WaveConstants.plotHeight + .spacing2x + WaveConstants.tickRow + .spacing1x + WaveConstants.labelRow)
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
        let fill = LinearGradient(gradient: style.curve, startPoint: .top, endPoint: .bottom)
        return ZStack(alignment: .leading) {
            Color.textColor.opacity(.finalBossUltraLowOpacity)

            // Blurred up to the line and sharp after it; until the result is
            // placed the line waits at the trailing edge, so it opens leftward.
            Group {
                BellCurve()
                    .fill(fill)
                    .blur(radius: WaveConstants.glowBlur)
                    .opacity(.lowOpacity)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: max(lineX, 0))
                    }

                BellCurve()
                    .fill(fill)
                    .mask(alignment: .trailing) {
                        Rectangle().frame(width: max(width - lineX, 0))
                    }
            }
            .scaleEffect(y: isRevealed ? 1 : 0, anchor: .bottom)
            .animation(.brightReveal, value: isRevealed)

            if isPlaced {
                Rectangle()
                    .fill(Color.textColor.opacity(.lowOpacity))
                    .frame(width: WaveConstants.lineWidth)
                    .offset(x: lineX - WaveConstants.lineWidth / 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: style.border.map { $0.opacity(.lowOpacity) }, startPoint: .leading, endPoint: .trailing),
                    lineWidth: WaveConstants.borderWidth
                )
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
            Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                .font(.standardSFPro(size: .subheading, weight: .regular))
                .foregroundStyle(Color.textColor)

            BrightText("\(Self.percent(abs(delta))) this week".uppercased(), size: .body1, color: .lightTextColor, weight: .regular)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }

    private func xPosition(_ fraction: Double, width: CGFloat) -> CGFloat {
        WaveConstants.axisInset + (width - WaveConstants.axisInset * 2) * fraction
    }

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
                let raw = (position - WaveConstants.axisInset) / max(width - WaveConstants.axisInset * 2, 1)
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

    static func percent(_ value: Double) -> String {
        let rounded = value >= 10 ? value.rounded() : (value * 10).rounded() / 10
        let number = rounded.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(rounded))"
            : String(format: "%.1f", rounded)
        return "\(number)%"
    }
}

extension BrightWaveWidgetV5 where Accessory == EmptyView {
    init(title: String, fraction: Double?, delta: Double = 0, emptySubtitle: String, unit: String = "percentile", style: BrightWaveStyle = .health) {
        self.init(title: title, fraction: fraction, delta: delta, emptySubtitle: emptySubtitle, unit: unit, style: style) { EmptyView() }
    }
}

enum BrightWaveStyle {
    case health
    case genome

    var curve: Gradient {
        switch self {
        case .health: Gradient(colors: [.defaultGreen, .defaultCyan])
        case .genome: Gradient(stops: [.init(color: .defaultWaveBlue, location: 0.33), .init(color: .defaultWaveMagenta, location: 1)])
        }
    }

    var border: [Color] {
        switch self {
        case .health: [.defaultGreen, .defaultSkyBlue]
        case .genome: [.defaultWavePink, .defaultCards, .defaultWaveSky]
        }
    }
}

// Outside the generic widget: generic types can't hold static stored properties.
private enum WaveConstants {
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
    static let revealDelay: Duration = .milliseconds(350)
    static let axisLabels = [AxisLabel(title: "0", fraction: 0), AxisLabel(title: "50", fraction: 0.5), AxisLabel(title: "100%", fraction: 1)]
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
    VStack(spacing: .spacing5x) {
        BrightWaveWidgetV5(
            title: "Global Health Ranking",
            fraction: 0.68,
            delta: 2,
            emptySubtitle: "Your ranking appears once your data syncs"
        )

        BrightWaveWidgetV5(
            title: "Genetic Risk Percentile",
            fraction: nil,
            emptySubtitle: "Your percentile appears once your results are in",
            style: .genome
        )
    }
    .padding(.spacing3x)
    .background(Color.defaultBackground)
}
