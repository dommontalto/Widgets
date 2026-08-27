//
//  ExerciseCalendarSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import SwiftUI

struct ExerciseCalendarSheet: View {
    @Binding var selectedDate: Date

    // The binding's source of truth is the calendar widget behind this sheet;
    // writing to it live re-renders that hidden widget — blur transition and
    // all — for every day boundary a swipe crosses. The sheet works on a
    // local date and hands it back on close instead.
    @State private var sheetDate = Calendar.current.startOfDay(for: Date())

    @State private var timelinePosition = ScrollPosition()
    @State private var bannerShadowProgress: CGFloat = 0

    private let calendar = Calendar.current

    var body: some View {
        BrightPageSheetView(
            horizontalPadding: .spacing0x,
            content: {
                VStack(spacing: .spacing0x) {
                    BrightCalendar(
                        selectedDate: $sheetDate,
                        backgroundColor: .defaultSheetBackground,
                        dotStyle: { ExerciseCalendarDemo.dotStyle(on: $0) }
                    )

                    programBanner
                        .padding(.top, .spacing2x)

                    timeline
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        )
        .onAppear { sheetDate = selectedDate }
        .onDisappear { selectedDate = sheetDate }
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
            .background(Color.defaultSheetBackground)
            .brightCalendarDropShadow(progress: bannerShadowProgress)
            .zIndex(1)
    }

    private var timeline: some View {
        ScrollView(showsIndicators: false) {
            TimelineHourGrid()
                .equatable()
                .overlay(alignment: .top) {
                    eventsOverlay
                }
                .padding(.leading, .spacing3x)
                .padding(.top, .spacing4x)
        }
        .scrollPosition($timelinePosition)
        .onAppear {
            // Set only after the sheet has laid out — an initial value from
            // init is applied while the scroll view has no size and is lost.
            timelinePosition.scrollTo(y: openingOffset)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            bannerShadowProgress = BrightCalendarDropShadow.progress(forOffset: offset)
        }
    }

    private var eventsOverlay: some View {
        ZStack(alignment: .top) {
            ForEach(ExerciseCalendarDemo.events(on: sheetDate)) { event in
                eventView(event)
                    .padding(.leading, Constants.gutterWidth)
                    .padding(.trailing, .spacing1x)
                    .frame(height: eventHeight(event))
                    .offset(y: eventOffset(event))
                    .transition(.blurReplace)
            }

            if calendar.isDateInToday(sheetDate) {
                nowIndicator
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(.brightEaseInOut, value: sheetDate)
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

            Rectangle()
                .fill(Color.defaultYellow)
                .frame(height: Constants.nowLineHeight)
        }
        .offset(y: timelineY(atMinutes: minutes) - Constants.nowPillHeight / 2)
    }

    private func eventOffset(_ event: ExerciseCalendarEvent) -> CGFloat {
        timelineY(atMinutes: event.startMinutes) + .spacing05x
    }

    private func eventHeight(_ event: ExerciseCalendarEvent) -> CGFloat {
        CGFloat(event.durationMinutes) / 60 * Constants.hourHeight - .spacing1x
    }

    // Opens with the current time an hour and a half down the timeline.
    private var openingOffset: CGFloat {
        let now = Date()
        let minutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        return max(0, timelineY(atMinutes: minutes - Constants.openingLeadMinutes) + .spacing4x)
    }

    private func timelineY(atMinutes minutes: Int) -> CGFloat {
        CGFloat(minutes - Constants.startHour * 60) / 60 * Constants.hourHeight
    }

    enum Constants {
        static let bannerHeight: CGFloat = 30
        static let hatchLineWidth: CGFloat = 1.4
        static let hatchStep: CGFloat = 5.7
        static let hatchRun: CGFloat = 0.75
        static let startHour = 0
        static let openingLeadMinutes = 90
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
    }
}

// The hour grid never changes, but it sits inside a body that re-renders
// twice per day crossed while swiping the calendar — always-equal Equatable
// lets SwiftUI skip re-diffing its 24 rows on every one of those passes.
private struct TimelineHourGrid: View, Equatable {
    typealias Constants = ExerciseCalendarSheet.Constants

    var body: some View {
        VStack(spacing: .spacing0x) {
            ForEach(Constants.startHour...Constants.endHour, id: \.self) { hour in
                hourRow(hour)
                    .frame(height: Constants.hourHeight, alignment: .top)
                    .id(hour)
            }
        }
        .scrollTargetLayout()
    }

    private func hourRow(_ hour: Int) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.textColor.opacity(.ultraLowOpacity))
                .frame(height: 1)
                .padding(.leading, Constants.gutterWidth)

            HStack(spacing: .spacing05x) {
                BrightText("\(hour % 12 == 0 ? 12 : hour % 12)", size: .body2, weight: .regular)
                    .monospacedDigit()
                    .frame(width: Constants.hourLabelWidth, alignment: .trailing)
                BrightText(hour < 12 ? "AM" : "PM", size: .body2, weight: .regular)
                    .opacity(.semiLowOpacity)
            }
            .offset(y: -Constants.hourLabelOffset)
        }
    }

    static func == (_: Self, _: Self) -> Bool { true }
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

#Preview {
    @Previewable @State var selectedDate = Calendar.current.startOfDay(for: Date())
    Color.defaultBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ExerciseCalendarSheet(selectedDate: $selectedDate)
        }
}
