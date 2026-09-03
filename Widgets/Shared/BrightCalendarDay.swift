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
    var isWeekly: Bool = false
    var events: (Date) -> [BrightCalendarDayEvent] = { _ in [] }
    var onEventTap: ((BrightCalendarDayEvent) -> Void)? = nil
    var onEventDelete: ((BrightCalendarDayEvent) -> Void)? = nil

    @State private var timelinePosition = ScrollPosition()
    @State private var pagedDay: Date?
    @State private var edgeProgress: CGFloat = 0

    private let calendar = Calendar.current
    private let pageDays: [Date]

    init(
        selectedDate: Binding<Date>,
        backgroundColor: Color = .defaultBackground,
        dotStyle: @escaping (Date) -> AnyShapeStyle? = { _ in nil },
        isWeekly: Bool = false,
        events: @escaping (Date) -> [BrightCalendarDayEvent] = { _ in [] },
        onEventTap: ((BrightCalendarDayEvent) -> Void)? = nil,
        onEventDelete: ((BrightCalendarDayEvent) -> Void)? = nil
    ) {
        _selectedDate = selectedDate
        self.backgroundColor = backgroundColor
        self.dotStyle = dotStyle
        self.isWeekly = isWeekly
        self.events = events
        self.onEventTap = onEventTap
        self.onEventDelete = onEventDelete
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        pageDays = (-Constants.dayRange...Constants.dayRange).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
        _pagedDay = State(initialValue: calendar.startOfDay(for: selectedDate.wrappedValue))
    }

    var body: some View {
        VStack(spacing: .spacing0x) {
            BrightCalendar(
                selectedDate: $selectedDate,
                backgroundColor: backgroundColor,
                isWeekly: isWeekly,
                dotStyle: dotStyle
            )
            .brightCalendarEdge(progress: edgeProgress)
            .zIndex(1)

            timeline
        }
    }

    private var timeline: some View {
        ScrollView(showsIndicators: false) {
            pager
        }
        .scrollPosition($timelinePosition)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            let progress = BrightCalendarEdge.progress(forOffset: offset)
            guard progress != edgeProgress else { return }
            edgeProgress = progress
        }
        .task {
            retargetScroll()
            syncPage()
        }
    }

    private var pager: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: .spacing0x) {
                ForEach(pageDays, id: \.self) { day in
                    page(for: day)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $pagedDay, anchor: .center)
        .frame(height: Constants.timelineHeight + Constants.topInset)
        .onChange(of: pagedDay) { _, day in
            guard let day, !day.isSameDay(as: selectedDate) else { return }
            BrightHaptic.light.play()
            withAnimation(.brightSnappy) { selectedDate = day }
        }
        .onChange(of: selectedDate) { syncPage() }
    }

    private func page(for day: Date) -> some View {
        TimelineHourGrid()
            .equatable()
            .overlay(alignment: .top) {
                eventsOverlay(for: day)
            }
            .padding(.leading, .spacing3x)
            .padding(.top, Constants.topInset)
    }

    private func syncPage() {
        let day = calendar.startOfDay(for: selectedDate)
        guard day != pagedDay else { return }
        let isAdjacent = abs(calendar.dateComponents([.day], from: pagedDay ?? day, to: day).day ?? 0) <= 1
        if isAdjacent {
            withAnimation(.brightSnappy) { pagedDay = day }
        } else {
            pagedDay = day
        }
    }

    private func eventsOverlay(for day: Date) -> some View {
        let dayEvents = events(day)
        return ZStack(alignment: .top) {
            ForEach(eventClusters(of: dayEvents)) { cluster in
                clusterView(cluster)
                    .padding(.leading, Constants.gutterWidth)
                    .padding(.trailing, .spacing1x)
                    .frame(height: clusterHeight(cluster), alignment: .top)
                    .offset(y: timelineY(atMinutes: cluster.startMinutes) + .spacing05x)
                    .transition(.blurReplace)
            }

            if calendar.isDateInToday(day) {
                nowIndicator
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(.brightEaseInOut, value: dayEvents)
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

    @ViewBuilder private func eventView(_ event: BrightCalendarDayEvent) -> some View {
        let button = Button {
            onEventTap?(event)
        } label: {
            eventLabel(event)
        }
        .buttonStyle(EventButtonStyle())
        .allowsHitTesting(onEventTap != nil || onEventDelete != nil)

        if let onEventDelete {
            button.contextMenu {
                Button(role: .destructive) {
                    onEventDelete(event)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.defaultRed)
            }
        } else {
            button
        }
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

    private func eventClusters(of dayEvents: [BrightCalendarDayEvent]) -> [EventCluster] {
        let sorted = dayEvents.sorted { ($0.startMinutes, $0.id) < ($1.startMinutes, $1.id) }
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
        let hour: Int = if calendar.isDateInToday(selectedDate) {
            max(Constants.startHour, calendar.component(.hour, from: Date()) - 1)
        } else if let firstStart = events(selectedDate).map(\.startMinutes).min() {
            max(Constants.startHour, firstStart / 60 - 1)
        } else {
            Constants.emptyDayTopHour
        }
        timelinePosition.scrollTo(y: CGFloat(hour - Constants.startHour) * Constants.hourHeight + Constants.topInset)
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
        static let timelineHeight: CGFloat = CGFloat(endHour - startHour + 1) * hourHeight
        static let gutterWidth: CGFloat = 66
        static let hourLabelWidth: CGFloat = 21
        static let hourLabelOffset: CGFloat = 9
        static let topInset: CGFloat = .spacing4x
        static let barHeight: CGFloat = 35
        static let compactBarHeight: CGFloat = 16
        static let compactThresholdMinutes = 45
        static let minimumEventMinutes = 30
        static let emptyDayTopHour = 7
        static let nowPillWidth: CGFloat = 48
        static let nowPillHeight: CGFloat = 28
        static let nowLineHeight: CGFloat = 1.5
        static let dayRange = 365
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
            }
        }
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
        isWeekly: true,
        events: { _ in [
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
        ] },
        onEventTap: { _ in },
        onEventDelete: { _ in }
    )
    .background(Color.defaultBackground.ignoresSafeArea())
}
