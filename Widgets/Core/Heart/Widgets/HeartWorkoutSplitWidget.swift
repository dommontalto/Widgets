//
//  HeartWorkoutSplitWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import SwiftUI

struct HeartWorkoutSplitWidget: View {
    let data: [HeartWorkoutSummarySplit]
    @State private var isExpanded = false

    private var allRows: [SplitRow] {
        data.compactMap { split in
            guard let duration = split.duration,
                  !duration.asString.isEmpty,
                  let paceSeconds = split.paceSecondsPerKm,
                  paceSeconds > 0,
                  let hr = split.avgHeartRate
            else {
                return nil
            }

            return SplitRow(
                time: duration.asString,
                pace: formatPace(secondsPerKm: paceSeconds),
                heartRate: "\(hr) BPM"
            )
        }
    }

    private var visibleRows: [SplitRow] {
        guard allRows.count > Constants.collapsedRowCount else { return allRows }
        return Array(allRows.prefix(isExpanded ? allRows.count : Constants.collapsedRowCount))
    }

    private var shouldShowMoreButton: Bool {
        allRows.count > Constants.collapsedRowCount
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

                        splitRow(row, displayNumber: index + 1)
                            .padding(.vertical, .spacing2x)
                    }
                }
            }
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .sheetModalCards))
    }

    private var header: some View {
        HStack {
            BrightText("Split", size: .body1)

            Spacer()

            if shouldShowMoreButton {
                BrightPillButton(
                    isExpanded ? "See Less" : "See More",
                    buttonSize: .small
                ) {
                    withAnimation(.brightEaseInOut) {
                        isExpanded.toggle()
                    }
                }
            }
        }
    }

    private var columnHeaders: some View {
        HStack(spacing: .spacing0x) {
            Spacer()
                .frame(width: Constants.numberColumnWidth)

            columnHeader("Time", alignment: .leading)
            columnHeader("Pace", alignment: .leading)
            columnHeader("Heart Rate", alignment: .trailing)
        }
    }

    private func columnHeader(_ title: String, alignment: Alignment) -> some View {
        BrightText(title, size: .body3, color: .textColor.opacity(.veryLowOpacity))
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    private func splitRow(_ row: SplitRow, displayNumber: Int) -> some View {
        HStack(spacing: .spacing0x) {
            BrightText("\(displayNumber)", size: .body3, color: .textColor.opacity(.veryLowOpacity))
                .frame(width: Constants.numberColumnWidth, alignment: .leading)

            BrightText(row.time, size: .body3, color: .semiLightTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            BrightText(row.pace, size: .body3, color: .semiLightTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            BrightText(row.heartRate, size: .body3, color: .semiLightTextColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .contentShape(Rectangle())
    }

    private func formatPace(secondsPerKm: Int) -> String {
        String(format: "%d:%02d /km", secondsPerKm / 60, secondsPerKm % 60)
    }

    private struct SplitRow: Identifiable {
        let id = UUID()
        let time: String
        let pace: String
        let heartRate: String
    }

    private enum Constants {
        static let collapsedRowCount = 5
        static let numberColumnWidth: CGFloat = 18
    }
}

#Preview {
    HeartWorkoutSplitWidget(data: HeartDemoData.workout.splits ?? [])
        .padding(.spacing3x)
        .background(Color.sheetBackground)
}
