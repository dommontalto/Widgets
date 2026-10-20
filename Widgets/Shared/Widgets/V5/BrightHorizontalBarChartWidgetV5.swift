//
//  BrightHorizontalBarChartWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 13/10/2026.
//

import SwiftUI

struct BrightHorizontalBarChartWidgetV5: View {
    struct Bar: Identifiable, Hashable {
        let label: String
        let value: Double
        let goal: Double
        let color: Color
        var gradient: Gradient?
        var systemImage: String?
        var image: String?
        var shortLabel = ""
        var unit = ""
        var decimals = 0
        var reading: String?
        var goalReading: String?
        var heldReading: String?
        var heldUnit: String?
        var yesterday: Double?

        var id: String { label }

        var progress: Double {
            goal > 0 ? min(max(value / goal, 0), 1) : 0
        }

        var formattedValue: String {
            reading ?? value.formatted(.number.precision(.fractionLength(0 ... decimals)))
        }

        var formattedGoal: String {
            goalReading ?? goal.formatted(.number.precision(.fractionLength(0 ... decimals)))
        }

        var formattedGap: String {
            if let yesterday {
                return yesterday.formatted(.number.precision(.fractionLength(0 ... decimals)))
            }
            return heldReading ?? abs(goal - value).formatted(.number.precision(.fractionLength(0 ... decimals)))
        }

        var gapUnit: String {
            if yesterday != nil {
                return "Yesterday"
            }
            return heldUnit ?? (value > goal ? "over" : "left")
        }

        var yesterdayProgress: Double? {
            yesterday.map { goal > 0 ? min(max($0 / goal, 0), 1) : 0 }
        }

        var fill: AnyShapeStyle {
            if let gradient {
                AnyShapeStyle(LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing))
            } else {
                AnyShapeStyle(LinearGradient(colors: [color.opacity(.lowOpacity), color], startPoint: .leading, endPoint: .trailing))
            }
        }
    }

    let bars: [Bar]
    var subtitle: String?
    var subtitleColor: Color = .defaultCyan
    let size: BrightWidgetSizeV5
    var allowsSelection = true

    @State private var isRevealed = false
    @State private var heldID: String?
    @State private var touch: UnitPoint?
    @State private var cardHeight: CGFloat = 0
    @State private var barMids: [String: CGFloat] = [:]
    @Namespace private var namespace
    @Environment(\.brightWidgetIsEmpty) private var isEmpty

    var body: some View {
        content
            .padding(.spacing205x)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .coordinateSpace(.named(Constants.space))
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { cardHeight = $0 }
            .overlay {
                if allowsSelection, !isEmpty {
                    BrightWidgetTouchLayerV5(touch: $touch)
                }
            }
            .onChange(of: touch) { resolveTouch() }
            .animation(.brightEaseInOut, value: heldID)
            .modifier(BrightCardModifierV5(color: .defaultHomeCards))
            .brightRevealV5($isRevealed)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(bars.map { "\($0.label), \($0.formattedValue) \($0.unit) of \($0.formattedGoal)" }.joined(separator: ", "))
    }

    @ViewBuilder
    private var content: some View {
        if let bar = bars.first, bars.count == 1 {
            single(bar)
        } else {
            triple
        }
    }

    // MARK: - Single

    private func single(_ bar: Bar) -> some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            HStack(spacing: .spacing1x) {
                icon(bar, size: Constants.iconSize)

                BrightText(bar.label, size: .body1, weight: .regular)
            }
            .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                BrightText(isHeld(bar) ? bar.formattedGap : revealed(isEmpty ? .brightEmptyValue : bar.formattedValue), size: .huge2, weight: .regular)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                let unit = isHeld(bar) ? bar.gapUnit : bar.unit
                if !unit.isEmpty {
                    BrightText(unit, size: .body1, color: .lightTextColor, weight: .regular)
                        .contentTransition(.numericText())
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(Constants.minimumScale)
            .padding(.top, .spacing2x)

            if let subtitle, !isEmpty {
                BrightText(subtitle, size: .body5, color: subtitleColor.opacity(.mediumOpacity), weight: .regular)
                    .lineLimit(1)
            }

            Spacer(minLength: .spacing0x)

            barColumn
        }
    }

    // MARK: - Triple

    private var triple: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            HStack(spacing: isMedium ? .spacing4x : .spacing0x) {
                ForEach(bars) { bar in
                    VStack(spacing: .spacing05x) {
                        if !isMedium {
                            icon(bar, size: Constants.iconSize)
                                .matchedGeometryEffect(id: bar.id, in: namespace, properties: .position)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: .spacing025x) {
                            BrightText(isHeld(bar) && isMedium ? bar.formattedGap : revealed(isEmpty ? .brightEmptyValue : bar.formattedValue), size: isMedium ? .standout1 : .heading, color: bar.color, weight: .regular)
                                .monospacedDigit()
                                .contentTransition(.numericText())

                            BrightText(isHeld(bar) && isMedium ? bar.gapUnit : (isMedium ? bar.unit : ""), size: .body3, color: .lightTextColor, weight: .regular)
                                .contentTransition(.numericText())
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(Constants.minimumScale)
                        .scaleEffect(isHeld(bar) && isMedium ? Constants.heldScale : 1, anchor: .leading)
                    }
                    .frame(maxWidth: isMedium ? nil : .infinity)
                    .opacity(isMedium ? opacity(of: bar) : (heldID == nil ? .opaque : .zero))
                }
            }
            .overlay {
                if !isMedium, let bar = bars.first(where: isHeld) {
                    HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                        BrightText(bar.formattedGap, size: .heading, color: bar.color, weight: .regular)
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        BrightText(bar.gapUnit, size: .body3, color: .lightTextColor, weight: .regular)
                            .contentTransition(.numericText())
                    }
                    .lineLimit(1)
                    .transition(.opacity)
                }
            }
            .padding(.leading, isMedium ? Constants.mediumIconSize + .spacing2x : .spacing0x)
            .padding(.top, isMedium ? .spacing2x : .spacing0x)

            Spacer(minLength: .spacing0x)

            HStack(alignment: .top, spacing: isMedium ? .spacing2x : .spacing0x) {
                if isMedium {
                    VStack(spacing: .spacing3x) {
                        ForEach(bars) { bar in
                            icon(bar, size: Constants.mediumIconSize)
                                .frame(width: Constants.mediumIconSize, height: Constants.barHeight)
                                .matchedGeometryEffect(id: bar.id, in: namespace, properties: .position)
                                .opacity(opacity(of: bar))
                        }
                    }
                }

                barColumn
            }
        }
    }

    private var isMedium: Bool {
        size != .small
    }

    private var barColumn: some View {
        VStack(spacing: .spacing0x) {
            VStack(spacing: .spacing3x) {
                ForEach(bars) { bar in
                    track(bar)
                        .opacity(opacity(of: bar))
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.frame(in: .named(Constants.space)).midY
                        } action: {
                            barMids[bar.id] = $0
                        }
                }
            }

            HStack {
                BrightText("0", size: .body3, color: .lightTextColor)

                Spacer(minLength: .spacing1x)

                BrightText("100", size: .body3, color: .lightTextColor)
            }
            .padding(.top, .spacing1x)
        }
    }

    // MARK: - Pieces

    private func track(_ bar: Bar) -> some View {
        ZStack {
            Capsule()
                .fill(bar.fill)
                .opacity(.minimalOpacity)

            Capsule()
                .strokeBorder(bar.color.opacity(.veryLowOpacity), lineWidth: Constants.outlineWidth)

            HealthProgressCapsuleShape(progress: isRevealed && !isEmpty ? (isHeld(bar) ? bar.yesterdayProgress ?? bar.progress : bar.progress) : 0)
                .fill(bar.fill)
        }
        .frame(height: Constants.barHeight)
        .animation(.brightBouncy, value: isRevealed)
        .animation(.brightBouncy, value: bar.progress)
    }

    @ViewBuilder
    private func icon(_ bar: Bar, size: CGFloat) -> some View {
        if let image = bar.image {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else if let systemImage = bar.systemImage {
            BrightWidgetIconV5(systemImage: systemImage, style: bar.color)
        } else {
            BrightText(bar.shortLabel, size: .body3, color: bar.color, weight: .regular)
                .frame(width: size, height: size)
        }
    }

    private func revealed(_ text: String) -> String {
        isRevealed ? text : text.zeroedDigits
    }

    private enum Constants {
        static let barHeight: CGFloat = 10
        static let outlineWidth: CGFloat = 0.5
        static let iconSize: CGFloat = 18
        static let mediumIconSize: CGFloat = 20
        static let minimumScale: CGFloat = 0.6
        static let heldScale: CGFloat = 1.1
        static let space = "horizontalBarCard"
    }
}

