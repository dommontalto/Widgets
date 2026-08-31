//
//  ExerciseLiveStrengthMenu.swift
//  Widgets
//
//  Created by Dom Montalto on 17/8/2026.
//

import SwiftUI

// The live run's player menu: the spinning record, the transport controls and
// the playlist of exercises still to come.
struct ExerciseLiveStrengthMenu: View {
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
    var onEditSupersets: () -> Void
    var onReorder: () -> Void
    var onCancel: () -> Void
    var onEnd: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing0x) {
                sectionLabel(
                    isPaused ? "Currently paused" : "Currently playing",
                    symbol: isPaused ? "pause" : "play",
                    color: isPaused ? .defaultOrange : .defaultGreen
                )
                    .padding(.horizontal, .spacing3x)

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

                transportControls
                    .padding(.top, .spacing4x)
                    .frame(maxWidth: .infinity)

                playlistHeader
                    .padding(.horizontal, .spacing3x)
                    .padding(.top, .spacing6x)
                    .padding(.bottom, .spacing3x)

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
                .font(.standard(size: .standout3, weight: .regular))
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
                glyph: .standout2,
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

            Menu {
                Button("Supersets", systemImage: "link", action: onEditSupersets)
                Button("Reorder", systemImage: "arrow.up.arrow.down", action: onReorder)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.standard(size: .standout3, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)
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
                        .font(.standard(size: .standout3, weight: .regular))
                        .foregroundStyle(isPaused ? Color.defaultOrange : Color.defaultGreen)
                        .contentTransition(.symbolEffect(.replace))
                        .padding(.trailing, .spacing1x)
                } else if index < currentIndex {
                    // The row itself takes the tap; the tick only reports that
                    // the exercise is behind the run.
                    BrightTick(isTicked: true)
                        .allowsHitTesting(false)
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
                .font(.standard(size: .standout3, weight: .light))
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
            "End session",
            leadingSystemImage: "xmark",
            trailingSystemImage: "flag.pattern.checkered",
            leadingColor: .defaultRed,
            trailingColor: .defaultGreen,
            onLeadingTap: { close(then: onCancel) },
            onTrailingTap: { close(then: onEnd) }
        )
    }

    private func close(then action: @escaping () -> Void) {
        withAnimation(.brightSnappy) { isExpanded = false }
        action()
    }

    private enum Constants {
        static let transportSize: CGFloat = 44
        static let playlistRowHeight = ExerciseLibraryRow.Constants.minHeight
    }
}
