//
//  ExerciseCalendarSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import SwiftUI

struct ExerciseCalendarSheet: View {
    @Binding var selectedDate: Date

    @State private var scrolledID: Date?
    @State private var topHour: Int?

    private let calendar = Calendar.current
    private let days: [Date]

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        _scrolledID = State(initialValue: Self.anchorDate(for: selectedDate.wrappedValue))

        let nowHour = Calendar.current.component(.hour, from: Date())
        _topHour = State(initialValue: max(Constants.startHour, nowHour - 2))

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
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
        BrightPageSheetView(
            horizontalPadding: .spacing0x,
            content: {
                VStack(spacing: .spacing0x) {
                    headerView
                        .padding(.horizontal, .spacing3x)

                    weekStrip
                        .padding(.top, .spacing3x)

                    programBanner
                        .padding(.top, .spacing2x)

                    timeline
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        )
    }

    private var headerView: some View {
        HStack(spacing: .spacing105x) {
            Image(ImageNames.exerciseCalendarV5)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.headerIconSize, height: Constants.headerIconSize)
                .foregroundStyle(Color.textColor)

            BrightText(selectedDate.formatted(.brightDate), size: .body2, weight: .regular)
                .contentTransition(.numericText())
                .animation(.brightSnappy, value: selectedDate)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weekStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: .spacing0x) {
                ForEach(days, id: \.self) { date in
                    SheetDayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        hasSession: !ExerciseCalendarSheetDemo.events(on: date).isEmpty,
                        onTap: { tappedDate in
                            BrightHaptic.light.play()
                            withAnimation(.brightSnappy) {
                                selectedDate = tappedDate
                                scrolledID = Self.anchorDate(for: tappedDate)
                            }
                        }
                    )
                    .containerRelativeFrame(.horizontal) { length, _ in
                        (length - .spacing3x * 2 - Constants.circleSize) / 6
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
        .frame(height: Constants.stripHeight)
    }

    private var programBanner: some View {
        BrightText("PROGRAM: WEEK 2/8", size: .body2, color: .defaultGreen, weight: .regular)
            .padding(.leading, .spacing3x)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: Constants.bannerHeight)
            .background {
                DiagonalHatch()
                    .stroke(Color.defaultGreen, lineWidth: Constants.hatchLineWidth)
                    .opacity(.veryMinimalOpacity)
            }
            .clipped()
    }

    private var timeline: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: .spacing0x) {
                ForEach(Constants.startHour...Constants.endHour, id: \.self) { hour in
                    hourRow(hour)
                        .frame(height: Constants.hourHeight, alignment: .top)
                        .id(hour)
                }
            }
            .scrollTargetLayout()
            .overlay(alignment: .top) {
                eventsOverlay
            }
            .padding(.leading, .spacing3x)
            .padding(.top, .spacing4x)
        }
        .scrollPosition(id: $topHour, anchor: .top)
        .overlay(alignment: .bottomTrailing) {
            BrightRoundButton(systemImage: "plus", size: .finalBossLarge) {}
                .padding(.trailing, .spacing4x)
                .padding(.bottom, .spacing2x)
        }
    }

    private func hourRow(_ hour: Int) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.textColor.opacity(.ultraLowOpacity))
                .frame(height: 1)
                .padding(.leading, Constants.gutterWidth)

            HStack(spacing: .spacing05x) {
                BrightText("\(hour == 12 ? 12 : hour % 12)", size: .body2, weight: .regular)
                    .monospacedDigit()
                    .frame(width: Constants.hourLabelWidth, alignment: .trailing)
                BrightText(hour < 12 ? "AM" : "PM", size: .body2, weight: .regular)
                    .opacity(.semiLowOpacity)
            }
            .offset(y: -Constants.hourLabelOffset)
        }
    }

    private var eventsOverlay: some View {
        ZStack(alignment: .top) {
            ForEach(ExerciseCalendarSheetDemo.events(on: selectedDate)) { event in
                eventView(event)
                    .padding(.leading, Constants.gutterWidth)
                    .padding(.trailing, .spacing1x)
                    .frame(height: eventHeight(event))
                    .offset(y: eventOffset(event))
                    .transition(.blurReplace)
            }

            sunsetMarker

            if calendar.isDateInToday(selectedDate) {
                nowIndicator
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(.brightEaseInOut, value: selectedDate)
    }

    @ViewBuilder private func eventView(_ event: ExerciseCalendarEvent) -> some View {
        let isCompact = event.durationMinutes < Constants.compactThresholdMinutes
        HStack(spacing: .spacing105x) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(event.color)
                .frame(width: 2, height: isCompact ? Constants.compactBarHeight : Constants.barHeight)

            if isCompact {
                BrightText(event.name, size: .body2, color: event.color, weight: .regular)
                Spacer()
                detailLabel(event)
            } else {
                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(event.name, size: .body2, color: event.color, weight: .regular)
                    detailLabel(event)
                }
                Spacer()
            }
        }
        .padding(.horizontal, .spacing105x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            event.color.opacity(.ultraLowOpacity),
            in: RoundedRectangle(cornerRadius: isCompact ? .cornerRadius9 : .cornerRadius14, style: .continuous)
        )
    }

    private func detailLabel(_ event: ExerciseCalendarEvent) -> some View {
        HStack(spacing: .spacing05x) {
            if let icon = event.detailIcon {
                Image(systemName: icon)
                    .font(.standard(size: .body2, weight: .light))
                    .foregroundStyle(event.color)
            }
            BrightText(event.detail, size: .body2, color: event.color)
        }
    }

    private var nowIndicator: some View {
        let now = Date()
        let minutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        return HStack(spacing: .spacing0x) {
            BrightText(now.formatted(.brightTime24), size: .body2, color: .defaultBlack, weight: .regular)
                .monospacedDigit()
                .frame(width: Constants.nowPillWidth, height: Constants.nowPillHeight)
                .background(Color.defaultYellow, in: Capsule())
                .overlay(alignment: .top) {
                    Image(systemName: "sun.max.fill")
                        .font(.standard(size: .body2, weight: .regular))
                        .foregroundStyle(Color.textColor)
                        .offset(y: -Constants.nowPillHeight * 0.7)
                }

            Rectangle()
                .fill(Color.defaultYellow)
                .frame(height: Constants.nowLineHeight)
        }
        .offset(y: timelineY(atMinutes: minutes) - Constants.nowPillHeight / 2)
    }

    private var sunsetMarker: some View {
        Image(systemName: "sunset.fill")
            .font(.standard(size: .body2, weight: .regular))
            .foregroundStyle(Color.textColor)
            .frame(width: Constants.gutterWidth)
            .offset(y: timelineY(atMinutes: Constants.sunsetMinutes) - Constants.hourLabelOffset)
    }

    private func eventOffset(_ event: ExerciseCalendarEvent) -> CGFloat {
        timelineY(atMinutes: event.startMinutes) + .spacing05x
    }

    private func eventHeight(_ event: ExerciseCalendarEvent) -> CGFloat {
        CGFloat(event.durationMinutes) / 60 * Constants.hourHeight - .spacing1x
    }

    private func timelineY(atMinutes minutes: Int) -> CGFloat {
        CGFloat(minutes - Constants.startHour * 60) / 60 * Constants.hourHeight
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
        static let selectedSlotIndex = 3
        static let circleSize: CGFloat = 30
        static let dotSize: CGFloat = 6
        static let stripHeight: CGFloat = 78
        static let headerIconSize: CGFloat = 24
        static let bannerHeight: CGFloat = 30
        static let hatchLineWidth: CGFloat = 1.4
        static let hatchStep: CGFloat = 5.7
        static let hatchRun: CGFloat = 0.75
        static let startHour = 6
        static let endHour = 23
        static let hourHeight: CGFloat = 65
        static let gutterWidth: CGFloat = 66
        static let hourLabelWidth: CGFloat = 21
        static let hourLabelOffset: CGFloat = 9
        static let barHeight: CGFloat = 35
        static let compactBarHeight: CGFloat = 16
        static let compactThresholdMinutes = 45
        static let nowPillWidth: CGFloat = 48
        static let nowPillHeight: CGFloat = 28
        static let nowLineHeight: CGFloat = 1.5
        static let sunsetMinutes = 17 * 60 + 45
    }
}

