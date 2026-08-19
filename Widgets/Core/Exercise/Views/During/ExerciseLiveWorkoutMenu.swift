//
//  ExerciseLiveWorkoutMenu.swift
//  Widgets
//
//  Created by Dom Montalto on 17/8/2026.
//

import SwiftUI

// The live run's player menu: the spinning record, the transport controls and
// the playlist of exercises still to come.
struct ExerciseLiveWorkoutMenu: View {
    @Binding var exercises: [ExerciseActiveExercise]
    @Binding var currentIndex: Int
    @Binding var isExpanded: Bool
    let startDate: Date
    // Non-nil while the run is paused; the disc reads it so it freezes with the
    // clock rather than spinning on.
    let pauseDate: Date?
    let blockName: String
    var onBack: () -> Void
    var onTogglePause: () -> Void
    // Handed the seconds the finger just turned the record through, so the run's
    // clock is what the disc actually moves.
    var onScrub: (TimeInterval) -> Void
    var onScrubEnd: () -> Void
    var onAdvance: () -> Void
    var onEdit: () -> Void
    var onCancel: () -> Void
    var onEnd: () -> Void

    @State private var visibleRows: Set<Int> = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing0x) {
                sectionLabel(
                    isPaused ? "Currently paused" : "Currently playing",
                    symbol: isPaused ? "pause" : "play",
                    color: isPaused ? .defaultOrange : .defaultGreen
                )
                    .padding(.horizontal, .spacing3x)
                    .staggered(at: 0, in: visibleRows)

                ExerciseDisc(
                    startDate: startDate,
                    pauseDate: pauseDate,
                    isExpanded: isExpanded,
                    blockName: blockName,
                    exerciseName: currentExercise.name,
                    setCount: currentExercise.workingSetCount,
                    onTogglePause: onTogglePause,
                    onScrub: onScrub,
                    onScrubEnd: onScrubEnd
                )
                    .padding(.top, .spacing5x)
                    .frame(maxWidth: .infinity)
                    .staggered(at: 1, in: visibleRows)

                transportControls
                    .padding(.top, .spacing4x)
                    .frame(maxWidth: .infinity)
                    .staggered(at: 2, in: visibleRows)

                playlistHeader
                    .padding(.horizontal, .spacing3x)
                    .padding(.top, .spacing6x)
                    .padding(.bottom, .spacing3x)
                    .staggered(at: 3, in: visibleRows)

                playlist

                endRows
                    .padding(.horizontal, .spacing3x)
                    .padding(.top, .spacing3x)

                Spacer(minLength: .spacing8x)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaPadding(.vertical)
        .animation(.brightSnappy, value: pauseDate)
        .onChange(of: isExpanded) { _, isExpanded in
            animateRows(in: isExpanded)
        }
    }

    private var isPaused: Bool {
        pauseDate != nil
    }

    private var currentExercise: ExerciseActiveExercise {
        exercises[currentIndex]
    }

    private func sectionLabel(_ title: String, symbol: String, color: Color) -> some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: symbol)
                .font(.standard(size: .standout4, weight: .regular))
                .foregroundStyle(color)
                .contentTransition(.symbolEffect(.replace))

            BrightText(title, size: .body1)

            Spacer(minLength: .spacing2x)
        }
    }

    // MARK: - Transport

    private var transportControls: some View {
        HStack(spacing: .spacing2x) {
            transportButton("backward.end.alt", glyph: .subheading, action: onBack)

            transportButton(
                pauseDate == nil ? "pause" : "play",
                glyph: .standout28,
                action: onTogglePause
            )
            .contentTransition(.symbolEffect(.replace))

            transportButton("forward.end.alt", glyph: .subheading, action: onAdvance)
        }
    }

    private func transportButton(
        _ symbol: String,
        glyph: FontSizes,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.standard(size: glyph, weight: .regular))
                .foregroundStyle(Color.textColor)
                .frame(width: Constants.transportSize, height: Constants.transportSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .modifier(GlassEffect(shape: .circle))
    }

    // MARK: - Playlist

    private var playlistHeader: some View {
        HStack(spacing: .spacing105x) {
            sectionLabel("Playlist", symbol: "text.append", color: .defaultPink)

            BrightRoundButton(systemImage: "link") {
                onEdit()
            }
        }
    }

    // A `List` so the rows can carry the same insets and spacing as the rest of
    // the feature; it can't scroll itself inside the menu's scroll view, so it
    // states its own height.
    private var playlist: some View {
        List {
            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                playlistRow(exercise, at: index)
                    .listRowInsets(EdgeInsets(
                        top: .spacing0x,
                        leading: .spacing3x,
                        bottom: .spacing0x,
                        trailing: .spacing3x
                    ))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .staggered(at: index + 4, in: visibleRows)
            }
        }
        .listStyle(.plain)
        .listRowSpacing(.spacing2x)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .contentMargins(.vertical, .spacing0x, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, Constants.playlistRowHeight)
        .frame(height: playlistHeight)
    }

    private var playlistHeight: CGFloat {
        CGFloat(exercises.count) * (Constants.playlistRowHeight + .spacing2x)
    }

    private func playlistRow(_ exercise: ExerciseActiveExercise, at index: Int) -> some View {
        Button {
            withAnimation(.brightSnappy) { isExpanded = false }
            currentIndex = index
        } label: {
            HStack(spacing: .spacing2x) {
                thumbnail(for: exercise)

                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(exercise.name, size: .body2, weight: .regular)
                        .fixedSize(horizontal: false, vertical: true)

                    BrightText(setsLabel(of: exercise), size: .body3, color: .lightTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: .spacing2x)

                if index == currentIndex {
                    Image(systemName: isPaused ? "pause" : "play")
                        .font(.standard(size: .standout4, weight: .regular))
                        .foregroundStyle(isPaused ? Color.defaultOrange : Color.defaultGreen)
                        .contentTransition(.symbolEffect(.replace))
                        .padding(.trailing, .spacing1x)
                }
            }
            .padding(.spacing2x)
            .frame(maxWidth: .infinity, minHeight: Constants.playlistRowHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    @ViewBuilder
    private func thumbnail(for exercise: ExerciseActiveExercise) -> some View {
        if let definition = ExerciseDemoLibrary.exercise(named: exercise.name) {
            Image(systemName: definition.symbol)
                .font(.standard(size: .standout4, weight: .light))
                .foregroundStyle(Color.lightTextColor)
                .frame(width: ExerciseLibraryRow.Constants.thumbnailWidth)
        } else {
            Color.clear
                .frame(width: ExerciseLibraryRow.Constants.thumbnailWidth)
        }
    }

    private func setsLabel(of exercise: ExerciseActiveExercise) -> String {
        let count = exercise.workingSetCount
        return "\(count) set\(count == 1 ? "" : "s")"
    }

    private var endRows: some View {
        BrightDuelPillButton(
            "Cancel",
            "End workout",
            leadingSystemImage: "xmark",
            trailingSystemImage: "flag.pattern.checkered",
            leadingColor: .defaultRed,
            trailingColor: .defaultGreen,
            onLeadingTap: { close(then: onCancel) },
            onTrailingTap: { close(then: onEnd) }
        )
        .staggered(at: exercises.count + 4, in: visibleRows)
    }

    private func close(then action: @escaping () -> Void) {
        withAnimation(.brightSnappy) { isExpanded = false }
        action()
    }

    // Rows fall in one after another as the menu opens, and drop together on the
    // way out — matching the app's main side menu.
    private func animateRows(in expanded: Bool) {
        guard expanded else {
            withAnimation(.easeOut(duration: Constants.rowExitDuration)) { visibleRows.removeAll() }
            return
        }

        visibleRows = []
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Constants.rowStartDelay))
            for row in 0...(exercises.count + 4) {
                withAnimation(.bouncy(duration: Constants.rowDuration, extraBounce: Constants.rowBounce)) {
                    _ = visibleRows.insert(row)
                }
                try? await Task.sleep(for: .seconds(Constants.rowStaggerDelay))
            }
        }
    }

    private enum Constants {
        static let rowDuration: TimeInterval = 0.3
        static let rowBounce: TimeInterval = 0.1
        static let rowStaggerDelay: TimeInterval = 0.03
        static let rowStartDelay: TimeInterval = 0.02
        static let rowExitDuration: TimeInterval = 0.15
        static let transportSize: CGFloat = 44
        static let playlistRowHeight = ExerciseLibraryRow.Constants.minHeight
    }
}

private extension View {
    func staggered(at index: Int, in visibleRows: Set<Int>) -> some View {
        let isVisible = visibleRows.contains(index)
        return opacity(isVisible ? .opaque : .zero)
            .offset(x: isVisible ? 0 : -40)
    }
}
