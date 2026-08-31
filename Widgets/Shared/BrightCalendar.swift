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
    @ViewBuilder var trailing: Trailing

    @State private var position: ScrollPosition
    @State private var containerWidth: CGFloat = 0
    @State private var scrollSyncedDate: Date?

    private let calendar = Calendar.current
    private let days: [Date]

    init(
        selectedDate: Binding<Date>,
        backgroundColor: Color = .defaultBackground,
        dotStyle: @escaping (Date) -> AnyShapeStyle? = { _ in nil },
        @ViewBuilder trailing: () -> Trailing
    ) {
        _selectedDate = selectedDate
        self.backgroundColor = backgroundColor
        self.dotStyle = dotStyle
        self.trailing = trailing()
        _position = State(
            initialValue: ScrollPosition(
                id: Self.anchorDate(for: selectedDate.wrappedValue),
                anchor: .leading
            )
        )

        let calendar = Calendar.current
        let today = Date()
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
        VStack(spacing: .spacing1x) {
            headerView
                .padding(.horizontal, .spacing3x)

            calendarView
        }
        .padding(.bottom, .spacing1x)
        .background(backgroundColor)
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
                    selection: $selectedDate,
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

    private var calendarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: .spacing0x) {
                ForEach(days, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: date.isSameDay(as: selectedDate),
                        dotStyle: dotStyle(date),
                        onTap: { tappedDate in
                            BrightHaptic.light.play()
                            withAnimation(.brightSnappy) {
                                selectedDate = tappedDate
                            }
                        }
                    )
                    .frame(width: cellWidth)
                    .id(date)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition($position, anchor: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
        .onChange(of: containerWidth) { _, _ in scrollToSelection() }
        .onAppear { scrollToSelection() }
        .onChange(of: position.viewID(type: Date.self)) { _, newID in
            guard let newID else { return }
            let candidate = Self.selectedDate(forAnchor: newID)
            if !candidate.isSameDay(as: selectedDate) {
                BrightHaptic.light.play()
                scrollSyncedDate = candidate
                withAnimation(.brightSnappy) {
                    selectedDate = candidate
                }
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            guard scrollSyncedDate?.isSameDay(as: newDate) != true else {
                scrollSyncedDate = nil
                return
            }
            scrollToSelection(animated: true)
        }
        .frame(height: Constants.calendarHeight)
    }

    private var cellWidth: CGFloat {
        max(0, (containerWidth - .spacing3x * 2 - Constants.circleSize) / 6)
    }

    private func scrollToSelection(animated: Bool = false) {
        guard containerWidth > 0, let first = days.first else { return }

        let anchor = Self.anchorDate(for: selectedDate)
        guard let day = calendar.dateComponents([.day], from: first, to: anchor).day else { return }

        let x = CGFloat(min(max(day, 0), days.count - 1)) * cellWidth
        if animated {
            withAnimation(.brightSnappy) { position.scrollTo(x: x) }
        } else {
            position.scrollTo(x: x)
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

}

private enum Constants {
    static let circleSize: CGFloat = 30
    static let calendarHeight: CGFloat = 80
    static let selectedSlotIndex = 3
    static let iconSize: CGFloat = 24
    static let dotSize: CGFloat = 6
}

extension BrightCalendar where Trailing == EmptyView {
    init(
        selectedDate: Binding<Date>,
        backgroundColor: Color = .defaultBackground,
        dotStyle: @escaping (Date) -> AnyShapeStyle? = { _ in nil }
    ) {
        self.init(
            selectedDate: selectedDate,
            backgroundColor: backgroundColor,
            dotStyle: dotStyle,
            trailing: { EmptyView() }
        )
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let dotStyle: AnyShapeStyle?
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
                        .strokeBorder(Color.textColor, lineWidth: 1)
                        .frame(width: Constants.circleSize, height: Constants.circleSize)

                    BrightText(date.formatted(.brightDay), size: .body3, weight: .regular)
                }
                .opacity(isSelected ? .opaque : .minimalOpacity)

                Circle()
                    .fill(dotStyle ?? AnyShapeStyle(Color.clear))
                    .frame(width: Constants.dotSize, height: Constants.dotSize)
            }
        }
        .animation(.brightBouncy, value: isSelected)
        .padding(.leading, .spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
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