private struct SheetDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasSession: Bool
    let onTap: (Date) -> Void

    var body: some View {
        VStack(spacing: .spacing2x) {
            BrightText(
                date.formatted(.brightWeekdayInitial),
                size: .subheading1,
                weight: isSelected ? .medium : .regular
            )
            .opacity(isSelected ? .opaque : .minimalOpacity)

            VStack(spacing: .spacing1x) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.textColor, lineWidth: 1)

                    BrightText(date.formatted(.brightDay), size: .body3, weight: .regular)
                }
                .frame(
                    width: ExerciseCalendarSheet.Constants.circleSize,
                    height: ExerciseCalendarSheet.Constants.circleSize
                )
                .opacity(isSelected ? .opaque : .minimalOpacity)

                Circle()
                    .fill(Color.defaultGreen)
                    .frame(
                        width: ExerciseCalendarSheet.Constants.dotSize,
                        height: ExerciseCalendarSheet.Constants.dotSize
                    )
                    .opacity(hasSession ? .opaque : 0)
            }
        }
        .animation(.brightBouncy, value: isSelected)
        .padding(.leading, .spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { onTap(date) }
    }
}

private struct DiagonalHatch: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let run = rect.height * ExerciseCalendarSheet.Constants.hatchRun
        var x = -run
        while x < rect.width {
            path.move(to: CGPoint(x: x, y: rect.height))
            path.addLine(to: CGPoint(x: x + run, y: 0))
            x += ExerciseCalendarSheet.Constants.hatchStep
        }
        return path
    }
}

