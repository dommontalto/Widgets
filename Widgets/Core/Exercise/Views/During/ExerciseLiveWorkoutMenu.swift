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
    @State private var lastTouch: Angle?
    @State private var grabs = 0
    // What the run was doing before the finger landed, so letting go can put it
    // back — and whether the finger did anything more than land.
    @State private var wasRunning = false
    @State private var grabDate: Date?
    @State private var didTurn = false
    // Clicks the record round like a click wheel: one tick per notch turned.
    @State private var ticks = 0
    @State private var untickedDegrees: Double = 0
    // The finger's own contribution to where the record sits, kept so it stays
    // where it was let go, and so the clock jumping a second per notch doesn't
    // whip the disc round with it.
    @State private var spinOffset: Angle = .zero
    @State private var fingerTurn: Angle = .zero
    // The clock's share of the angle, frozen at the moment it was taken hold of.
    @State private var heldAngle: Angle?

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

                turntable
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

    // MARK: - Turntable

    private var turntable: some View {
        // Frozen while paused, and while the menu is closed there's nothing to
        // animate — the angle is derived from the clock, so it picks straight up
        // where it left off on the way back in.
        TimelineView(.animation(paused: pauseDate != nil || !isExpanded)) { context in
            Circle()
                .fill(Color.defaultCapsule)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.textColor.opacity(.veryMinimalOpacity))
                        .frame(width: Constants.discMarkWidth, height: Constants.discMarkHeight)
                        .padding(.top, Constants.discMarkInset)
                }
                .overlay { discLabels }
                .rotationEffect(discAngle(at: context.date))
        }
        .frame(width: Constants.discSize, height: Constants.discSize)
        .contentShape(Circle())
        .gesture(spin)
        .brightHaptic(.light, trigger: grabs)
        .brightHaptic(.soft, trigger: ticks)
    }

    private var spin: some Gesture {
        // No minimum distance, so resting a finger on the record stops it the
        // way it would in the world.
        DragGesture(minimumDistance: .zero)
            .onChanged { value in
                let touch = touchAngle(at: value.location)

                if let lastTouch {
                    let turn = shortestTurn(from: lastTouch, to: touch)

                    if abs(turn.degrees) > Constants.turnThreshold { didTurn = true }

                    // The record follows the finger; the clock only moves on
                    // the notches, a second at a time, so every click the wheel
                    // makes is a second on the timer.
                    fingerTurn += turn
                    untickedDegrees += turn.degrees

                    // Subtracted rather than reset, so reversing unwinds towards
                    // the notch behind instead of clicking straight away, and a
                    // drag past several notches counts every one of them.
                    while abs(untickedDegrees) >= Constants.tickDegrees {
                        let direction: Double = untickedDegrees < 0 ? -1 : 1
                        untickedDegrees -= Constants.tickDegrees * direction
                        ticks += 1
                        ExerciseDiscClick.play()
                        onScrub(Constants.tickSeconds * direction)
                    }
                } else {
                    // A hand on the record stops it dead, whatever the finger
                    // goes on to do; what happens on the way off depends on that.
                    wasRunning = pauseDate == nil
                    grabDate = value.time
                    didTurn = false
                    untickedDegrees = 0
                    fingerTurn = .zero
                    heldAngle = spinAngle(at: .now)
                    if wasRunning { onTogglePause() }

                    grabs += 1
                }

                self.lastTouch = touch
            }
            .onEnded { value in
                // A tap is the transport's play/pause, so it comes off the disc
                // in the opposite state; anything longer is a hand held against
                // a record, which leaves it however it was found.
                let held = didTurn || value.time.timeIntervalSince(grabDate ?? value.time) > Constants.tapWindow
                if held == wasRunning { onTogglePause() }

                // Hands the held angle back to the offset, so letting go leaves
                // the record exactly where the finger left it.
                if let heldAngle {
                    spinOffset += heldAngle + fingerTurn - spinAngle(at: .now)
                }

                lastTouch = nil
                grabDate = nil
                heldAngle = nil
                fingerTurn = .zero
                onScrubEnd()
            }
    }

    private func discAngle(at date: Date) -> Angle {
        (heldAngle ?? spinAngle(at: date)) + spinOffset + fingerTurn
    }

    private func spinAngle(at date: Date) -> Angle {
        let seconds = (pauseDate ?? date).timeIntervalSince(startDate)
        return .degrees(seconds / Constants.discSpinSeconds * 360)
    }

    private func touchAngle(at point: CGPoint) -> Angle {
        let centre = Constants.discSize / 2
        return .radians(atan2(point.y - centre, point.x - centre))
    }

    // Straight across the ±180° seam, so a drag past it doesn't whip the record
    // back around the long way.
    private func shortestTurn(from: Angle, to: Angle) -> Angle {
        var degrees = (to - from).degrees.truncatingRemainder(dividingBy: 360)
        if degrees > 180 {
            degrees -= 360
        } else if degrees < -180 {
            degrees += 360
        }
        return .degrees(degrees)
    }

    private var discLabels: some View {
        ZStack {
            BrightText(blockName.uppercased(), size: .body1)
                .padding(.horizontal, .spacing1x)
                .frame(height: Constants.discChipHeight)
                .overlay {
                    RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous)
                        .stroke(
                            Color.textColor.opacity(.veryLowOpacity),
                            lineWidth: Constants.discChipStroke
                        )
                }
                .offset(x: -Constants.discLabelOffset)

            BrightText("\(currentExercise.workingSetCount) sets", size: .body2)
                .offset(x: Constants.discLabelOffset)

            Circle()
                .fill(Color.defaultCards)
                .frame(width: Constants.discHoleSize, height: Constants.discHoleSize)

            BrightText(currentExercise.name, size: .body2)
                .lineLimit(1)
                .offset(y: Constants.discNameOffset)
        }
        .frame(width: Constants.discSize, height: Constants.discSize)
    }

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

            BrightPillButton("Edit") {
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
            Image(systemName: definition.category.symbol)
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
        // Longer than this, or turned at all, and the touch counts as a hold.
        static let tapWindow: TimeInterval = 0.25
        static let turnThreshold: Double = 1
        // The notch the record clicks over, in degrees — 24 to the turn.
        static let tickDegrees: Double = 15
        // What one notch is worth on the run's clock.
        static let tickSeconds: TimeInterval = 1
        static let transportSize: CGFloat = 44
        static let discSize: CGFloat = 240
        static let discHoleSize: CGFloat = 35
        static let discMarkWidth: CGFloat = 4
        static let discMarkHeight: CGFloat = 76
        static let discMarkInset: CGFloat = 15
        // Halfway between the hole's edge and the rim.
        static let discLabelOffset = (discSize + discHoleSize) / 4
        static let discNameOffset: CGFloat = 55
        static let discChipHeight: CGFloat = 27
        static let discChipStroke: CGFloat = 0.5
        // One turn of the record, in seconds.
        static let discSpinSeconds: TimeInterval = 6
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
