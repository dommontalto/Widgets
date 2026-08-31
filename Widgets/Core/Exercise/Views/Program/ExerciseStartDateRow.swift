//
//  ExerciseStartDateRow.swift
//  Widgets
//
//  Created by Dom Montalto on 29/8/2026.
//

import SwiftUI

// When a program begins is scheduling rather than training, so it stays a quiet
// row: the common answers one tap away, the calendar behind the last.
struct ExerciseStartDateRow: View {
    @Binding var startDate: Date
    // Editing may hold a start already in the past; a new program can only
    // begin today or later.
    var allowsPast = false
    // A started program's date is a fact, not a choice: the row goes static.
    var isStarted = false

    @State private var showingPicker = false

    var body: some View {
        if isStarted {
            row(title: "Started", showsChevron: false)
        } else {
            Menu {
                Button("Today", systemImage: "sun.max") {
                    startDate = Calendar.current.startOfDay(for: .now)
                }

                Button("Next Monday", systemImage: "arrow.right.to.line") {
                    startDate = Self.nextMonday
                }

                Button("Pick a date…", systemImage: "calendar") {
                    showingPicker = true
                }
            } label: {
                row(title: "Starts", showsChevron: true)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .brightHaptic(.light, trigger: startDate)
            .brightMiniSheet(isPresented: $showingPicker) {
                picker
            }
        }
    }

    private func row(title: String, showsChevron: Bool) -> some View {
        HStack(spacing: .spacing1x) {
            BrightText(title, size: .body2, color: .semiLightTextColor)

            Spacer(minLength: .spacing2x)

            BrightText(label, size: .body2, weight: .regular)
                .contentTransition(.numericText())
                .animation(.brightSnappy, value: startDate)

            if showsChevron {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: FontSizes.body4.rawValue, weight: .medium))
                    .foregroundStyle(Color.lightTextColor)
            }
        }
    }

    // Today and tomorrow already say when they are; any other day needs its
    // weekday so the start reads as a day of the week, not just a date.
    private var label: String {
        let calendar = Calendar.autoupdatingCurrent
        if calendar.isDateInToday(startDate) || calendar.isDateInTomorrow(startDate) {
            return startDate.formatted(.brightDate)
        }
        return "\(startDate.formatted(.brightWeekday)) \(startDate.formatted(.brightDate))"
    }

    private var picker: some View {
        DatePicker(
            "",
            selection: $startDate,
            in: (allowsPast ? Date.distantPast : Calendar.current.startOfDay(for: .now))...,
            displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .tint(.defaultSkyBlue)
        .labelsHidden()
        .padding(.horizontal, .spacing3x)
        .padding(.top, .spacing4x)
        .padding(.bottom, .spacing2x)
        .onChange(of: startDate) {
            showingPicker = false
        }
    }

    static var nextMonday: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return calendar.nextDate(after: today, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) ?? today
    }
}

#Preview {
    @Previewable @State var date = ExerciseStartDateRow.nextMonday
    ExerciseStartDateRow(startDate: $date)
        .padding(.spacing3x)
        .frame(maxHeight: .infinity)
        .background(Color.defaultSheetBackground)
}
