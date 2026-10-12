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
// Every size draws the same rings, each placed from the card's own size rather than by a
// stack, so resizing carries them along under the finger and glides them between
// arrangements.
struct BrightRingGroupWidgetV5: View {
    struct Ring: Identifiable, Hashable {
        let label: String
        // In the ring's hole on the small triangle, e.g. "C"

        let shortLabel: String
        let value: Double
        let goal: Double
        let color: Color
        // Shown above the ring in place of "value/goal", e.g. a duration.
        var caption: String?
        // At most this many decimal places, e.g. 2 for "2.54/4" litres.
        var decimals = 0
        // Going over turns the amount orange; off for goals where more is fine, like water.
        var warnsWhenOver = true
        var image: String?

        var id: String { label }

        var progress: Double {
            goal > 0 ? value / goal : 0
        }

        var isOver: Bool {
            value > goal
        }

        var showsOverWarning: Bool {
            warnsWhenOver && isOver
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
    @State private var area: CGSize = .zero
    @State private var headerHeight: CGFloat = .zero
    // Each ring's text above and below, so the rings make room for the tallest.
    @State private var aboveHeights: [String: CGFloat] = [:]
    @State private var belowHeights: [String: CGFloat] = [:]

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
        ZStack(alignment: .topLeading) {
            if let header {
                header
                    .onGeometryChange(for: CGFloat.self, of: \.size.height) { headerHeight = $0 }
                    .opacity(showsHeader ? .opaque : .zero)
            }

            GeometryReader { geometry in
                ForEach(Array(rings.enumerated()), id: \.element.id) { index, ring in
                    piece(ring, index: index, in: geometry.size)
                        .position(centre(of: index, in: geometry.size))
                }
            }
            .onGeometryChange(for: CGSize.self, of: \.size) { area = $0 }
            .overlay { touchLayer }
        }
        // The square's two rows of rings need the room more than the usual edge padding.
        .padding(arrangement == .square || arrangement == .triangle ? .spacing1x : .spacing205x)
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
        .accessibilityLabel(rings.map { "\($0.label) \(display($0.value, of: $0)) of \(display($0.goal, of: $0))" }.joined(separator: ", "))
    }

    // MARK: - Arrangement

    // Small shows one ring large, three in a triangle or four in a square; medium and
    // large lay them out in a row under the header.
    private enum Arrangement {
        case single
        case triangle
        case square
        case row
    }

    private var arrangement: Arrangement {
        if size != .small {
            return .row
        }
        if rings.count == 1 {
            return .single
        }
        return rings.count == 4 ? .square : .triangle
    }

    private var showsHeader: Bool {
        arrangement == .single || arrangement == .row
    }

    private var ringSize: BrightRingV5.Size {
        switch arrangement {
        case .single: .large
        case .triangle: .small
        case .square: .extraSmall
        case .row: .medium
        }
    }

    private var aboveHeight: CGFloat {
        rings.compactMap { aboveHeights[$0.id] }.max() ?? .zero
    }

    private var belowHeight: CGFloat {
        rings.compactMap { belowHeights[$0.id] }.max() ?? .zero
    }

    // Where each ring's middle sits. Worked out from the room rather than stacked, so
    // the rings move with the card as it's stretched.
    private func centre(of index: Int, in area: CGSize) -> CGPoint {
        let diameter = ringSize.diameter
        let middle = CGPoint(x: area.width / 2, y: area.height / 2)

        switch arrangement {
        case .single:
            // Centred in what's left between the header and the amount.
            let room = area.height - headerHeight - belowHeight - .spacing1x * 2
            return CGPoint(x: middle.x, y: headerHeight + .spacing1x + room / 2)
        case .triangle:
            // The bottom pair tuck up under the top ring, so the three sit packed together.
            let pitch = diameter + Constants.triangleGap
            let rise = pitch * sqrt(3) / 4
            guard index > 0 else {
                return CGPoint(x: middle.x, y: middle.y - rise)
            }
            return CGPoint(x: middle.x + (index == 1 ? -pitch : pitch) / 2, y: middle.y + rise)
        case .square:
            let cell = diameter + .spacing05x + belowHeight
            let top = middle.y - (cell * 2 + .spacing05x) / 2 + diameter / 2
            return CGPoint(
                x: middle.x + (index % 2 == 0 ? -1 : 1) * (diameter + .spacing3x) / 2,
                y: index < 2 ? top : top + cell + .spacing05x
            )
        case .row:
            // Fewer than four rings have the room to spread out; four or more sit closer.
            let gap: CGFloat = rings.count < 4 ? .spacing5x : .spacing3x
            let pitch = min(diameter + gap, area.width / CGFloat(max(rings.count, 1)))
            let offset = CGFloat(index) - CGFloat(rings.count - 1) / 2
            let centred = (headerHeight + area.height + aboveHeight - belowHeight) / 2
            let lowest = headerHeight + .spacing1x + aboveHeight + .spacing1x + diameter / 2
            return CGPoint(x: middle.x + offset * pitch, y: max(centred, lowest))
        }
    }

    // MARK: - Pieces

