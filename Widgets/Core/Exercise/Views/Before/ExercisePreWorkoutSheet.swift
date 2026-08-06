//
//  ExercisePreWorkoutSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 3/8/2026.
//

import SwiftUI

struct ExercisePreWorkoutSheet: View {
    let workout: ExerciseQuickWorkout
    var chrome: ExercisePageChrome = .sheet
    /// Ends the whole run. Only the flow can do that from a pushed leg, where
    /// `dismiss` would pop back instead.
    var onClose: (() -> Void)?
    /// Hands the workout to the presenter, which pushes the live screen inside
    /// the same presentation.
    var onStart: (ExerciseQuickWorkout) -> Void = { _ in }

    @Environment(ExerciseWorkoutBuilder.self) private var builder
    @Environment(\.dismiss) private var dismiss

    @State private var openedExercise: ExerciseDefinition?

    var body: some View {
        page
            .sheet(item: $openedExercise) { exercise in
                BrightPageSheetView(title: exercise.name, horizontalPadding: .spacing0x) {
                    ExerciseDetailSheet(exercise: exercise)
                }
            }
    }

    @ViewBuilder private var page: some View {
        switch chrome {
        case .sheet:
            BrightPageSheetView(horizontalPadding: .spacing0x, backgroundColor: .defaultBackground) {
                content
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            ExerciseInlineTitle(file: #file)
                        }
                    }
            }

        case .pushed:
            BrightPageView(
                horizontalPadding: .spacing0x,
                backgroundColor: .defaultBackground,
                toolbar: {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            close()
                        } label: {
                            Label("Close", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        ExerciseInlineTitle(file: #file)
                    }
                },
                content: { content }
            )
        }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing0x) {
                header
                    .padding(.top, .spacing3x)

                statsRow
                    .padding(.top, .spacing4x)

                exerciseRows
                    .padding(.top, .spacing5x)
            }
            .padding(.horizontal, .spacing3x)
            .padding(.bottom, Constants.controlSize + .spacing5x)
        }
        .safeAreaInset(edge: .bottom) {
            controls
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: workout.symbol)
                .font(.standard(size: .huge2, weight: .light))
                .foregroundStyle(Color.textColor)

            BrightText(workout.name, size: .standout4, scaleTextSize: 0.7)
                .lineLimit(1)
        }
    }

    private var statsRow: some View {
        HStack(spacing: .spacing0x) {
            statColumn(
                symbol: "text.line.magnify",
                color: .defaultBlue,
                label: "Exercises:",
                value: "\(workout.items.count)"
            )

            BrightVerticalDivider(height: Constants.statDividerHeight)
                .padding(.horizontal, .spacing2x)

            statColumn(
                symbol: "text.line.3.summary",
                color: .defaultGreen,
                label: "Total sets:",
                value: "\(totalSets)"
            )

            Spacer(minLength: .spacing0x)
        }
    }

    private func statColumn(
        symbol: String,
        color: Color,
        label: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing1x) {
                Image(systemName: symbol)
                    .font(.standardSFPro(size: .body1, weight: .regular))
                    .foregroundStyle(color)

                BrightText(label, size: .body1)
                    .lineLimit(1)
                    .fixedSize()
            }

            BrightText(value, size: .huge)
                .monospacedDigit()
        }
        .frame(width: Constants.statColumnWidth, alignment: .leading)
    }

    // MARK: - Exercises

    private var exerciseRows: some View {
        VStack(spacing: .spacing2x) {
            ForEach(workout.items) { item in
                Button {
                    openedExercise = ExerciseDemoLibrary.exercise(named: item.exerciseName)
                } label: {
                    exerciseRow(item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Mirrors ExerciseLibraryRow, with the set count where its add button sits.
    private func exerciseRow(_ item: ExerciseTemplateItem) -> some View {
        HStack(spacing: .spacing2x) {
            thumbnail(for: item)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(item.exerciseName, size: .body2, weight: .regular)
                    .fixedSize(horizontal: false, vertical: true)

                BrightText(subtitle(for: item), size: .body3, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: .spacing2x)

            BrightText(setsLabel(for: item), size: .subheading, color: .lightTextColor)
                .monospacedDigit()
                .fixedSize()
                .padding(.trailing, .spacing1x)
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, minHeight: ExerciseLibraryRow.Constants.minHeight, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    @ViewBuilder
    private func thumbnail(for item: ExerciseTemplateItem) -> some View {
        if let exercise = ExerciseDemoLibrary.exercise(named: item.exerciseName) {
            Image(systemName: exercise.category.symbol)
                .font(.standardSFPro(size: .standout4, weight: .light))
                .foregroundStyle(exercise.category.accentColor)
                .frame(width: Constants.thumbnailWidth)
        } else {
            Color.clear
                .frame(width: Constants.thumbnailWidth)
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: .spacing2x) {
            Menu {
                Button("Duplicate", systemImage: "plus.square.on.square") {
                    withAnimation(.brightSnappy) { builder.duplicate(workout) }
                }

                Button("Delete", systemImage: "trash", role: .destructive) {
                    builder.delete(workout)
                    close()
                }
            } label: {
                // The Menu owns the tap, so the button is label only.
                BrightRoundButton(systemImage: "ellipsis", size: .extraLarge)
                    .allowsHitTesting(false)
            }

            Spacer(minLength: .spacing2x)

            BrightRoundButton(systemImage: "play.fill", size: .extraLarge, color: .defaultGreen) {
                onStart(workout)
            }
        }
        .padding(.horizontal, .spacing4x)
        .padding(.bottom, .spacing1x)
    }

    // MARK: - Derived state

    private var totalSets: Int {
        workout.items.reduce(0) { $0 + setCount(for: $1) }
    }

    private func setCount(for item: ExerciseTemplateItem) -> Int {
        Int(item.target.prefix { $0.isNumber }) ?? 0
    }

    private func setsLabel(for item: ExerciseTemplateItem) -> String {
        let count = setCount(for: item)
        return "\(count) set\(count == 1 ? "" : "s")"
    }

    private func subtitle(for item: ExerciseTemplateItem) -> String {
        guard let exercise = ExerciseDemoLibrary.exercise(named: item.exerciseName) else {
            return item.target
        }
        return "\(exercise.primaryMuscle.displayName) \u{2022} \(exercise.equipmentLabel)"
    }

    private enum Constants {
        static let statColumnWidth: CGFloat = 110
        static let statDividerHeight: CGFloat = 58
        static let thumbnailWidth: CGFloat = 40
        static let controlSize = BrightButtonSizes.extraLarge.rawValue
    }
}

#Preview {
    Color.defaultBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ExercisePreWorkoutSheet(workout: ExerciseDemoWorkouts.quickPush)
                .environment(ExerciseWorkoutBuilder())
        }
}
