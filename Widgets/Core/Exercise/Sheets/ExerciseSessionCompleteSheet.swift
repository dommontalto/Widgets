//
//  ExerciseSessionCompleteSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

struct ExerciseSessionCompleteSheet: View {
    let session: ExerciseSession

    @State private var collapsedExercises: Set<String> = []
    @State private var openedExerciseName: String?
    @State private var isMapExpanded = false

    private let statTileHeight: CGFloat = 67
    private let setColumnWidth: CGFloat = 40
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
        Group {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .spacing4x) {
                    header

                    statsGrid

                    if !session.detail.exercises.isEmpty {
                        exercisesCard
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.defaultSheetBackground.ignoresSafeArea())
        .navigationTitle("Session complete")
        .navigationBarTitleDisplayMode(.inline)
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

    private var statsGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: .spacing2x), count: 2),
            spacing: .spacing2x
        ) {
            ForEach(session.detail.stats.indices, id: \.self) { i in
                statTile(session.detail.stats[i])
            }
        }
    }

    private func statTile(_ stat: ExerciseSessionStat) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                BrightText(stat.value, size: .standout3, weight: .regular)
                    .monospacedDigit()
                if let unit = stat.unit {
                    BrightText(unit, size: .body4, color: .lightTextColor)
                }
            }
            BrightText(stat.label, size: .body4, color: .semiLightTextColor)
        }
        .padding(.horizontal, .spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: statTileHeight)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius18))
    }

    private var exercisesCard: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightText("Workout", size: .body1)

            VStack(alignment: .leading, spacing: .spacing3x) {
                ForEach(session.detail.exercises.indices, id: \.self) { i in
                    exerciseSection(session.detail.exercises[i])

                    if i < session.detail.exercises.count - 1 {
                        divider
                    }
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private func exerciseSection(_ exercise: ExerciseLoggedExercise) -> some View {
        let isCollapsed = collapsedExercises.contains(exercise.name)
        return VStack(alignment: .leading, spacing: .spacing105x) {
            HStack {
                Button {
                    openedExerciseName = exercise.name
                } label: {
                    BrightText(exercise.name, size: .body2, color: .defaultPurple, weight: .regular)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer(minLength: .spacing2x)

                Button {
                    withAnimation(.brightEaseInOut) {
                        if isCollapsed {
                            collapsedExercises.remove(exercise.name)
                        } else {
                            collapsedExercises.insert(exercise.name)
                        }
                    }
                } label: {
                    HStack(spacing: .spacing1x) {
                        BrightText("\(exercise.sets.count) sets", size: .body4, color: .lightTextColor)
                            .monospacedDigit()
                        Image(systemName: "chevron.down")
                            .font(.standardSFPro(size: .body5, weight: .regular))
                            .foregroundStyle(Color.lightTextColor)
                            .rotationEffect(.degrees(isCollapsed ? 0 : 180))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if !isCollapsed {
                HStack(spacing: .spacing0x) {
                    BrightText("SET", size: .body5, color: .lightTextColor)
                        .frame(width: setColumnWidth, alignment: .leading)
                    BrightText("KG", size: .body5, color: .lightTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    BrightText("REPS", size: .body5, color: .lightTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    BrightText("", size: .body5)
                        .frame(width: setColumnWidth)
                }

                VStack(spacing: .spacing1x) {
                    ForEach(exercise.sets.indices, id: \.self) { i in
                        setRow(index: i, set: exercise.sets[i])
                    }
                }
            }
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

    private func setRow(index: Int, set: ExerciseLoggedSet) -> some View {
        HStack(spacing: .spacing0x) {
            BrightText("\(index + 1)", size: .body2, color: .semiLightTextColor)
                .monospacedDigit()
                .frame(width: setColumnWidth, alignment: .leading)
            BrightText(set.weight, size: .body2, weight: .regular)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .leading)
            BrightText(set.reps, size: .body2, weight: .regular)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                if set.isRecord {
                    Image(systemName: "trophy")
                        .font(.standardSFPro(size: .body4, weight: .regular))
                        .foregroundStyle(Color.defaultOrange)
                }
            }
            .frame(width: setColumnWidth)
        }
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

    private var divider: some View {
        Rectangle()
            .fill(Color.textColor.opacity(.ultraLowOpacity))
            .frame(height: 1)
    }
}

#Preview("Strength") {
    ExerciseSessionCompleteSheet(session: ExerciseDemoData.sessionHistory[0])
}

#Preview("Cardio") {
    ExerciseSessionCompleteSheet(session: ExerciseDemoData.sessionHistory[1])
}