extension BrightHorizontalBarChartWidgetV5 {
    // MARK: - Holding

    private func isHeld(_ bar: Bar) -> Bool {
        heldID == bar.id
    }

    private func opacity(of bar: Bar) -> Double {
        heldID == nil || heldID == bar.id || bars.count == 1 ? .opaque : .ultraLowOpacity
    }

    private func resolveTouch() {
        guard let touch else {
            heldID = nil
            return
        }
        let y = touch.y * cardHeight
        let nearest = bars.min { abs((barMids[$0.id] ?? 0) - y) < abs((barMids[$1.id] ?? 0) - y) }
        guard nearest?.id != heldID else { return }
        heldID = nearest?.id
        BrightHaptic.light.play()
    }
}

private struct HealthProgressCapsuleShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard progress > 0 else { return Path() }
        let width = max(rect.width * progress, rect.height)
        return Capsule().path(in: CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))
    }
}

#Preview {
    VStack(spacing: .spacing205x) {
        HStack(spacing: .spacing205x) {
            BrightHorizontalBarChartWidgetV5(
                bars: [.init(label: "Intake", value: 1_823, goal: 2_300, color: .defaultGreen, gradient: .brightIntake, systemImage: "arrow.right", unit: "Cal")],
                subtitle: "477 behind",
                size: .small
            )
            .frame(width: 174, height: 174)

            BrightHorizontalBarChartWidgetV5(
                bars: [
                    .init(label: "Recovery", value: 56, goal: 100, color: .defaultGreen, shortLabel: "R", unit: "%"),
                    .init(label: "Fatigue", value: 22, goal: 100, color: .defaultRed, shortLabel: "F", unit: "%"),
                    .init(label: "Readiness", value: 82, goal: 100, color: .defaultCyan, shortLabel: "R", unit: "%"),
                ],
                size: .small
            )
            .frame(width: 174, height: 174)
        }

        BrightHorizontalBarChartWidgetV5(
            bars: [
                .init(label: "Recovery", value: 56, goal: 100, color: .defaultGreen, shortLabel: "R", unit: "%"),
                .init(label: "Fatigue", value: 22, goal: 100, color: .defaultRed, shortLabel: "F", unit: "%"),
                .init(label: "Readiness", value: 82, goal: 100, color: .defaultCyan, shortLabel: "R", unit: "%"),
            ],
            size: .medium
        )
        .frame(width: 363, height: 174)
    }
    .padding(.spacing205x)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultBackground)
}
