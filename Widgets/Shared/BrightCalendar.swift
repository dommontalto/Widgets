//
//  BrightCalendar.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import SwiftUI

struct BrightCalendar<Trailing: View>: View {
    @Binding var selectedDate: Date
    var backgroundColor: Color
    // Nil for no dot; a day with sessions styles its dot by what they are.
    var dotStyle: (Date) -> AnyShapeStyle?
    var isWeekly: Bool
    @ViewBuilder var trailing: Trailing

    @State private var scrolledDay: Date?
    @State private var scrolledWeek: Date?

    private let calendar = Calendar.current
    private let days: [Date]
    private let weeks: [Date]

    init(
        selectedDate: Binding<Date>,
        backgroundColor: Color = .defaultBackground,
        isWeekly: Bool = false,
        dotStyle: @escaping (Date) -> AnyShapeStyle? = { _ in nil },
        @ViewBuilder trailing: () -> Trailing
    ) {
        _selectedDate = selectedDate
        self.backgroundColor = backgroundColor
        self.isWeekly = isWeekly
        self.dotStyle = dotStyle
        self.trailing = trailing()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        days = (-Constants.dayRange...Constants.dayRange).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
        let currentWeek = Self.weekStart(of: today)
        weeks = (-Constants.weekRange...Constants.weekRange).compactMap {
            calendar.date(byAdding: .weekOfYear, value: $0, to: currentWeek)
        }
        _scrolledDay = State(initialValue: calendar.startOfDay(for: selectedDate.wrappedValue))
        _scrolledWeek = State(initialValue: Self.weekStart(of: selectedDate.wrappedValue))
    }

