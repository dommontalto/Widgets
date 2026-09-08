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
    var showsIcon: Bool
    // Nil for no dot; a day with sessions styles its dot by what they are.
    var dotStyle: (Date) -> AnyShapeStyle?
    var selectionColor: Color
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
        showsIcon: Bool = true,
        isWeekly: Bool = false,
        dotStyle: @escaping (Date) -> AnyShapeStyle? = { _ in nil },
        selectionColor: Color = .textColor,
        @ViewBuilder trailing: () -> Trailing
    ) {
        _selectedDate = selectedDate
        self.backgroundColor = backgroundColor
        self.showsIcon = showsIcon
        self.isWeekly = isWeekly
        self.dotStyle = dotStyle
        self.selectionColor = selectionColor
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
        VStack(spacing: .spacing2x) {
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
                if showsIcon {
                    Image(ImageNames.exerciseCalendarV5)
                        .resizable()
                        .scaledToFit()
                        .frame(width: Constants.iconSize, height: Constants.iconSize)
                        .foregroundStyle(Color.textColor)
                }
                BrightText(selectedDate.formatted(.brightCalendarDate), size: .body1, color: .semiLightTextColor, weight: .regular)
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
                    BrightHaptic.soft.play()
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
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: .spacing0x) {
                    ForEach(days, id: \.self) { date in
                        dayCell(date)
                            .containerRelativeFrame(.horizontal, count: Constants.visibleDays, span: 1, spacing: .spacing0x)
                            .id(date)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .defaultScrollAnchor(.center)
            .scrollPosition(id: $scrolledDay, anchor: .center)
            .scrollClipDisabled()
            .padding(.horizontal, .spacing2x)
            .onChange(of: scrolledDay) { _, day in
                guard let day, !day.isSameDay(as: selectedDate) else { return }
                BrightHaptic.soft.play()
                withAnimation(.brightSnappy) { selectedDate = day }
            }
            .onChange(of: selectedDate) { scrollToSelection() }
            .task { scrollToSelection() }
            .modifier(ReanchorOnWidthChange { recentre(with: proxy) })
        }
        .frame(height: Constants.calendarHeight)
    }

    private var weekStrip: some View {
        ScrollViewReader { proxy in
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
                        .id(week)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledWeek, anchor: .center)
            .onChange(of: selectedDate) { scrollToSelection() }
            .task { scrollToSelection() }
            .modifier(ReanchorOnWidthChange { recentre(with: proxy) })
        }
        .frame(height: Constants.calendarHeight)
    }

    private func dayCell(_ date: Date) -> some View {
        DayCell(
            date: date,
            isSelected: date.isSameDay(as: selectedDate),
            dotStyle: dotStyle(date),
            selectionColor: selectionColor,
            onTap: { tappedDate in
                BrightHaptic.soft.play()
                withAnimation(.brightSnappy) {
                    selectedDate = tappedDate
                }
            }
        )
    }

    private func daysOfWeek(startingAt week: Date) -> [Date] {
        (0..<Constants.daysInWeek).compactMap { calendar.date(byAdding: .day, value: $0, to: week) }
    }

    // The strip sizes its cells off the container width, and inside a pager
    // that width lands after the first layout pass — the offset picked for the
    // anchored day then points at a different day, so re-centre it by id.
    private func recentre(with proxy: ScrollViewProxy) {
        let target = isWeekly ? Self.weekStart(of: selectedDate) : calendar.startOfDay(for: selectedDate)
        proxy.scrollTo(target, anchor: .center)
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
        showsIcon: Bool = true,
        isWeekly: Bool = false,
        dotStyle: @escaping (Date) -> AnyShapeStyle? = { _ in nil },
        selectionColor: Color = .textColor
    ) {
        self.init(
            selectedDate: selectedDate,
            backgroundColor: backgroundColor,
            showsIcon: showsIcon,
            isWeekly: isWeekly,
            dotStyle: dotStyle,
            selectionColor: selectionColor,
            trailing: { EmptyView() }
        )
    }
}

private enum Constants {
    static let circleSize: CGFloat = .spacing7x
    static let ringInset: CGFloat = .spacing05x
    static let ringLineWidth: CGFloat = 1
    static let calendarHeight: CGFloat = 86
    static let dayRange = 365
    static let weekRange = 52
    static let daysInWeek = 7
    static let mondayIndex = 2
    static let visibleDays = 7
    static let iconSize: CGFloat = 24
    static let dotSize: CGFloat = 5
    static let dotLineWidth: CGFloat = 1
    static let circleRestScale: CGFloat = 0.8
}

private struct ReanchorOnWidthChange: ViewModifier {
    let onChange: () -> Void

    func body(content: Content) -> some View {
        content.onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.width } action: { _, _ in
            Task { @MainActor in onChange() }
        }
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let dotStyle: AnyShapeStyle?
    let selectionColor: Color
    let onTap: (Date) -> Void

    var body: some View {
        VStack(spacing: .spacing05x) {
            BrightText(date.formatted(.brightDay), size: .subheading, weight: .regular)
                .opacity(isSelected ? .opaque : .minimalOpacity)
                .frame(width: Constants.circleSize, height: Constants.circleSize)
                .background {
                    ZStack {
                        Circle()
                            .fill(selectionColor.opacity(.ultraLowOpacity))
                            .padding(Constants.ringInset)
                        Circle()
                            .strokeBorder(selectionColor.opacity(.lowOpacity), lineWidth: Constants.ringLineWidth)
                    }
                    .scaleEffect(isSelected ? 1 : Constants.circleRestScale)
                    .opacity(isSelected ? .opaque : 0)
                }

            // The number's circle frame leaves more empty space under the digit
            // than the initial has above its letter, so centre the dot between
            // the glyphs rather than the frames.
            dot
                .opacity(isSelected ? 0 : .opaque)
                .offset(y: -.spacing1x)

            BrightText(date.formatted(.brightWeekdayInitial), size: .body1, weight: .regular)
                .opacity(isSelected ? .opaque : .minimalOpacity)

            dot
                .opacity(isSelected ? .opaque : 0)
        }
        .animation(.brightBouncy, value: isSelected)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onTap(date) }
    }

    private var dot: some View {
        let fill = dotStyle ?? AnyShapeStyle(Color.clear)
        return Circle()
            .fill(fill.opacity(.minimalOpacity))
            .overlay {
                Circle()
                    .strokeBorder(fill.opacity(.lowOpacity), lineWidth: Constants.dotLineWidth)
            }
            .frame(width: Constants.dotSize, height: Constants.dotSize)
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