struct ExerciseCalendarEvent: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let detailIcon: String?
    let startMinutes: Int
    let durationMinutes: Int
    let color: Color
}

enum ExerciseCalendarSheetDemo {
    static func events(on date: Date) -> [ExerciseCalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let offset = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: date)).day ?? 0
        return eventsByOffset[offset] ?? []
    }

    private static let eventsByOffset: [Int: [ExerciseCalendarEvent]] = [
        -2: [
            ExerciseCalendarEvent(
                name: "Soccer", detail: "30 Mins", detailIcon: "stopwatch",
                startMinutes: 18 * 60, durationMinutes: 60, color: .defaultGreen
            ),
        ],
        0: [
            ExerciseCalendarEvent(
                name: "Soccer", detail: "30 Mins", detailIcon: "stopwatch",
                startMinutes: 11 * 60, durationMinutes: 60, color: .defaultGreen
            ),
            ExerciseCalendarEvent(
                name: "Push Pull Split", detail: "1hr 30min", detailIcon: "stopwatch",
                startMinutes: 13 * 60, durationMinutes: 60, color: .defaultPurple
            ),
            ExerciseCalendarEvent(
                name: "Push Pull Split", detail: "1hr 30min", detailIcon: "stopwatch",
                startMinutes: 15 * 60, durationMinutes: 27, color: .defaultPurple
            ),
            ExerciseCalendarEvent(
                name: "Warmdown Walk", detail: "Free walk", detailIcon: nil,
                startMinutes: 15 * 60 + 30, durationMinutes: 25, color: .defaultSkyBlue
            ),
            ExerciseCalendarEvent(
                name: "5K run", detail: "40 Mins", detailIcon: "stopwatch",
                startMinutes: 17 * 60, durationMinutes: 60, color: .defaultSkyBlue
            ),
        ],
        1: [
            ExerciseCalendarEvent(
                name: "5K run", detail: "30 Mins", detailIcon: "stopwatch",
                startMinutes: 6 * 60 + 30, durationMinutes: 30, color: .defaultSkyBlue
            ),
        ],
        3: [
            ExerciseCalendarEvent(
                name: "Soccer", detail: "30 Mins", detailIcon: "stopwatch",
                startMinutes: 20 * 60 + 30, durationMinutes: 30, color: .defaultGreen
            ),
        ],
    ]
}

#Preview {
    @Previewable @State var selectedDate = Calendar.current.startOfDay(for: Date())
    Color.defaultBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ExerciseCalendarSheet(selectedDate: $selectedDate)
        }
}
