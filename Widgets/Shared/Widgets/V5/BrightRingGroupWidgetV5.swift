//
//  BrightRingGroupWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import Charts
import SwiftUI

// One or more progress rings, each against its own goal. Small shows a single ring large,
// three in a triangle or four in a square; medium and large lay them out in a row.
//
// Holding picks out the ring under the finger and swaps its numbers for the detail.
struct BrightRingGroupWidgetV5: View {
    struct Ring: Identifiable, Hashable {
        let label: String
        // In the ring's hole on the small triangle, e.g. "C".
        let shortLabel: String
        let value: Double
        let goal: Double
        let color: Color
        // Shown above the ring in place of "value/goal", e.g. a duration.
        var caption: String?

        var id: String { label }

        var progress: Double {
            goal > 0 ? value / goal : 0
        }

        var isOver: Bool {
            value > goal
        }
    }

    let rings: [Ring]
    let size: BrightWidgetSizeV5
    var allowsSelection = true
    // Erased so the rings stay one type whichever header a widget brings.
    private let header: AnyView?

    @State private var selectedRingID: String?
    @State private var touchX: Double?
    @State private var touchY: Double?

    init(rings: [Ring], size: BrightWidgetSizeV5, allowsSelection: Bool = true) {
        self.rings = rings
        self.size = size
        self.allowsSelection = allowsSelection
        header = nil
    }

    init(rings: [Ring], size: BrightWidgetSizeV5, allowsSelection: Bool = true, @ViewBuilder header: () -> some View) {
        self.rings = rings
        self.size = size
        self.allowsSelection = allowsSelection
        self.header = AnyView(header())
    }

    var body: some View {
        Group {
            if size != .small {
                rowLayout
            } else if rings.count == 1, let ring = rings.first {
                singleLayout(ring)
            } else if rings.count == 4 {
                gridLayout
            } else {
                triangleLayout
            }
        }
        // The square's two rows of rings need the room more than the usual edge padding.
        .padding(size == .small && rings.count == 4 ? .spacing1x : .spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .onChange(of: touchX) { resolveTouch() }
        .onChange(of: touchY) { resolveTouch() }
        .onChange(of: allowsSelection) { _, allows in
            if !allows {
                touchX = nil
                touchY = nil
            }
        }
        .animation(.brightEaseInOut, value: selectedRingID)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rings.map { "\($0.label) \(display($0.value)) of \(display($0.goal))" }.joined(separator: ", "))
    }

    // MARK: - Layouts

    private func singleLayout(_ ring: Ring) -> some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            header

