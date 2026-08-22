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
        case .run, .cycle: .defaultSkyBlue
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
    // Set when this week finishes the whole flow: the button reads Create and
    // `onDone` closes the presenting sheet. Unset, it says Save and pops back.
    let isCreating: Bool
    // The custom flow plans its week from scratch; only the guided flow
    // arrives with one already filled in.
    let startsEmpty: Bool
    let onDone: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var days: [ExercisePlanDay]

    @State private var repeatsWeekly = false

    init(isCreating: Bool = false, startsEmpty: Bool = false, onDone: (() -> Void)? = nil) {
        self.isCreating = isCreating
        self.startsEmpty = startsEmpty
        self.onDone = onDone
        _days = State(initialValue: startsEmpty ? ExerciseDemoPlanner.emptyWeek : ExerciseDemoPlanner.week)
    }

    var body: some View {
        BrightPageView(
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultSheetBackground,
            toolbar: {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: "Add Sessions", file: #file)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(isCreating ? "Create" : "Save") {
                        if let onDone {
                            onDone()
                        } else {
                            dismiss()
                        }
                    }
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
            }
        )
        .animation(.brightSnappy, value: days.map(\.sessions))
    }

    // MARK: - Week

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
                Button("Undo changes", systemImage: "arrow.counterclockwise") {
                    days = startsEmpty ? ExerciseDemoPlanner.emptyWeek : ExerciseDemoPlanner.week
                }

                Divider()

                Button("Clear week", systemImage: "eraser.line.dashed") {
                    days = ExerciseDemoPlanner.emptyWeek
                }
                Button("Delete week", systemImage: "trash", role: .destructive) {
                    days = ExerciseDemoPlanner.emptyWeek
                    dismiss()
                }
                .tint(.defaultRed)
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

            VStack(spacing: .spacing1x) {
                ForEach(day.wrappedValue.sessions) { session in
                    sessionCard(session, in: day)
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
                Button(template.title, systemImage: templateSymbol(template.kind)) {
                    day.wrappedValue.sessions.append(template.duplicated)
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
            .tint(.defaultRed)
        }
    }

    private var restBackground: some View {
        DiagonalStripesShape(spacing: Constants.stripeSpacing)
            .stroke(Color.defaultSkyBlue.opacity(.minimalOpacity), lineWidth: Constants.stripeWidth)
    }

    // MARK: - Bottom bar

    // MARK: - Derived state

    private func templateSymbol(_ kind: ExercisePlannedSession.Kind) -> String {
        switch kind {
        case .strength: ExerciseCategory.gym.symbol
        case .run, .cycle: ExerciseCategory.cardio.symbol
        case .rest: "moon.zzz"
        }
    }

    private enum Constants {
        static let cardHeight: CGFloat = 53
        static let dayChipWidth: CGFloat = 50
        static let accentLineWidth: CGFloat = 2
        static let accentLineHeight: CGFloat = 35
        static let plusIconSize: CGFloat = 22
        static let stripeSpacing: CGFloat = 9
        static let stripeWidth: CGFloat = 3
        static let hairline: CGFloat = 0.5
        static let backgroundBleed: CGFloat = 1000
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
    NavigationStack {
        ExerciseAddSessionsSheet()
    }
}
