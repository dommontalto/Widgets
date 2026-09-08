//
//  ExerciseCalendarWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import SwiftUI

struct ExerciseCalendarWidget: View {
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())

    var body: some View {
        VStack(spacing: .spacing1x) {
            BrightCalendar(
                selectedDate: $selectedDate,
                backgroundColor: .clear,
                showsIcon: false,
                dotStyle: { ExerciseCalendarDemo.dotStyle(on: $0) }
            )

            sessionView
                .padding(.horizontal, .spacing3x)
                .padding(.bottom, .spacing3x)
                .transaction { $0.animation = .brightEaseInOut }
                .animation(.brightEaseInOut, value: selectedDate)
        }
        .padding(.top, .spacing3x)
        .modifier(CardModifier())
    }

    private var sessionView: some View {
        Group {
            let sessions = ExerciseCalendarDemo.sessions(on: selectedDate)
            if sessions.isEmpty {
                emptyCard
            } else {
                VStack(spacing: .spacing0x) {
                    ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                        sessionRow(session, isLast: index == sessions.count - 1)
                    }
                }
            }
        }
        .id(selectedDate)
        .transition(.blurReplace)
    }

    private func sessionRow(_ session: ExerciseCalendarSession, isLast: Bool) -> some View {
        VStack(spacing: .spacing0x) {
            HStack(spacing: .spacing105x) {
                Rectangle()
                    .fill(Color.textColor)
                    .frame(width: Constants.accentWidth)

                VStack(alignment: .leading, spacing: .spacing1x) {
                    BrightText(session.name, size: .body1, weight: .regular)
                    BrightText(session.subtitle, size: .body1, color: .semiLightTextColor)
                }

                Spacer(minLength: .spacing2x)

                ExerciseCategoryCircleStack(categories: session.categories)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, .spacing2x)
            .padding(.bottom, isLast ? .spacing0x : .spacing2x)

            if !isLast {
                BrightDivider()
            }
        }
    }

    private var emptyCard: some View {
        BrightText("No sessions", size: .body1, color: .lightTextColor)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.emptyHeight)
    }

    enum Constants {
        static let accentWidth: CGFloat = 2
        static let emptyHeight: CGFloat = .spacing12x
    }
}

#Preview {
    ExerciseCalendarWidget()
        .padding(.spacing4x)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.defaultBackground.ignoresSafeArea())
}