    // A ring with its text hung above and below it, so placing the ring places the lot.
    private func piece(_ ring: Ring, index: Int, in area: CGSize) -> some View {
        BrightRingV5(
            progress: ring.progress,
            color: ring.color,
            label: arrangement == .triangle ? ring.shortLabel : nil,
            image: arrangement == .single ? nil : ring.image,
            size: ringSize,
            overColor: overColor(of: ring)
        )
        .overlay {
            if arrangement == .square {
                BrightText(percent(of: ring), size: .body5, color: .semiLightTextColor)
                    .monospacedDigit()
            }
        }
        .overlay(alignment: .top) {
            ZStack {
                above(ring, index: index)
            }
            .fixedSize()
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { aboveHeights[ring.id] = $0 }
            .alignmentGuide(.top) { $0[.bottom] + aboveGap }
        }
        .overlay(alignment: .bottom) {
            ZStack {
                below(ring, index: index)
            }
            .fixedSize()
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { belowHeights[ring.id] = $0 }
            .alignmentGuide(.bottom) { $0[.top] - belowGap(in: area) }
        }
        .opacity(opacity(of: ring))
    }

    // The amount or caption over the row's rings and the triangle's top one.
    @ViewBuilder
    private func above(_ ring: Ring, index: Int) -> some View {
        if arrangement == .row || (arrangement == .triangle && index == 0) {
            caption(for: ring)
        }
    }

    @ViewBuilder
    private func below(_ ring: Ring, index: Int) -> some View {
        switch arrangement {
        case .single:
            amount(ring, valueSize: .standout3, suffixSize: .body1, valueColor: ring.showsOverWarning ? .defaultOrange : ring.color)
        case .triangle:
            if index > 0 {
                caption(for: ring)
            }
        case .square:
            // Holding a ring swaps its name for its caption, such as the time.
            steady(isHeld: selectedRingID == ring.id) { isHeld in
                BrightText(isHeld ? ring.caption ?? ring.label : ring.label, size: .body5, color: isHeld ? .textColor : .semiLightTextColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
            }
        case .row:
            BrightText(ring.label, size: .body3, color: .semiLightTextColor)
                .lineLimit(1)
        }
    }

    private var aboveGap: CGFloat {
        arrangement == .row ? .spacing1x : .spacing05x
    }

    // The single ring's amount sits on the bottom edge; the rest hang just under their ring.
    private func belowGap(in area: CGSize) -> CGFloat {
        switch arrangement {
        case .single:
            max(area.height - belowHeight - centre(of: 0, in: area).y - ringSize.diameter / 2, .spacing0x)
        case .row:
            .spacing1x
        case .triangle, .square:
            .spacing05x
        }
    }

    private func overColor(of ring: Ring) -> Color? {
        ring.warnsWhenOver ? .defaultOrange : nil
    }

    // The held ring stays bright while the rest, with their numbers and names, dim.
    private func opacity(of ring: Ring) -> Double {
        selectedRingID == nil || selectedRingID == ring.id ? .opaque : .ultraLowOpacity
    }

    // A held ring trades its numbers for what's left or over, or for its share of the whole,
    // rolling each piece of text over to the new one: "27/46" becomes "19 left".
    @ViewBuilder
    private func caption(for ring: Ring) -> some View {
        if let caption = ring.caption {
            steady(isHeld: selectedRingID == ring.id) { isHeld in
                BrightText(isHeld ? share(of: ring) : caption, size: .body3, color: isHeld ? .textColor : .lightTextColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
            }
        } else {
            // The small triangle keeps its amounts quiet; the medium row leads with them.
            amount(
                ring,
                valueSize: size == .small ? .body4 : .heading,
                suffixSize: size == .small ? .body4 : .body3,
                valueColor: ring.showsOverWarning ? .defaultOrange : (size == .small ? .semiLightTextColor : .textColor)
            )
        }
    }

    // "75/200", or held, "125 left": the number then its suffix in the dimmer text,
    // each rolling over to the other.
    private func amount(_ ring: Ring, valueSize: FontSizes, suffixSize: FontSizes, valueColor: Color) -> some View {
        steady(isHeld: selectedRingID == ring.id) { isHeld in
            amountText(ring, isHeld: isHeld, valueSize: valueSize, suffixSize: suffixSize, valueColor: valueColor)
        }
    }

    private func amountText(_ ring: Ring, isHeld: Bool, valueSize: FontSizes, suffixSize: FontSizes, valueColor: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing0x) {
            BrightText(display(isHeld ? abs(ring.goal - ring.value) : ring.value, of: ring), size: valueSize, color: valueColor)
                .monospacedDigit()
                .contentTransition(.numericText())

            BrightText(
                isHeld ? (ring.isOver ? " over" : " left") : "/\(display(ring.goal, of: ring))",
                size: suffixSize,
                color: .lightTextColor
            )
            .monospacedDigit()
            .contentTransition(.numericText())
        }
        .lineLimit(1)
    }

    // Takes the room of the wider of its held and resting text, so swapping one for the
    // other never resizes its column and nudges the rings beside it.
    private func steady(isHeld: Bool, @ViewBuilder _ content: (Bool) -> some View) -> some View {
        ZStack {
            content(false)
                .hidden()

            content(true)
                .hidden()

            content(isHeld)
        }
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
        // The chart counts up from the bottom; the rings are placed from the top.
        let point = CGPoint(x: touchX * area.width, y: (1 - touchY) * area.height)

        let nearest = rings.indices.min { distance(from: point, to: centre(of: $0, in: area)) < distance(from: point, to: centre(of: $1, in: area)) }
        let id = nearest.map { rings[$0].id }
        guard id != selectedRingID else { return }
        selectedRingID = id
        BrightHaptic.light.play()
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

    private func display(_ value: Double, of ring: Ring) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... ring.decimals)))
    }

    private enum Constants {
        static let triangleGap: CGFloat = .spacing105x
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
