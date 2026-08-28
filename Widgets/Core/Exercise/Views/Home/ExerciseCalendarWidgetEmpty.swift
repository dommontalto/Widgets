//
//  ExerciseCalendarWidgetEmpty.swift
//  Widgets
//
//  Created by Dom Montalto on 28/8/2026.
//

import SwiftUI

// The calendar before a program exists: the same month strip, then the create
// prompt in place of the day's sessions.
struct ExerciseCalendarWidgetEmpty: View {
    var onCreate: () -> Void = {}

    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var showingCalendarSheet = false
    @State private var sportIndex = 0

    var body: some View {
        VStack(spacing: .spacing1x) {
            BrightCalendar(selectedDate: $selectedDate, backgroundColor: .clear) {
                BrightRoundButton(
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    size: .medium
                ) {
                    showingCalendarSheet = true
                }
            }

            prompt
                .padding(.top, .spacing2x)
                .padding(.horizontal, .spacing3x)
                .padding(.bottom, .spacing3x)
        }
        .padding(.top, .spacing3x)
        .modifier(CardModifier())
        .sheet(isPresented: $showingCalendarSheet) {
            ExerciseCalendarSheet(selectedDate: $selectedDate)
        }
    }

    private var prompt: some View {
        VStack(spacing: .spacing3x) {
            sportIcon

            BrightText(
                "Plan your sessions with programs",
                size: .subheading2,
                color: .defaultSlateBlue,
                weight: .regular
            )
            .multilineTextAlignment(.center)

            BrightPillButton(
                "Create",
                textColor: .defaultBlack,
                buttonSize: .large,
                isClear: true,
                onTapCallback: onCreate
            )
        }
        .padding(.top, .spacing6x)
        .padding(.bottom, .spacing4x)
        .padding(.horizontal, .spacing3x)
        .frame(maxWidth: .infinity)
        .background {
            ExerciseProgramBackground(fades: false)
        }
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius20, style: .continuous))
    }

    // The sports a program can be built from, one at a time, the way the create
    // flow's own intro cycles them.
    private var sportIcon: some View {
        Image(systemName: Constants.sportSymbols[sportIndex])
            .font(.system(size: Constants.sportIconSize, weight: .light))
            .foregroundStyle(Color.defaultSlateBlue)
            .contentTransition(.symbolEffect(.replace))
            .frame(height: Constants.sportIconSize)
            .task {
                while true {
                    do {
                        try await Task.sleep(for: .seconds(Constants.sportSwapEvery))
                    } catch {
                        return
                    }
                    withAnimation(.brightEaseInOut) {
                        sportIndex = (sportIndex + 1) % Constants.sportSymbols.count
                    }
                }
            }
    }

    private enum Constants {
        static let sportIconSize: CGFloat = 44
        static let sportSwapEvery: TimeInterval = 5
        static let sportSymbols = [
            "figure.volleyball", "figure.basketball",
            "figure.outdoor.cycle", "figure.run", "figure.badminton",
            "figure.strengthtraining.traditional", "figure.boxing",
            "figure.tennis", "figure.pool.swim", "figure.hiking",
            "figure.yoga", "figure.jumprope", "figure.dance",
            "figure.rower", "figure.core.training", "figure.cooldown",
            "figure.golf", "figure.climbing",
        ]
    }
}

#Preview {
    ExerciseCalendarWidgetEmpty()
        .padding(.spacing4x)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.defaultBackground.ignoresSafeArea())
}
