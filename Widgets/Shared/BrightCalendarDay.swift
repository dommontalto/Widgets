//
//  BrightCalendarDay.swift
//  Widgets
//
//  Created by Dom Montalto on 1/9/2026.
//

import SwiftUI

struct BrightCalendarDayEvent: Identifiable, Equatable {
    let id: String
    let name: String
    let detail: String
    let detailIcon: String?
    let startMinutes: Int
    let durationMinutes: Int
    let color: Color
}

struct BrightCalendarDay: View {
    @Binding var selectedDate: Date
    var backgroundColor: Color = .defaultBackground
    var dotStyle: (Date) -> AnyShapeStyle? = { _ in nil }
    var events: [BrightCalendarDayEvent] = []
    var onEventTap: ((BrightCalendarDayEvent) -> Void)? = nil

    @State private var topHour: Int?
    @State private var calendarShadowProgress: CGFloat = 0

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: .spacing0x) {
            BrightCalendar(
                selectedDate: $selectedDate,
                backgroundColor: backgroundColor,
                dotStyle: dotStyle
            )
            .brightCalendarDropShadow(progress: calendarShadowProgress)
            .zIndex(1)

            timeline
        }
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
        .scrollPosition(id: $topHour, anchor: .top)
        .onAppear { retargetScroll() }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            calendarShadowProgress = BrightCalendarDropShadow.progress(forOffset: offset)
        }
    }

    private var eventsOverlay: some View {
        ZStack(alignment: .top) {
            ForEach(eventClusters) { cluster in
                clusterView(cluster)
                    .padding(.leading, Constants.gutterWidth)
                    .padding(.trailing, .spacing1x)
                    .frame(height: clusterHeight(cluster), alignment: .top)
                    .offset(y: timelineY(atMinutes: cluster.startMinutes) + .spacing05x)
                    .transition(.blurReplace)
            }

            if calendar.isDateInToday(selectedDate) {
                nowIndicator
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(.brightEaseInOut, value: events)
        .animation(.brightEaseInOut, value: selectedDate)
    }

    private func clusterView(_ cluster: EventCluster) -> some View {
        HStack(alignment: .top, spacing: .spacing05x) {
            ForEach(cluster.columns.indices, id: \.self) { index in
                ZStack(alignment: .top) {
                    ForEach(cluster.columns[index]) { event in
                        eventView(event)
                            .frame(height: eventHeight(event))
                            .offset(y: relativeY(of: event, in: cluster))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }

    private func eventView(_ event: BrightCalendarDayEvent) -> some View {
        Button {
            onEventTap?(event)
        } label: {
            eventLabel(event)
        }
        .buttonStyle(EventButtonStyle())
        .allowsHitTesting(onEventTap != nil)
    }

    @ViewBuilder private func eventLabel(_ event: BrightCalendarDayEvent) -> some View {
        let isCompact = effectiveDuration(of: event) < Constants.compactThresholdMinutes
        HStack(spacing: .spacing105x) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(event.color)
                .frame(width: 2, height: isCompact ? Constants.compactBarHeight : Constants.barHeight)

            if isCompact {
                BrightText(event.name, size: .body2, color: event.color, weight: .regular)
                    .lineLimit(1)
                Spacer()
                detailLabel(event)
            } else {
                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(event.name, size: .body2, color: event.color, weight: .regular)
                        .lineLimit(1)
                    detailLabel(event)
                }
                Spacer()
            }
        }
        .padding(.horizontal, .spacing105x)
        .padding(.vertical, isCompact ? .spacing0x : .spacing105x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isCompact ? .leading : .topLeading)
        .background(
            event.color.opacity(.ultraLowOpacity),
            in: RoundedRectangle(cornerRadius: isCompact ? .cornerRadius9 : .cornerRadius14, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: isCompact ? .cornerRadius9 : .cornerRadius14, style: .continuous))
    }

    private func detailLabel(_ event: BrightCalendarDayEvent) -> some View {
        HStack(spacing: .spacing05x) {
            if let icon = event.detailIcon {
                Image(systemName: icon)
                    .font(.standard(size: .body2, weight: .light))
                    .foregroundStyle(event.color)
            }
            BrightText(event.detail, size: .body2, color: event.color)
                .lineLimit(1)
        }
    }

    private var nowIndicator: some View {
        TimelineView(.everyMinute) { context in
            let minutes = calendar.component(.hour, from: context.date) * 60
                + calendar.component(.minute, from: context.date)
            HStack(spacing: .spacing0x) {
                BrightText(context.date.formatted(.brightTime24), size: .body2, color: .defaultBlack, weight: .regular)
                    .monospacedDigit()
                    .frame(width: Constants.nowPillWidth, height: Constants.nowPillHeight)
                    .background(Color.defaultYellow, in: Capsule())

                Rectangle()
                    .fill(Color.defaultYellow)
                    .frame(height: Constants.nowLineHeight)
            }
            .offset(y: timelineY(atMinutes: minutes) - Constants.nowPillHeight / 2)
        }
        .allowsHitTesting(false)
    }

    private struct EventCluster: Identifiable {
        let columns: [[BrightCalendarDayEvent]]
        let startMinutes: Int
        let endMinutes: Int

        var id: String {
            columns.flatMap { $0 }.map(\.id).joined(separator: "|")
        }
    }

    private var eventClusters: [EventCluster] {
        let sorted = events.sorted { ($0.startMinutes, $0.id) < ($1.startMinutes, $1.id) }
        var clusters: [EventCluster] = []
        var columns: [[BrightCalendarDayEvent]] = []
        var clusterStart = 0
        var clusterEnd = 0

        func closeCluster() {
            guard !columns.isEmpty else { return }
            clusters.append(EventCluster(columns: columns, startMinutes: clusterStart, endMinutes: clusterEnd))
            columns = []
        }

        for event in sorted {
            let end = event.startMinutes + effectiveDuration(of: event)
            if columns.isEmpty || event.startMinutes >= clusterEnd {
                closeCluster()
                columns = [[event]]
                clusterStart = event.startMinutes
                clusterEnd = end
            } else {
                let openColumn = columns.firstIndex { column in
                    guard let last = column.last else { return true }
                    return last.startMinutes + effectiveDuration(of: last) <= event.startMinutes
                }
                if let openColumn {
                    columns[openColumn].append(event)
                } else {
                    columns.append([event])
                }
                clusterEnd = max(clusterEnd, end)
            }
        }
        closeCluster()
        return clusters
    }

    private func retargetScroll() {
        if calendar.isDateInToday(selectedDate) {
            topHour = max(Constants.startHour, calendar.component(.hour, from: Date()) - 1)
        } else if let firstStart = events.map(\.startMinutes).min() {
            topHour = max(Constants.startHour, firstStart / 60 - 1)
        } else {
            topHour = Constants.emptyDayTopHour
        }
    }

    private func effectiveDuration(of event: BrightCalendarDayEvent) -> Int {
        let capped = min(event.durationMinutes, (Constants.endHour + 1) * 60 - event.startMinutes)
        return max(capped, Constants.minimumEventMinutes)
    }

    private func relativeY(of event: BrightCalendarDayEvent, in cluster: EventCluster) -> CGFloat {
        CGFloat(event.startMinutes - cluster.startMinutes) / 60 * Constants.hourHeight
    }

    private func clusterHeight(_ cluster: EventCluster) -> CGFloat {
        CGFloat(cluster.endMinutes - cluster.startMinutes) / 60 * Constants.hourHeight
    }

    private func eventHeight(_ event: BrightCalendarDayEvent) -> CGFloat {
        CGFloat(effectiveDuration(of: event)) / 60 * Constants.hourHeight - .spacing1x
    }

    private func timelineY(atMinutes minutes: Int) -> CGFloat {
        CGFloat(minutes - Constants.startHour * 60) / 60 * Constants.hourHeight
    }

    enum Constants {
        static let startHour = 0
        static let endHour = 23
        static let hourHeight: CGFloat = 65
        static let gutterWidth: CGFloat = 66
        static let hourLabelWidth: CGFloat = 21
        static let hourLabelOffset: CGFloat = 9
        static let barHeight: CGFloat = 35
        static let compactBarHeight: CGFloat = 16
        static let compactThresholdMinutes = 45
        static let minimumEventMinutes = 30
        static let emptyDayTopHour = 7
        static let nowPillWidth: CGFloat = 48
        static let nowPillHeight: CGFloat = 28
        static let nowLineHeight: CGFloat = 1.5
    }
}

private struct EventButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.brightBouncy, value: configuration.isPressed)
    }
}