    private static func weekStart(of date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = Constants.mondayIndex
        return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    var body: some View {
        VStack(spacing: .spacing1x) {
            headerView
                .padding(.horizontal, .spacing3x)

            calendarView
        }
        .padding(.bottom, .spacing1x)
        .background(backgroundColor)
    }

    private var pickedDate: Binding<Date> {
        Binding {
            selectedDate
        } set: {
            selectedDate = calendar.startOfDay(for: $0)
        }
    }

    private var headerView: some View {
        HStack(spacing: .spacing2x) {
            HStack(spacing: .spacing2x) {
                Image(ImageNames.exerciseCalendarV5)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundStyle(Color.textColor)
                BrightText(selectedDate.formatted(.brightDate), size: .body1, weight: .regular)
                    .contentTransition(.numericText())
                    .animation(.brightSnappy, value: selectedDate)
            }
            .overlay {
                DatePicker(
                    "",
                    selection: pickedDate,
                    displayedComponents: .date
                )
                .tint(.textColor)
                .datePickerStyle(.compact)
                .labelsHidden()
                .blendMode(.destinationOver)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Spacer()

            if !selectedDate.isToday {
                BrightPillButton(
                    "Today",
                    systemImage: "arrow.uturn.left",
                    buttonSize: .small
                ) {
                    BrightHaptic.light.play()
                    withAnimation(.brightSnappy) {
                        selectedDate = calendar.startOfDay(for: Date())
                    }
                }
                .transition(.opacity.animation(.brightEaseInOut))
            }

            trailing
        }
        .frame(minHeight: 31)
        .animation(.brightEaseInOut, value: selectedDate.isToday)
    }

    @ViewBuilder private var calendarView: some View {
        if isWeekly {
            weekStrip
        } else {
            dayStrip
        }
    }

    private var dayStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: .spacing0x) {
                ForEach(days, id: \.self) { date in
                    dayCell(date)
                        .containerRelativeFrame(.horizontal, count: Constants.visibleDays, span: 1, spacing: .spacing0x)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .defaultScrollAnchor(.center)
        .scrollPosition(id: $scrolledDay, anchor: .center)
        .onChange(of: scrolledDay) { _, day in
            guard let day, !day.isSameDay(as: selectedDate) else { return }
            BrightHaptic.light.play()
            withAnimation(.brightSnappy) { selectedDate = day }
        }
        .onChange(of: selectedDate) { scrollToSelection() }
        .task { scrollToSelection() }
        .frame(height: Constants.calendarHeight)
    }

    private var weekStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: .spacing0x) {
                ForEach(weeks, id: \.self) { week in
                    HStack(spacing: .spacing0x) {
                        ForEach(daysOfWeek(startingAt: week), id: \.self) { date in
                            dayCell(date)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, .spacing2x)
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolledWeek, anchor: .center)
        .onChange(of: selectedDate) { scrollToSelection() }
        .task { scrollToSelection() }
        .frame(height: Constants.calendarHeight)
    }

    private func dayCell(_ date: Date) -> some View {
        DayCell(
            date: date,
            isSelected: date.isSameDay(as: selectedDate),
            dotStyle: dotStyle(date),
            isWeekly: isWeekly,
            onTap: { tappedDate in
                BrightHaptic.light.play()
                withAnimation(.brightSnappy) {
                    selectedDate = tappedDate
                }
            }
        )
    }

    private func daysOfWeek(startingAt week: Date) -> [Date] {
        (0..<Constants.daysInWeek).compactMap { calendar.date(byAdding: .day, value: $0, to: week) }
    }

    private func scrollToSelection() {
        if isWeekly {
            let week = Self.weekStart(of: selectedDate)
            guard week != scrolledWeek else { return }
            withAnimation(.brightSnappy) { scrolledWeek = week }
        } else {
            let day = calendar.startOfDay(for: selectedDate)
            guard day != scrolledDay else { return }
            withAnimation(.brightSnappy) { scrolledDay = day }
        }
    }
}

extension BrightCalendar where Trailing == EmptyView {
    init(
        selectedDate: Binding<Date>,
        backgroundColor: Color = .defaultBackground,
        isWeekly: Bool = false,
        dotStyle: @escaping (Date) -> AnyShapeStyle? = { _ in nil }
    ) {
        self.init(
            selectedDate: selectedDate,
            backgroundColor: backgroundColor,
            isWeekly: isWeekly,
            dotStyle: dotStyle,
            trailing: { EmptyView() }
        )
    }
}

private enum Constants {
    static let circleSize: CGFloat = 30
    static let calendarHeight: CGFloat = 80
    static let dayRange = 365
    static let weekRange = 52
    static let daysInWeek = 7
    static let mondayIndex = 2
    static let visibleDays = 7
    static let iconSize: CGFloat = 24
    static let dotSize: CGFloat = 6
    static let circleScale: CGFloat = 1
    static let circleRestScale: CGFloat = 0.4
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let dotStyle: AnyShapeStyle?
    let isWeekly: Bool
    let onTap: (Date) -> Void

    var body: some View {
        VStack(spacing: .spacing2x) {
            BrightText(
                date.formatted(.brightWeekdayInitial),
                size: .subheading1,
                weight: isSelected ? .medium : .regular
            )
            .opacity(isSelected ? .opaque : .minimalOpacity)

            VStack(spacing: .spacing105x) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.textColor : .clear)
                        .frame(width: Constants.circleSize, height: Constants.circleSize)
                        .scaleEffect(isSelected ? Constants.circleScale : Constants.circleRestScale)

                    BrightText(
                        date.formatted(.brightDay),
                        size: .body3,
                        color: isSelected ? .defaultBlackWhite : .textColor,
                        weight: .regular
                    )
                    .opacity(isSelected ? .opaque : .minimalOpacity)
                }

                Circle()
                    .fill(dotStyle ?? AnyShapeStyle(Color.clear))
                    .frame(width: Constants.dotSize, height: Constants.dotSize)
            }
        }
        .animation(.brightBouncy, value: isSelected)
        .padding(.leading, isWeekly ? .spacing0x : .spacing3x)
        .frame(maxWidth: .infinity, alignment: isWeekly ? .center : .leading)
        .contentShape(Rectangle())
        .onTapGesture { onTap(date) }
    }
}

#Preview {
    @Previewable @State var selectedDate = Calendar.current.startOfDay(for: Date())
    BrightCalendar(selectedDate: $selectedDate) { date in
        ExerciseCalendarDemo.dotStyle(on: date)
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultBackground.ignoresSafeArea())
}
