//
//  ExerciseCalendarWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import SwiftUI

struct ExerciseCalendarWidget: View {
    @State private var selectedDate: Date
    @State private var scrolledID: Date?
    @State private var showingCalendarSheet = false

    private let calendar = Calendar.current
    private let days: [Date]

    init() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        _selectedDate = State(initialValue: today)
        _scrolledID = State(initialValue: Self.anchorDate(for: today))

        let start = calendar.date(byAdding: .day, value: -365, to: today)!
        let end = calendar.date(byAdding: .day, value: 365, to: today)!

        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(calendar.startOfDay(for: current))
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        days = dates
    }

    var body: some View {
        VStack(spacing: .spacing3x) {
            HStack(alignment: .top, spacing: .spacing1x) {
                calendarView

                BrightRoundButton(
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    size: .medium
                ) {
                    showingCalendarSheet = true
                }
            }

            sessionView
                .animation(.brightEaseInOut, value: selectedDate)
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
        .sheet(isPresented: $showingCalendarSheet) {
            ExerciseCalendarSheet(selectedDate: $selectedDate)
        }
    }

    private var calendarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: .spacing0x) {
                ForEach(days, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        dotColor: ExerciseCalendarDemo.session(on: date)?.color,
                        onTap: { tappedDate in
                            BrightHaptic.light.play()
                            withAnimation(.brightSnappy) {
                                selectedDate = tappedDate
                                scrolledID = Self.anchorDate(for: tappedDate)
                            }
                        }
                    )
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length / CGFloat(Constants.visibleDays)
                    }
                    .id(date)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolledID, anchor: .leading)
        .onChange(of: scrolledID) { _, newID in
            if let newID {
                let candidate = Self.selectedDate(forAnchor: newID)
                if !calendar.isDate(candidate, inSameDayAs: selectedDate) {
                    BrightHaptic.light.play()
                    selectedDate = candidate
                }
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            let anchor = Self.anchorDate(for: newDate)
            if scrolledID != anchor {
                withAnimation(.brightSnappy) {
                    scrolledID = anchor
                }
            }
        }
    }

    private var sessionView: some View {
        Group {
            if let session = ExerciseCalendarDemo.session(on: selectedDate) {
                sessionCard(session)
            } else {
                emptyCard
            }
        }
        .id(selectedDate)
        .transition(.blurReplace)
    }

    private func sessionCard(_ session: ExerciseCalendarSession) -> some View {
        HStack(spacing: .spacing105x) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(session.color)
                .frame(width: 2)

            VStack(alignment: .leading, spacing: .spacing05x) {
                HStack(spacing: .spacing05x) {
                    BrightText(session.name, size: .body2, color: session.color, weight: .regular)

                    Spacer()

                    Image(systemName: "stopwatch")
                        .font(.standard(size: .body2, weight: .light))
                        .foregroundStyle(session.color)
                    BrightText(session.duration, size: .body2, color: session.color)
                }

                BrightText(session.time, size: .body2, color: session.color)
                    .opacity(.lowOpacity)

                HStack(spacing: .spacing1x) {
                    ForEach(session.symbols, id: \.self) { symbol in
                        chip(symbol)
                    }
                }
                .padding(.top, .spacing105x)
            }
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            session.color.opacity(.ultraLowOpacity),
            in: RoundedRectangle(cornerRadius: .cornerRadius18, style: .continuous)
        )
    }

    private var emptyCard: some View {
        HStack(spacing: .spacing105x) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Color.defaultGreen)
                .frame(width: 2, height: 35)

            BrightText("No sessions", size: .body2, color: .defaultGreen, weight: .regular)
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.defaultGreen.opacity(.ultraLowOpacity),
            in: RoundedRectangle(cornerRadius: .cornerRadius18, style: .continuous)
        )
    }

    private func chip(_ symbol: String) -> some View {
        Circle()
            .strokeBorder(Color.textColor.opacity(.minimalOpacity), lineWidth: 1)
            .frame(width: Constants.chipSize, height: Constants.chipSize)
            .overlay {
                Image(systemName: symbol)
                    .font(.standardSFPro(size: .subheading, weight: .light))
                    .foregroundStyle(Color.textColor)
            }
    }

    private static func anchorDate(for date: Date) -> Date {
        let calendar = Calendar.current
        let shifted = calendar.date(byAdding: .day, value: -Constants.selectedSlotIndex, to: date) ?? date
        return calendar.startOfDay(for: shifted)
    }

    private static func selectedDate(forAnchor anchor: Date) -> Date {
        let calendar = Calendar.current
        let shifted = calendar.date(byAdding: .day, value: Constants.selectedSlotIndex, to: anchor) ?? anchor
        return calendar.startOfDay(for: shifted)
    }

    enum Constants {
        static let circleSize: CGFloat = 36
        static let chipSize: CGFloat = 36
        static let dotSize: CGFloat = 4
        static let visibleDays = 7
        static let selectedSlotIndex = 3
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let dotColor: Color?
    let onTap: (Date) -> Void

    var body: some View {
        VStack(spacing: .spacing2x) {
            ZStack {
                Circle()
                    .strokeBorder(Color.textColor, lineWidth: 1)

                BrightText(date.formatted(.brightDay), size: .body3, weight: .regular)
            }
            .frame(
                width: ExerciseCalendarWidget.Constants.circleSize,
                height: ExerciseCalendarWidget.Constants.circleSize
            )
            .opacity(isSelected ? .opaque : .minimalOpacity)
            .overlay(alignment: .bottom) {
                if let dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(
                            width: ExerciseCalendarWidget.Constants.dotSize,
                            height: ExerciseCalendarWidget.Constants.dotSize
                        )
                        .padding(.bottom, .spacing1x)
                }
            }

            BrightText(
                date.formatted(.brightWeekdayInitial),
                size: .subheading1,
                weight: isSelected ? .medium : .regular
            )
            .opacity(isSelected ? .opaque : .minimalOpacity)
        }
        .animation(.brightBouncy, value: isSelected)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onTap(date) }
    }
}

struct ExerciseCalendarSession {
    let name: String
    let time: String
    let duration: String
    let color: Color
    let symbols: [String]
}

enum ExerciseCalendarDemo {
    static func session(on date: Date) -> ExerciseCalendarSession? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let offset = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: date)).day ?? 0
        return sessionsByOffset[offset]
    }

    private static let sessionsByOffset: [Int: ExerciseCalendarSession] = [
        0: ExerciseCalendarSession(
            name: "Gym session",
            time: "6:00 - 7:00 PM",
            duration: "1hr 30min",
            color: .defaultPurple,
            symbols: ["figure.strengthtraining.traditional", "figure.run"]
        ),
        1: ExerciseCalendarSession(
            name: "5K run",
            time: "6:30 - 7:00 AM",
            duration: "30min",
            color: .defaultSkyBlue,
            symbols: ["figure.run"]
        ),
        3: ExerciseCalendarSession(
            name: "Soccer",
            time: "8:30 - 9:00 PM",
            duration: "30min",
            color: .defaultGreen,
            symbols: ["figure.indoor.soccer"]
        ),
    ]
}

#Preview {
    ExerciseCalendarWidget()
        .padding(.spacing4x)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.defaultBackground.ignoresSafeArea())
}