private struct TimelineHourGrid: View, Equatable {
    typealias Constants = BrightCalendarDay.Constants

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

#Preview {
    @Previewable @State var selectedDate = Calendar.current.startOfDay(for: Date())
    BrightCalendarDay(
        selectedDate: $selectedDate,
        events: [
            BrightCalendarDayEvent(
                id: "breakfast",
                name: "Breakfast",
                detail: "420 cal",
                detailIcon: nil,
                startMinutes: 7 * 60 + 30,
                durationMinutes: 0,
                color: .defaultGreen
            ),
            BrightCalendarDayEvent(
                id: "run",
                name: "Morning run",
                detail: "45min",
                detailIcon: "stopwatch",
                startMinutes: 9 * 60,
                durationMinutes: 45,
                color: .defaultSkyBlueCyan
            ),
            BrightCalendarDayEvent(
                id: "water",
                name: "Water",
                detail: "600 ml",
                detailIcon: nil,
                startMinutes: 9 * 60 + 15,
                durationMinutes: 0,
                color: .defaultBlue
            ),
            BrightCalendarDayEvent(
                id: "push",
                name: "Push day",
                detail: "1hr 30min",
                detailIcon: "stopwatch",
                startMinutes: 18 * 60,
                durationMinutes: 90,
                color: .defaultPurple
            ),
        ],
        onEventTap: { _ in }
    )
    .background(Color.defaultBackground.ignoresSafeArea())
}
