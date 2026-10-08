//
//  BrightRingGroupWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

// One or more progress rings, each against its own goal. Small shows a single ring large,
// or three in a triangle; medium and large lay them out in a row.
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
    // Erased so the rings stay one type whichever header a widget brings.
    private let header: AnyView?

    init(rings: [Ring], size: BrightWidgetSizeV5) {
        self.rings = rings
        self.size = size
        header = nil
    }

    init(rings: [Ring], size: BrightWidgetSizeV5, @ViewBuilder header: () -> some View) {
        self.rings = rings
        self.size = size
        self.header = AnyView(header())
    }

    var body: some View {
        Group {
            if size != .small {
                rowLayout
            } else if rings.count == 1, let ring = rings.first {
                singleLayout(ring)
            } else {
                triangleLayout
            }
        }
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rings.map { "\($0.label) \(display($0.value)) of \(display($0.goal))" }.joined(separator: ", "))
    }

    // MARK: - Layouts

    private func singleLayout(_ ring: Ring) -> some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            header

            BrightRingV5(progress: ring.progress, color: ring.color, size: .large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            amount(ring, valueSize: .standout3, goalSize: .body1, valueColor: ring.isOver ? .defaultOrange : ring.color)
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
    }

    private var rowLayout: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            header

            Spacer(minLength: .spacing0x)

            Grid(horizontalSpacing: .spacing4x, verticalSpacing: .spacing1x) {
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
            .frame(maxWidth: .infinity)

            Spacer(minLength: .spacing0x)
        }
    }

    // MARK: - Pieces

    private func ring(_ ring: Ring, showsLabel: Bool) -> some View {
        BrightRingV5(progress: ring.progress, color: ring.color, label: showsLabel ? ring.shortLabel : nil)
    }

    @ViewBuilder
    private func caption(for ring: Ring) -> some View {
        if let caption = ring.caption {
            BrightText(caption, size: .body3, color: .lightTextColor)
                .lineLimit(1)
        } else {
            amount(ring, valueSize: size == .small ? .body3 : .heading, goalSize: size == .small ? .body3 : .body3, valueColor: ring.isOver ? .defaultOrange : .textColor)
        }
    }

    // "75/200": the amount, then the goal in the dimmer text.
    private func amount(_ ring: Ring, valueSize: FontSizes, goalSize: FontSizes, valueColor: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing0x) {
            BrightText(display(ring.value), size: valueSize, color: valueColor)
                .monospacedDigit()
                .contentTransition(.numericText())

            BrightText("/\(display(ring.goal))", size: goalSize, color: .lightTextColor)
                .monospacedDigit()
        }
        .lineLimit(1)
    }

    private func display(_ value: Double) -> String {
        Int(value.rounded()).formatted()
    }

    private enum Constants {
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
