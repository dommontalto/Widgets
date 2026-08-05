//
//  ExerciseSessionCompleteSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

struct ExerciseSessionCompleteSheet: View {
    let session: ExerciseSession

    @State private var openedExerciseName: String?
    @State private var isMapExpanded = false

    private let splitLabelWidth: CGFloat = 24
    private let splitPaceWidth: CGFloat = 48
    private let splitTrailingWidth: CGFloat = 44
    private let splitBarHeight: CGFloat = 15

    var body: some View {
        GeometryReader { proxy in
            sheet(expandedMapHeight: proxy.size.height + proxy.safeAreaInsets.bottom)
        }
    }

    private func sheet(expandedMapHeight: CGFloat) -> some View {
        BrightPageSheetView(
            title: "Workout Complete",
            horizontalPadding: .spacing0x
        ) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .spacing4x) {
                    header

                    ExerciseStatTileGrid(tiles: session.detail.tiles)

                    if !session.detail.exercises.isEmpty {
                        exercisesList
                    }

                    if session.type == .cardio {
                        zonesCard
                    }

                    if !session.detail.splits.isEmpty {
                        splitsCard
                    }
                }
                .padding(.horizontal, .spacing3x)
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing4x)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: "Workout Complete", file: #file)
                }
            }
        }
        .sheet(item: openedExerciseBinding) { exercise in
            BrightPageSheetView(title: exercise.name, horizontalPadding: .spacing0x) {
                ExerciseDetailSheet(exercise: exercise)
            }
        }
    }

    private var openedExerciseBinding: Binding<ExerciseDefinition?> {
        Binding(
            get: { openedExerciseName.flatMap(ExerciseDemoLibrary.exercise(named:)) },
            set: { openedExerciseName = $0?.name }
        )
    }

    private var accentColor: Color {
        session.type == .cardio ? .defaultSkyBlue : .defaultPurple
    }

    private var header: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: session.type == .cardio ? "figure.run" : "dumbbell")
                .resizable()
                .scaledToFit()
                .fontWeight(.light)
                .frame(width: 40, height: 40)
                .foregroundStyle(accentColor)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(session.name, size: .standout3)
                BrightText(session.timestamp, size: .body2, color: .semiLightTextColor)
            }
        }
    }

    private var exercisesList: some View {
        ExerciseSetHistoryList(groups: exerciseGroups) { group in
            openedExerciseName = group.title
        }
    }

    private var exerciseGroups: [ExerciseSetGroup] {
        session.detail.exercises.map { exercise in
            ExerciseSetGroup(title: exercise.name, lines: lines(for: exercise))
        }
    }

    /// Drop sets take a set number alongside working sets — only warm-ups sit
    /// outside the count.
    private func lines(for exercise: ExerciseLoggedExercise) -> [ExerciseSetLine] {
        var number = 0
        return exercise.sets.map { set in
            var kind = set.kind
            if kind.countsAsSet {
                number += 1
            }
            if kind.isWorking {
                kind = .working(number)
            }
            return ExerciseSetLine(
                kind: kind,
                reps: "\(set.reps) reps",
                weight: "\(set.weight) KG",
                prLabel: set.isRecord ? "PR" : nil
            )
        }
    }

    private var zonesCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("Heart rate zones", size: .body1)

            VStack(spacing: .spacing105x) {
                ForEach(zoneBreakdown.indices, id: \.self) { i in
                    let zone = zoneBreakdown[i]
                    HStack(spacing: .spacing2x) {
                        BrightText("Z\(i + 1)", size: .body3, color: zone.color, weight: .regular)
                            .monospacedDigit()
                            .frame(width: splitLabelWidth, alignment: .leading)

                        GeometryReader { proxy in
                            Capsule()
                                .fill(zone.color.opacity(.semiLowOpacity))
                                .frame(width: max(proxy.size.width * zone.fraction, splitBarHeight))
                                .frame(maxHeight: .infinity)
                        }
                        .frame(height: splitBarHeight)

                        BrightText(zone.time, size: .body3, color: .lightTextColor)
                            .monospacedDigit()
                            .frame(width: splitTrailingWidth, alignment: .trailing)
                    }
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private var zoneBreakdown: [(color: Color, fraction: CGFloat, time: String)] {
        [
            (.defaultBlue, 0.10, "2:29"),
            (.defaultGreen, 0.22, "5:29"),
            (.defaultYellow, 0.38, "9:28"),
            (.defaultOrange, 0.24, "5:59"),
            (.defaultRed, 0.06, "1:31"),
        ]
    }

    private var splitsCard: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightText("Splits", size: .body1)

            VStack(spacing: .spacing105x) {
                HStack(spacing: .spacing2x) {
                    BrightText("KM", size: .body5, color: .lightTextColor)
                        .frame(width: splitLabelWidth, alignment: .leading)
                    BrightText("PACE", size: .body5, color: .lightTextColor)
                        .frame(width: splitPaceWidth, alignment: .leading)
                    Spacer(minLength: .spacing0x)
                    BrightText("HR", size: .body5, color: .lightTextColor)
                        .frame(width: splitTrailingWidth, alignment: .trailing)
                    BrightText("ELEV", size: .body5, color: .lightTextColor)
                        .frame(width: splitTrailingWidth, alignment: .trailing)
                }

                ForEach(session.detail.splits.indices, id: \.self) { i in
                    splitRow(session.detail.splits[i])
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private func splitRow(_ split: ExerciseSplit) -> some View {
        HStack(spacing: .spacing2x) {
            BrightText(split.label, size: .body2, color: .semiLightTextColor)
                .monospacedDigit()
                .frame(width: splitLabelWidth, alignment: .leading)
            BrightText(split.pace, size: .body2, weight: .regular)
                .monospacedDigit()
                .frame(width: splitPaceWidth, alignment: .leading)

            GeometryReader { proxy in
                Capsule()
                    .fill(Color.defaultSkyBlue.opacity(.veryMinimalOpacity))
                    .frame(width: proxy.size.width * split.paceFraction)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: splitBarHeight)

            BrightText("\(split.heartRate)", size: .body3, color: .lightTextColor)
                .monospacedDigit()
                .frame(width: splitTrailingWidth, alignment: .trailing)
            BrightText(split.elevation, size: .body3, color: .lightTextColor)
                .monospacedDigit()
                .frame(width: splitTrailingWidth, alignment: .trailing)
        }
    }

}

#Preview("Strength") {
    ExerciseSessionCompleteSheet(session: ExerciseDemoData.sessionHistory[0])
}

#Preview("Cardio") {
    ExerciseSessionCompleteSheet(session: ExerciseDemoData.sessionHistory[1])
}