            BrightRingV5(progress: ring.progress, color: ring.color, size: .large)
                .overlay { touchLayer }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            amount(ring, valueSize: .standout3, suffixSize: .body1, valueColor: ring.isOver ? .defaultOrange : ring.color)
                .frame(maxWidth: .infinity)
        }
    }

    // The first ring on top with its amount above, the other two below with theirs underneath.
    private var triangleLayout: some View {
        VStack(spacing: .spacing05x) {
            if let top = rings.first {
                caption(for: top)

                ring(top, showsLabel: true)
            }

            HStack(alignment: .top, spacing: .spacing0x) {
                ForEach(rings.dropFirst()) { ring in
                    VStack(spacing: .spacing05x) {
                        self.ring(ring, showsLabel: true)

                        caption(for: ring)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay { touchLayer }
    }

    // Two by two, each ring showing its share in the hole and its name below.
    private var gridLayout: some View {
        Grid(horizontalSpacing: .spacing2x, verticalSpacing: .spacing0x) {
            ForEach(0 ..< 2, id: \.self) { row in
                GridRow {
                    ForEach(rings[(row * 2) ..< (row * 2 + 2)]) { ring in
                        VStack(spacing: .spacing0x) {
                            self.ring(ring, showsLabel: false)
                                .overlay {
                                    // Holding a ring swaps its share for its caption, such as the time.
                                    BrightText(
                                        selectedRingID == ring.id ? ring.caption ?? percent(of: ring) : percent(of: ring),
                                        size: .body3,
                                        color: .semiLightTextColor
                                    )
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                }

                            BrightText(ring.label, size: .body3, color: .semiLightTextColor)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay { touchLayer }
    }

    private var rowLayout: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            header

            Spacer(minLength: .spacing0x)

            // Fewer than four rings have the room to spread out; four or more sit closer.
            Grid(horizontalSpacing: rings.count < 4 ? .spacing5x : .spacing3x, verticalSpacing: .spacing1x) {
                GridRow {
                    ForEach(rings) { ring in
                        caption(for: ring)
                    }
                }

                GridRow {
                    ForEach(rings) { ring in
                        self.ring(ring, showsLabel: false)
                    }
                }

                GridRow {
                    ForEach(rings) { ring in
                        BrightText(ring.label, size: .body3, color: .semiLightTextColor)
                            .lineLimit(1)
                    }
                }
            }
            .overlay { touchLayer }
            .frame(maxWidth: .infinity)

            Spacer(minLength: .spacing0x)
        }
    }

    // MARK: - Pieces

    // The held ring stays bright while the rest dim.
    // Medium widgets' rows get the medium ring; the small widgets' groups use the default.
    private func ring(_ ring: Ring, showsLabel: Bool) -> some View {
        BrightRingV5(
            progress: ring.progress,
            color: ring.color,
            label: showsLabel ? ring.shortLabel : nil,
            size: size == .small ? .small : .medium
        )
            .opacity(selectedRingID == nil || selectedRingID == ring.id ? .opaque : .semiLowOpacity)
    }

    // A held ring trades its numbers for what's left or over, or for its share of the whole,
    // rolling each piece of text over to the new one: "27/46" becomes "19 left".
    @ViewBuilder
    private func caption(for ring: Ring) -> some View {
        let isHeld = selectedRingID == ring.id

        if let caption = ring.caption {
            BrightText(isHeld ? share(of: ring) : caption, size: .body3, color: isHeld ? .textColor : .lightTextColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
        } else {
            amount(
                ring,
                valueSize: size == .small ? .body3 : .heading,
                suffixSize: .body3,
                valueColor: ring.isOver ? .defaultOrange : .textColor
            )
        }
    }

    // "75/200", or held, "125 left": the number then its suffix in the dimmer text,
    // each rolling over to the other.
    private func amount(_ ring: Ring, valueSize: FontSizes, suffixSize: FontSizes, valueColor: Color) -> some View {
        let isHeld = selectedRingID == ring.id

        return HStack(alignment: .firstTextBaseline, spacing: .spacing0x) {
            BrightText(display(isHeld ? abs(ring.goal - ring.value) : ring.value), size: valueSize, color: valueColor)
                .monospacedDigit()
                .contentTransition(.numericText())

            BrightText(
                isHeld ? (ring.isOver ? " over" : " left") : "/\(display(ring.goal))",
                size: suffixSize,
                color: .lightTextColor
            )
            .monospacedDigit()
            .contentTransition(.numericText())
        }
        .lineLimit(1)
    }

    // MARK: - Holding

    // An empty chart laid over the rings, so holding them uses the same gesture as the
    // charts and the page still scrolls. It reports where the finger is, from 0 to 1 each way.
    @ViewBuilder
    private var touchLayer: some View {
        if allowsSelection {
            Chart {
                PointMark(x: .value("X", 0.5), y: .value("Y", 0.5))
                    .opacity(.zero)
            }
            .chartXScale(domain: 0 ... 1)
            .chartYScale(domain: 0 ... 1)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartXSelection(value: $touchX)
            .chartYSelection(value: $touchY)
        }
    }

    private func resolveTouch() {
        guard let touchX, let touchY else {
            selectedRingID = nil
            return
        }
        // The chart counts up from the bottom; the layouts are laid out from the top.
        let point = CGPoint(x: touchX, y: 1 - touchY)

        let nearest = rings.indices.min { distance(from: point, to: centre(of: $0)) < distance(from: point, to: centre(of: $1)) }
        let id = nearest.map { rings[$0].id }
        guard id != selectedRingID else { return }
        selectedRingID = id
        BrightHaptic.light.play()
    }

    // Where each ring sits in its layout, as a share of the layout's width and height.
    private func centre(of index: Int) -> CGPoint {
        if size != .small {
            return CGPoint(x: (Double(index) + 0.5) / Double(rings.count), y: 0.5)
        }
        if rings.count == 4 {
            return CGPoint(x: index % 2 == 0 ? 0.25 : 0.75, y: index < 2 ? 0.25 : 0.75)
        }
        return index == 0 ? CGPoint(x: 0.5, y: 0.3) : CGPoint(x: index == 1 ? 0.25 : 0.75, y: 0.75)
    }

    // MARK: - Values

    private func distance(from point: CGPoint, to other: CGPoint) -> CGFloat {
        hypot(point.x - other.x, point.y - other.y)
    }

    private func share(of ring: Ring) -> String {
        "\(percent(of: ring))%"
    }

    // The bare number, for the small square where the rings say what it is.
    private func percent(of ring: Ring) -> String {
        "\(Int((ring.progress * 100).rounded()))"
    }

    private func display(_ value: Double) -> String {
        Int(value.rounded()).formatted()
    }
}

#Preview {
    let macros = [
        BrightRingGroupWidgetV5.Ring(label: "Carbs", shortLabel: "C", value: 75, goal: 200, color: .defaultGreen),
        BrightRingGroupWidgetV5.Ring(label: "Fats", shortLabel: "F", value: 58, goal: 46, color: .defaultYellow),
        BrightRingGroupWidgetV5.Ring(label: "Protein", shortLabel: "P", value: 102, goal: 140, color: .defaultPink),
    ]

    VStack(spacing: .spacing205x) {
        BrightRingGroupWidgetV5(rings: macros, size: .medium)
            .frame(width: 363, height: 174)

        HStack(spacing: .spacing205x) {
            BrightRingGroupWidgetV5(rings: macros, size: .small)
                .frame(width: 174, height: 174)

            BrightRingGroupWidgetV5(rings: [macros[0]], size: .small)
                .frame(width: 174, height: 174)
        }
    }
    .padding(.spacing205x)
    .background(Color.defaultBackground)
}
