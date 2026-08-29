//
//  ExerciseAddSessionsSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 31/7/2026.
//

import SwiftUI

nonisolated struct ExercisePlannedSession: Identifiable, Equatable {
    enum Kind {
        case strength
        case cardio
        // Lifts and a run in the one session, which is what earns the gradient.
        case mixed
        case rest
    }

    let id: UUID
    let title: String
    let subtitle: String
    let kind: Kind
    // The menu's icon: whatever the session opens with.
    let symbol: String

    init(id: UUID = UUID(), title: String, subtitle: String, kind: Kind, symbol: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
        self.symbol = symbol ?? kind.symbol
    }

    var accentColor: Color {
        switch kind {
        case .strength, .mixed: .defaultPurple
        case .cardio: .defaultSkyBlueCyan
        case .rest: .defaultGreen
        }
    }

    var duplicated: ExercisePlannedSession {
        ExercisePlannedSession(title: title, subtitle: subtitle, kind: kind, symbol: symbol)
    }
}

extension ExercisePlannedSession.Kind {
    var symbol: String {
        switch self {
        case .strength, .mixed: ExerciseCategory.gym.symbol
        case .cardio: ExerciseCategory.cardio.symbol
        case .rest: "moon.zzz"
        }
    }
}

nonisolated struct ExercisePlanDay: Identifiable {
    let name: String
    var sessions: [ExercisePlannedSession]

    var id: String { name }
}

nonisolated struct ExercisePlanWeek: Identifiable {
    let id = UUID()
    var days: [ExercisePlanDay]
}

struct ExerciseAddSessionsSheet: View {
    // Set when this week finishes the whole flow: the button reads Create and
    // `onDone` closes the presenting sheet. Unset, it says Save and pops back.
    let isCreating: Bool
    // The custom flow plans its week from scratch; only the guided flow
    // arrives with one already filled in.
    let startsEmpty: Bool
    let onDone: (() -> Void)?
    // Which block this week belongs to, as its period names it.
    let title: String
    // The block this week plans for, so its row and the period's total carry the
    // length picked here.
    let blockLength: Binding<Int>?

    @Environment(\.dismiss) private var dismiss

    @State private var weeks: [ExercisePlanWeek]
    @State private var selectedWeekID: UUID
    @State private var isUneven = false
    @State private var length: Int

    private let initialSessions: [[ExercisePlannedSession]]

    init(
        isCreating: Bool = false,
        startsEmpty: Bool = false,
        title: String? = nil,
        blockLength: Binding<Int>? = nil,
        onDone: (() -> Void)? = nil
    ) {
        self.isCreating = isCreating
        self.startsEmpty = startsEmpty
        self.title = title.map { $0.isEmpty ? "Add Sessions" : $0 } ?? "Add Sessions"
        self.blockLength = blockLength
        self.onDone = onDone
        _length = State(initialValue: blockLength?.wrappedValue ?? 1)
        let week = ExercisePlanWeek(days: startsEmpty ? ExerciseDemoPlanner.emptyWeek : ExerciseDemoPlanner.week)
        _weeks = State(initialValue: [week])
        _selectedWeekID = State(initialValue: week.id)
        initialSessions = week.days.map(\.sessions)
    }

    // Saving is offered only once the week differs from the one it opened with;
    // creating always is, since the flow has to be finishable.
    private var hasChanges: Bool {
        length > 1 || isUneven || days.map(\.sessions) != initialSessions
    }

    private var showsDone: Bool {
        isCreating || hasChanges
    }

    private var selectedIndex: Int {
        weeks.firstIndex { $0.id == selectedWeekID } ?? 0
    }

    private var days: [ExercisePlanDay] {
        weeks[selectedIndex].days
    }

