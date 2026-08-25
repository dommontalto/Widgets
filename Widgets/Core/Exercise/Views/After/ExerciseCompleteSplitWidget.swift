//
//  ExerciseCompleteSplitWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

struct ExerciseCompleteSplitWidget: View {
    let data: [ExerciseCardioSummarySplit]

    @State private var isExpanded = false

    private var allRows: [SplitRow] {
        data.compactMap { split in
            guard let duration = split.duration,
                  duration.totalSeconds > 0,
                  let paceSeconds = split.paceSecondsPerKm,
                  paceSeconds > 0,
                  let hr = split.avgHeartRate
            else {
                return nil
            }

            return SplitRow(
                time: clock(duration),
                pace: pace(secondsPerKm: paceSeconds),
                heartRate: "\(hr) BPM",
                zone: split.zoneIndex
            )
        }
    }

    private var visibleRows: [SplitRow] {
        if allRows.count <= Constants.collapsedRowCount { return allRows }
        return Array(allRows.prefix(isExpanded ? allRows.count : Constants.collapsedRowCount))
    }

    private var shouldShowMoreButton: Bool {
        allRows.count > Constants.collapsedRowCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            header

            VStack(spacing: .spacing0x) {
                columnHeaders
                    .padding(.bottom, .spacing1x)

                ForEach(Array(visibleRows.enumerated()), id: \.element.id) { index, row in
                    if index != 0 {
                        BrightDivider()
                    }

                    splitRow(row, number: index + 1)
                        .padding(.top, .spacing2x)
                        .padding(
                            .bottom,
                            index == visibleRows.count - 1 ? .spacing0x : .spacing2x
                        )
                }
            }
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    private var header: some View {
        HStack {
            BrightText("Splits", size: .body1, weight: .regular)

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
                .frame(width: Constants.numberColumnWidth, height: 0)

            column("Time")
            column("Pace")
            column("Heart Rate")
            column("Zones", alignment: .trailing)
        }
    }

    private func column(_ title: String, alignment: Alignment = .leading) -> some View {
        BrightText(title, size: .body1, color: .textColor.opacity(.veryLowOpacity))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    private func splitRow(_ row: SplitRow, number: Int) -> some View {
        HStack(spacing: .spacing0x) {
            BrightText("\(number)", size: .body1, color: .semiLightTextColor)
                .monospacedDigit()
                .frame(width: Constants.numberColumnWidth, alignment: .leading)

            value(row.time)
            value(row.pace)
            value(row.heartRate)

            zoneTag(row.zone)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .contentShape(Rectangle())
    }

    private func value(_ text: String) -> some View {
        BrightText(text, size: .body1)
            .monospacedDigit()
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func zoneTag(_ zone: Int?) -> some View {
        if let zone {
            BrightStatus(status: "Zone \(zone)")
        }
    }

    private func clock(_ duration: TimeDuration) -> String {
        let total = Int(duration.totalSeconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func pace(secondsPerKm: Int) -> String {
        "\(secondsPerKm / 60)\u{2019}\(String(format: "%02d", secondsPerKm % 60))\u{201D}"
    }

    private struct SplitRow: Identifiable {
        let id = UUID()
        let time: String
        let pace: String
        let heartRate: String
        let zone: Int?
    }

    private enum Constants {
        static let collapsedRowCount = 5
        static let numberColumnWidth: CGFloat = 22
    }
}

#Preview {
    ExerciseCompleteSplitWidget(data: ExerciseDemoComplete.cardio.summary.splits ?? [])
        .padding(.spacing3x)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.defaultSheetBackground.ignoresSafeArea())
}
