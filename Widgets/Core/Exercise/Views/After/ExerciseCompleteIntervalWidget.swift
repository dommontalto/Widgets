//
//  ExerciseCompleteIntervalWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

struct ExerciseCompleteIntervalWidget: View {
    let data: [ExerciseIntervalPayload]

    @State private var isExpanded = false

    private var allRows: [IntervalRow] {
        data.indices.compactMap { position -> IntervalRow? in
            let interval = data[position]
            let kind = interval.kind ?? .other
            let time = durationText(interval.duration)

            guard time != nil || interval.name?.isEmpty == false else { return nil }

            return IntervalRow(
                name: displayName(for: interval, kind: kind, fallbackIndex: position + 1),
                kind: kind,
                time: time,
                heartRate: interval.avgHeartRate.map { "\($0) BPM" },
                distance: distanceText(interval.distance)
            )
        }
    }

    private var visibleRows: [IntervalRow] {
        if allRows.count <= Constants.collapsedRowCount { return allRows }
        return Array(allRows.prefix(isExpanded ? allRows.count : Constants.collapsedRowCount))
    }

    private var shouldShowMoreButton: Bool {
        allRows.count > Constants.collapsedRowCount
    }

    private var showsHeartRate: Bool {
        allRows.contains { $0.heartRate != nil }
    }

    private var showsDistance: Bool {
        allRows.contains { $0.distance != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            header
                .padding(.bottom, .spacing2x)

            VStack(alignment: .leading, spacing: .spacing1x) {
                columnHeaders

                VStack(spacing: .spacing0x) {
                    ForEach(Array(visibleRows.enumerated()), id: \.element.id) { index, row in
                        if index != 0 {
                            BrightDivider()
                        }

                        intervalRow(row)
                            .padding(.top, .spacing2x)
                            .padding(
                                .bottom,
                                index == visibleRows.count - 1 ? .spacing0x : .spacing2x
                            )
                    }
                }
            }
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    private var header: some View {
        HStack {
            BrightText("Intervals", size: .body1, weight: .regular)

            Spacer()

            if shouldShowMoreButton {
                BrightPillButton(isExpanded ? "See Less" : "See More", buttonSize: .small) {
                    withAnimation(.brightEaseInOut) {
                        isExpanded.toggle()
                    }
                }
            }
        }
    }

    private var columnHeaders: some View {
        HStack(spacing: .spacing0x) {
            Color.clear
                .frame(width: Constants.dotColumnWidth, height: 0)

            columnHeader("Interval")
            columnHeader("Time")

            if showsDistance {
                columnHeader("Distance")
            }

            if showsHeartRate {
                columnHeader("Avg HR")
            }
        }
    }

    private func columnHeader(_ title: String) -> some View {
        BrightText(title, size: .body1, color: .textColor.opacity(.veryLowOpacity))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func intervalRow(_ row: IntervalRow) -> some View {
        HStack(spacing: .spacing0x) {
            Circle()
                .fill(color(for: row.kind))
                .frame(width: Constants.dotSize, height: Constants.dotSize)
                .frame(width: Constants.dotColumnWidth, alignment: .leading)

            value(row.name)
            value(row.time)

            if showsDistance {
                value(row.distance)
            }

            if showsHeartRate {
                value(row.heartRate)
            }
        }
        .contentShape(Rectangle())
    }

    private func value(_ text: String?) -> some View {
        BrightText(
            text ?? "-",
            size: .body1,
            color: text == nil ? .textColor.opacity(.veryLowOpacity) : .textColor
        )
        .monospacedDigit()
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func displayName(
        for interval: ExerciseIntervalPayload,
        kind: ExerciseIntervalKind,
        fallbackIndex: Int
    ) -> String {
        if let name = interval.name, !name.isEmpty { return name }
        if let label = label(for: kind) { return label }
        return "Interval \(interval.index ?? fallbackIndex)"
    }

    private func label(for kind: ExerciseIntervalKind) -> String? {
        switch kind {
        case .warmup: "Warm Up"
        case .work: "Work"
        case .rest: "Rest"
        case .recovery: "Recovery"
        case .cooldown: "Cool Down"
        case .other: nil
        }
    }

    private func color(for kind: ExerciseIntervalKind) -> Color {
        switch kind {
        case .warmup: .defaultOrange
        case .work: .defaultRed
        case .rest, .recovery, .cooldown: .defaultBlue
        case .other: .lightTextColor
        }
    }

    private func durationText(_ duration: TimeDuration?) -> String? {
        guard let duration else { return nil }
        let total = Int(duration.totalSeconds)
        guard total > 0 else { return nil }

        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func distanceText(_ distance: Amount?) -> String? {
        guard let distance, let value = distance.value, value > 0 else { return nil }
        let unit = (distance.unit ?? "").uppercased()

        if distance.unit?.lowercased() == "m" {
            return "\(Int(value)) \(unit)"
        }
        return String(format: "%.2f %@", value, unit)
    }

    private struct IntervalRow: Identifiable {
        let id = UUID()
        let name: String
        let kind: ExerciseIntervalKind
        let time: String?
        let heartRate: String?
        let distance: String?
    }

    private enum Constants {
        static let collapsedRowCount = 5
        static let dotColumnWidth: CGFloat = 22
        static let dotSize: CGFloat = .spacing1x
    }
}

#Preview {
    ExerciseCompleteIntervalWidget(data: ExerciseDemoComplete.cardio.summary.intervals ?? [])
        .padding(.spacing3x)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.defaultSheetBackground.ignoresSafeArea())
}
