//
//  VaultDatapointsWidget.swift
//  Widgets
//
//

import SwiftUI

// MARK: - Widget

// Vault → Data hero. Each dot is one real marker from
// `GET /vault/data/markers`; lit dots have recorded data.
// Tapping a dot rings it and opens a compact marker summary sheet. While
// completeness is still loading it renders an all-muted placeholder grid.
struct VaultDatapointsWidget: View {
    var datapoints: [VaultCompletenessDatapoint] = []
    var onExpand: (() -> Void)?

    private static let topColor: Color = .defaultBrightGreen
    private static let bottomColor: Color = .defaultCyan
    private static let legendFill = LinearGradient(colors: [topColor, bottomColor], startPoint: .top, endPoint: .bottom)

    private let columns = 20
    private static let placeholderRows = 8
    private let ordered: [VaultCompletenessDatapoint]

    @State private var selectedId: String?

    init(datapoints: [VaultCompletenessDatapoint] = [], onExpand: (() -> Void)? = nil) {
        self.datapoints = datapoints
        self.onExpand = onExpand
        ordered = datapoints.indices
            .sorted { Self.scatterHash($0) < Self.scatterHash($1) }
            .map { datapoints[$0] }
    }

    // SplitMix64 finalizer — a fixed bijection, so ranks never collide and the
    // scatter is identical on every render and app launch.
    private static func scatterHash(_ x: Int) -> UInt64 {
        var z = UInt64(x) &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    private var total: Int { ordered.count }
    private var filled: Int { ordered.filter { $0.complete == true }.count }

    // No completeness yet — draw a fixed all-muted grid instead of collapsing.
    private var isPlaceholder: Bool { ordered.isEmpty }
    private var dotCount: Int { isPlaceholder ? columns * Self.placeholderRows : total }
    private var gridRows: Int { max(1, Int((Double(dotCount) / Double(columns)).rounded(.up))) }

    private func datapoint(id: String?) -> VaultCompletenessDatapoint? {
        guard !isPlaceholder, let id, let i = Int(id), ordered.indices.contains(i) else { return nil }
        return ordered[i]
    }

    private var gridColumns: [[BrightDotGridV5Dot?]] {
        (0 ..< columns).map { col in
            (0 ..< gridRows).map { row in
                let i = row * columns + col
                guard i < dotCount else { return nil }
                let lit = !isPlaceholder && ordered[i].complete == true
                let colour = rowColour(row)
                let fill = lit ? colour : colour.opacity(.ultraLowOpacity)
                // Looked at, a recorded dot shows where its value sits: red, yellow or green.
                if lit, let position = ordered[i].markerPosition {
                    let stops = VaultMarkerWidget.stops(forMarkerPosition: position, direction: VaultMarkerDirection(ordered[i].direction))
                    return BrightDotGridV5Dot(id: String(i), fill: fill, revealFill: LinearGradient(colors: stops, startPoint: .top, endPoint: .bottom))
                }
                return BrightDotGridV5Dot(id: String(i), fill: fill, isSelectable: !isPlaceholder)
            }
        }
    }

    private func rowColour(_ row: Int) -> Color {
        Self.topColor.mix(with: Self.bottomColor, by: Double(row) / Double(max(gridRows - 1, 1)))
    }

    private var sheetShown: Binding<Bool> {
        Binding(
            get: { datapoint(id: selectedId) != nil },
            set: { if !$0 { selectedId = nil } }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            header

            datapointsGrid
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5())
        .brightMiniSheetV5(isPresented: sheetShown) {
            if let dp = datapoint(id: selectedId) {
                VaultDatapointMiniSheet(
                    title: dp.name ?? "Data point",
                    unit: dp.unit ?? "",
                    hasData: dp.complete == true,
                    latestRecorded: dp.lastUpdated,
                    onClose: { selectedId = nil },
                    value: dp.value,
                    markerId: dp.id,
                    markerPosition: dp.markerPosition,
                    direction: VaultMarkerDirection(dp.direction)
                )
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                HStack(spacing: .spacing1x) {
                    BrightRingV5(
                        progress: total == 0 ? 0 : Double(filled) / Double(total),
                        color: Self.topColor,
                        size: .extraSmall
                    )

                    HStack(alignment: .firstTextBaseline, spacing: .spacing0x) {
                        BrightText("\(filled) ", size: .huge2)
                        BrightText("/\(total)", size: .standout3, color: .lightTextColor)
                    }
                }

                BrightText("Recorded datapoints", size: .body2, color: .lightTextColor)
            }

            Spacer()

            if let onExpand {
                BrightRoundButton(systemImage: "arrow.down.backward.and.arrow.up.forward", onTapCallback: onExpand)
            }
        }
    }

    // MARK: - Grid

    private var datapointsGrid: some View {
        BrightDotGridV5(
            columns: gridColumns,
            legend: [
                BrightDotGridV5Key(title: "Data recorded", fill: Self.legendFill),
                BrightDotGridV5Key(title: "No data", fill: Self.legendFill.opacity(.ultraLowOpacity))
            ],
            selection: $selectedId,
            spacing: .spacing05x
        )
    }
}

#Preview {
    VaultDatapointsWidget(
        datapoints: (0..<420).map {
            VaultCompletenessDatapoint(
                name: "Marker \($0)",
                category: "Preview",
                bucket: "clinical",
                complete: $0 % 3 != 0,
                unit: nil,
                lastUpdated: nil
            )
        }
    )
    .padding(.spacing4x)
}
