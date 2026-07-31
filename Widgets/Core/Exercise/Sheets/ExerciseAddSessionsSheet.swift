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
        case run
        case cycle
        case rest
    }

    let id: UUID
    let title: String
    let subtitle: String
    let kind: Kind

    init(id: UUID = UUID(), title: String, subtitle: String, kind: Kind) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
    }

    var accentColor: Color {
        switch kind {
        case .strength: .defaultPurple
        case .run: .defaultGreen
        case .cycle: .defaultOrange
        case .rest: .defaultSkyBlue
        }
    }

    var duplicated: ExercisePlannedSession {
        ExercisePlannedSession(title: title, subtitle: subtitle, kind: kind)
    }
}

nonisolated struct ExercisePlanDay: Identifiable {
    let name: String
    var sessions: [ExercisePlannedSession]

    var id: String { name }
}

struct ExerciseAddSessionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var days = ExerciseAddSessionsSheet.demoWeek
    @State private var repeatsWeekly = false
    @State private var clipboard: ExercisePlannedSession?
    @State private var weekClipboard: [ExercisePlanDay]?
    @State private var copyTick = 0

    var body: some View {
        BrightPageSheetView(
            title: "Add Sessions",
            horizontalPadding: .spacing0x,
            showBackButton: true,
            trailing: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .tint(.defaultSkyBlue)
                }
            },
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: .spacing0x) {
                        repeatRow
                            .padding(.top, .spacing1x)
                            .padding(.horizontal, .spacing3x)
                            .padding(.bottom, .spacing3x)

                        week
                            .padding(.horizontal, .spacing3x)
                            .background(Color.defaultCards.padding(.bottom, -Constants.backgroundBleed))
                    }
                }
                .safeAreaInset(edge: .bottom) { bottomBar }
            }
        )
        .brightHaptic(.light, trigger: copyTick)
        .animation(.brightSnappy, value: days.map(\.sessions))
    }

    private var repeatRow: some View {
        HStack(spacing: .spacing105x) {
            BrightRoundButton(
                systemImage: "repeat",
                size: .large,
                color: repeatsWeekly ? .defaultGreen : nil
            ) {
                repeatsWeekly.toggle()
            }

            BrightText("Repeat weekly", size: .body1, color: .semiLightTextColor)
                .padding(.leading, .spacing05x)

            Spacer()

            Menu {
                Button("Add variable week", systemImage: "calendar.badge.plus") {
                    days = Self.demoWeek
                }

                Divider()

                Button("Clear week", systemImage: "eraser.line.dashed") {
                    days = Self.emptyWeek
                }
                Button("Delete week", systemImage: "trash", role: .destructive) {
                    days = Self.emptyWeek
                    dismiss()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: FontSizes.subheading2.rawValue, weight: .medium))
                    .foregroundStyle(Color.textColor)
                    .frame(width: BrightButtonSizes.large.rawValue, height: BrightButtonSizes.large.rawValue)
                    .contentShape(Circle())
            }
            .modifier(GlassEffect())
        }
    }

    private var week: some View {
        VStack(spacing: .spacing0x) {
            ForEach($days) { $day in
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

            addButton(for: day)
                .padding(.top, .spacing05x)

            VStack(spacing: .spacing1x) {
                ForEach(day.wrappedValue.sessions) { session in
                    sessionCard(session, in: day)
                }
            }
            .frame(maxWidth: .infinity)
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
            ForEach(Self.templates) { template in
                Button(template.title, systemImage: templateSymbol(template.kind)) {
                    day.wrappedValue.sessions.append(template.duplicated)
                }
            }

            if let clipboard {
                Divider()
                Button("Paste \"\(clipboard.title)\"", systemImage: "arrow.right.page.on.clipboard") {
                    day.wrappedValue.sessions.append(clipboard.duplicated)
                }
            }
        } label: {
            Image(systemName: "plus.circle")
                .font(.system(size: Constants.plusIconSize, weight: .light))
                .foregroundStyle(Color.defaultSkyBlue)
        }
    }

    private func sessionCard(_ session: ExercisePlannedSession, in day: Binding<ExercisePlanDay>) -> some View {
        HStack(spacing: .spacing105x) {
            if session.kind == .rest {
                BrightText(session.title, size: .body2, color: session.accentColor, weight: .regular)
            } else {
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(session.accentColor)
                    .frame(width: Constants.accentLineWidth, height: Constants.accentLineHeight)

                VStack(alignment: .leading, spacing: .spacing025x) {
                    BrightText(session.title, size: .body2, color: session.accentColor, weight: .regular)
                    BrightText(session.subtitle, size: .body2, color: session.accentColor)
                }
            }

            Spacer(minLength: .spacing0x)

            Button {
                clipboard = session
                copyTick += 1
            } label: {
                Image(systemName: "square.on.square")
                    .font(.system(size: FontSizes.body3.rawValue, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.textColor)
            }
            .buttonStyle(.plain)
            .padding(.trailing, .spacing05x)
        }
        .padding(.horizontal, .spacing105x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Constants.cardHeight)
        .background {
            if session.kind == .rest {
                restBackground
            } else {
                session.accentColor.opacity(.ultraLowOpacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius14, style: .continuous))
        .contextMenu {
            Button("Remove", systemImage: "trash", role: .destructive) {
                day.wrappedValue.sessions.removeAll { $0.id == session.id }
            }
        }
    }

    private var restBackground: some View {
        DiagonalStripesShape(spacing: Constants.stripeSpacing)
            .stroke(Color.defaultSkyBlue.opacity(.minimalOpacity), lineWidth: Constants.stripeWidth)
    }

    private var bottomBar: some View {
        HStack(spacing: .spacing0x) {
            BrightRoundButton(systemImage: "arrow.counterclockwise", size: .large) {
                days = Self.demoWeek
                clipboard = nil
                weekClipboard = nil
            }

            Spacer()

            HStack(spacing: .spacing2x) {
                Button {
                    weekClipboard = days
                    copyTick += 1
                } label: {
                    Image(systemName: "square.on.square")
                        .font(.system(size: FontSizes.subheading.rawValue, weight: .light))
                        .foregroundStyle(Color.textColor)
                        .frame(width: BrightButtonSizes.medium.rawValue, height: BrightButtonSizes.medium.rawValue)
                }
                .buttonStyle(.plain)

                Button {
                    if let weekClipboard {
                        days = weekClipboard.map { day in
                            ExercisePlanDay(name: day.name, sessions: day.sessions.map(\.duplicated))
                        }
                    }
                } label: {
                    Image(systemName: "arrow.right.page.on.clipboard")
                        .font(.system(size: FontSizes.subheading.rawValue, weight: .light))
                        .foregroundStyle(Color.textColor.opacity(weekClipboard == nil ? .semiLowOpacity : .opaque))
                        .frame(width: BrightButtonSizes.medium.rawValue, height: BrightButtonSizes.medium.rawValue)
                }
                .buttonStyle(.plain)
                .disabled(weekClipboard == nil)
            }
            .padding(.horizontal, .spacing1x)
            .frame(height: BrightButtonSizes.large.rawValue)
            .modifier(GlassEffect())
        }
        .padding(.horizontal, .spacing3x)
        .padding(.bottom, .spacing1x)
    }

    private func templateSymbol(_ kind: ExercisePlannedSession.Kind) -> String {
        switch kind {
        case .strength: "dumbbell"
        case .run: "figure.run"
        case .cycle: "figure.outdoor.cycle"
        case .rest: "moon.zzz"
        }
    }

    private class Constants {
        static let dayChipWidth: CGFloat = 50
        static let cardHeight: CGFloat = 53
        static let accentLineWidth: CGFloat = 2
        static let accentLineHeight: CGFloat = 35
        static let plusIconSize: CGFloat = 22
        static let stripeSpacing: CGFloat = 9
        static let stripeWidth: CGFloat = 3
        static let hairline: CGFloat = 0.5
        static let backgroundBleed: CGFloat = 1000
    }
}

private extension ExerciseAddSessionsSheet {
    static let templates: [ExercisePlannedSession] = [
        ExercisePlannedSession(title: "Back & Biceps", subtitle: "10 exercises", kind: .strength),
        ExercisePlannedSession(title: "Chest & Legs", subtitle: "10 exercises", kind: .strength),
        ExercisePlannedSession(title: "Back & Core", subtitle: "6 exercises", kind: .strength),
        ExercisePlannedSession(title: "3K Run", subtitle: "Target: Zone 2", kind: .run),
        ExercisePlannedSession(title: "10K Run", subtitle: "Target: Zone 3", kind: .run),
        ExercisePlannedSession(title: "20K Cycle", subtitle: "Target: Zone 2", kind: .cycle),
        ExercisePlannedSession(title: "Rest Day", subtitle: "", kind: .rest),
    ]

    static var demoWeek: [ExercisePlanDay] {
        [
            ExercisePlanDay(name: "Mon", sessions: [templates[0].duplicated]),
            ExercisePlanDay(name: "Tue", sessions: [templates[1].duplicated]),
            ExercisePlanDay(name: "Wed", sessions: [templates[6].duplicated]),
            ExercisePlanDay(name: "Thu", sessions: [templates[4].duplicated]),
            ExercisePlanDay(name: "Fri", sessions: [templates[2].duplicated, templates[3].duplicated]),
            ExercisePlanDay(name: "Sat", sessions: [templates[6].duplicated]),
            ExercisePlanDay(name: "Sun", sessions: [templates[5].duplicated]),
        ]
    }

    static var emptyWeek: [ExercisePlanDay] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map {
            ExercisePlanDay(name: $0, sessions: [])
        }
    }
}

private struct DiagonalStripesShape: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var x = rect.minX - rect.height
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            x += spacing
        }
        return path
    }
}

#Preview {
    ExerciseAddSessionsSheet()
}