    var body: some View {
        BrightPageView(
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultSheetBackground,
            toolbar: {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: title, file: #file)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if showsDone {
                        Button(isCreating ? "Create" : "Save") {
                            if let onDone {
                                onDone()
                            } else {
                                dismiss()
                            }
                        }
                            .buttonStyle(.borderedProminent)
                            .tint(.defaultSkyBlue)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            },
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: .spacing0x) {
                        repeatRow
                            .padding(.top, .spacing1x)
                            .padding(.horizontal, .spacing3x)
                            .padding(.bottom, .spacing3x)

                        if isUneven {
                            weekTags
                                .padding(.bottom, .spacing3x)
                        }

                        week
                            .padding(.horizontal, .spacing3x)
                            .background(Color.defaultCards.padding(.bottom, -Constants.backgroundBleed))
                    }
                }
            }
        )
        .animation(.brightSnappy, value: days.map(\.sessions))
        .animation(.brightSnappy, value: isUneven)
        .animation(.brightSnappy, value: length)
        .animation(.brightSnappy, value: weeks.count)
    }

    // MARK: - Week

    private var repeatRow: some View {
        HStack(spacing: .spacing105x) {
            if length > 1 {
                BrightRoundButton(
                    systemImage: isUneven ? "repeat" : "arrow.clockwise",
                    size: .large
                ) {
                    toggleUneven()
                }

                BrightText(isUneven ? "Uneven week" : "Repeat weekly", size: .body1, color: .semiLightTextColor)
                    .padding(.leading, .spacing05x)
            }

            Spacer()

            BrightText("Length:", size: .body1, color: .semiLightTextColor)

            lengthMenu
        }
    }

    private var lengthMenu: some View {
        Menu {
            Picker("Length", selection: lengthSelection) {
                ForEach(1...Constants.maxWeeks, id: \.self) { count in
                    Text(Self.lengthTitle(count)).tag(count)
                }
            }
            .pickerStyle(.inline)
        } label: {
            BrightText(Self.lengthTitle(length), size: .body1)
                .padding(.horizontal, .spacing2x)
                .frame(height: .spacing5x)
                .contentShape(.capsule)
        }
        .modifier(GlassEffect(shape: .capsule))
    }

    private var weekTags: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacing1x) {
                ForEach(Array(weeks.enumerated()), id: \.element.id) { index, week in
                    weekTag(week, at: index)
                }

                if weeks.count < length {
                    BrightRoundButton(systemImage: "plus", size: .small) {
                        addWeek()
                    }
                }
            }
            .padding(.horizontal, .spacing3x)
        }
        .scrollClipDisabled()
    }

    // Week A and Week B are what makes the fortnight uneven, so only the weeks
    // added after them can be pressed and held to delete.
    @ViewBuilder
    private func weekTag(_ week: ExercisePlanWeek, at index: Int) -> some View {
        let tag = BrightTag(title: Self.weekName(index), isSelected: week.id == selectedWeekID) {
            selectedWeekID = week.id
        }

        if index < Constants.fixedWeeks {
            tag
        } else {
            tag.contextMenu {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    remove(week)
                }
                .tint(.defaultRed)
            }
        }
    }

    private static func weekName(_ index: Int) -> String {
        "Week \(String(UnicodeScalar(UInt8(65 + index))))"
    }

    // An uneven fortnight needs two weeks to be uneven between, so turning it on
    // brings Week B with it.
    private func toggleUneven() {
        isUneven.toggle()
        if isUneven {
            if weeks.count < Constants.fixedWeeks {
                addWeek()
            }
        } else {
            // An even week is Week A repeated, so that is the one left on screen.
            selectedWeekID = weeks[0].id
        }
    }

    private var lengthSelection: Binding<Int> {
        Binding(
            get: { length },
            set: { setLength($0) }
        )
    }

    private static func lengthTitle(_ count: Int) -> String {
        count == 1 ? "1 week" : "\(count) weeks"
    }

    // A shorter block can't hold the weeks already written, so it drops the ones
    // past its end. A longer one only makes room; the weeks are added by hand.
    private func setLength(_ count: Int) {
        length = count
        blockLength?.wrappedValue = count
        if count == 1 {
            isUneven = false
        }
        if weeks.count > count {
            weeks.removeLast(weeks.count - count)
            if !weeks.contains(where: { $0.id == selectedWeekID }) {
                selectedWeekID = weeks[0].id
            }
        }
    }

    private func addWeek() {
        let week = ExercisePlanWeek(days: ExerciseDemoPlanner.emptyWeek)
        weeks.append(week)
        selectedWeekID = week.id
    }

    private func remove(_ week: ExercisePlanWeek) {
        weeks.removeAll { $0.id == week.id }
        if !weeks.contains(where: { $0.id == selectedWeekID }) {
            selectedWeekID = weeks[0].id
        }
    }

    private var week: some View {
        VStack(spacing: .spacing0x) {
            ForEach($weeks[selectedIndex].days) { $day in
                dayRow($day)
                    .padding(.vertical, .spacing2x)

                if day.id != days.last?.id {
                    BrightDivider()
                }
            }
        }
        .padding(.vertical, .spacing2x)
    }

    private func dayRow(_ day: Binding<ExercisePlanDay>) -> some View {
        HStack(alignment: .top, spacing: .spacing105x) {
            dayChip(day.wrappedValue.name)

            VStack(spacing: .spacing1x) {
                if day.wrappedValue.sessions.isEmpty {
                    // A day with nothing on it is a rest day, so it says so
                    // rather than sitting blank; adding a session takes it back.
                    restCard
                } else {
                    ForEach(day.wrappedValue.sessions) { session in
                        sessionCard(session, in: day)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            addButton(for: day)
                .padding(.top, .spacing05x)
        }
    }

    private func dayChip(_ name: String) -> some View {
        BrightText(name, size: .body1)
            .padding(.horizontal, .spacing1x)
            .padding(.vertical, .spacing05x)
            .frame(width: Constants.dayChipWidth)
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous)
                    .strokeBorder(Color.textColor.opacity(.veryLowOpacity), lineWidth: Constants.hairline)
            }
    }

    private func addButton(for day: Binding<ExercisePlanDay>) -> some View {
        Menu {
            ForEach(ExerciseDemoPlanner.templates) { template in
                Button(template.title, systemImage: template.symbol) {
                    add(template, to: day)
                }
            }
        } label: {
            Image(systemName: "plus.circle")
                .font(.system(size: Constants.plusIconSize, weight: .light))
                .foregroundStyle(Color.defaultSkyBlue)
        }
    }

    // A rest day is the whole day, so it clears the day it lands on and any
    // session added after it takes the day back.
    private func add(_ template: ExercisePlannedSession, to day: Binding<ExercisePlanDay>) {
        guard template.kind != .rest else {
            day.wrappedValue.sessions = [template.duplicated]
            return
        }

        day.wrappedValue.sessions.removeAll { $0.kind == .rest }
        day.wrappedValue.sessions.append(template.duplicated)
    }

    private func sessionCard(_ session: ExercisePlannedSession, in day: Binding<ExercisePlanDay>) -> some View {
        let isMixed = session.kind == .mixed

        return HStack(spacing: .spacing105x) {
            if session.kind == .rest {
                BrightText(session.title, size: .body2, color: session.accentColor, weight: .regular)
            } else {
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(isMixed
                        ? AnyShapeStyle(ExerciseDayType.bothGradient)
                        : AnyShapeStyle(session.accentColor))
                    .frame(width: Constants.accentLineWidth, height: Constants.accentLineHeight)

                sessionBody(session)
                    .overlay {
                        if isMixed {
                            Self.cardGradient
                                .mask(sessionBody(session))
                                .allowsHitTesting(false)
                        }
                    }
            }

            Spacer(minLength: .spacing0x)
        }
        .padding(.horizontal, .spacing105x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Constants.cardHeight)
        .background {
            if session.kind == .rest {
                restBackground
            } else if isMixed {
                Self.cardGradient.opacity(.ultraLowOpacity)
            } else {
                session.accentColor.opacity(.ultraLowOpacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius14, style: .continuous))
        .contextMenu {
            Button("Remove", systemImage: "trash", role: .destructive) {
                day.wrappedValue.sessions.removeAll { $0.id == session.id }
            }
            .tint(.defaultRed)
        }
    }

    private var restCard: some View {
        HStack(spacing: .spacing105x) {
            BrightText("Rest Day", size: .body2, color: .defaultGreen, weight: .regular)

            Spacer(minLength: .spacing0x)
        }
        .padding(.horizontal, .spacing105x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Constants.cardHeight)
        .background(restBackground)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius14, style: .continuous))
    }

    private func sessionBody(_ session: ExercisePlannedSession) -> some View {
        VStack(alignment: .leading, spacing: .spacing025x) {
            BrightText(session.title, size: .body2, color: session.accentColor, weight: .regular)
            BrightText(session.subtitle, size: .body2, color: session.accentColor)
        }
    }

    // Reaches blue by mid-card: a swatch spread would stay purple across a card
    // this wide.
    private static let cardGradient = LinearGradient(
        stops: [
            .init(color: .defaultPurple, location: 0),
            .init(color: .defaultSkyBlueCyan, location: Constants.blueStop),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private var restBackground: some View {
        ExerciseRestBackground()
    }

    // MARK: - Bottom bar

    // MARK: - Derived state

    private enum Constants {
        static let cardHeight: CGFloat = 53
        static let blueStop: Double = 0.55
        static let dayChipWidth: CGFloat = 50
        static let accentLineWidth: CGFloat = 2
        static let accentLineHeight: CGFloat = 35
        static let plusIconSize: CGFloat = 22
        static let hairline: CGFloat = 0.5
        static let fixedWeeks = 2
        static let maxWeeks = 6
        static let backgroundBleed: CGFloat = 1000
    }
}

#Preview {
    NavigationStack {
        ExerciseAddSessionsSheet()
    }
}
