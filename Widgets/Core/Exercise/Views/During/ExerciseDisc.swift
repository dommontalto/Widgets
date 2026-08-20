//
//  ExerciseDisc.swift
//  Widgets
//
//  Created by Dom Montalto on 18/8/2026.
//

import SwiftUI

struct ExerciseDisc: View {
    let startDate: Date
    let pauseDate: Date?
    let isExpanded: Bool
    let blockName: String
    let exerciseName: String
    let setCount: Int
    var onTogglePause: () -> Void
    var onScrub: (TimeInterval) -> Void
    var onScrubEnd: () -> Void

    @State private var lastTouch: Angle?
    @State private var grabs = 0
    @State private var wasRunning = false
    @State private var grabDate: Date?
    @State private var didTurn = false
    @State private var ticks = 0
    @State private var untickedDegrees: Double = 0
    @State private var spinOffset: Angle = .zero
    @State private var fingerTurn: Angle = .zero
    @State private var heldAngle: Angle?
    @State private var turnSpeed: Double = 0
    @State private var lastMoveDate: Date?
    @State private var coast: Task<Void, Never>?
    @State private var coastResumes = false
    @State private var coastEnds = 0

    var body: some View {
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
                // The timeline stops while the record is off screen, so coming
                // back the angle has a gap to make up. Nothing here wants an
                // animated rotation — every frame is drawn from the date — so
                // refusing the ambient one is what stops it spinning to catch
                // up.
                .transaction { $0.animation = nil }
        }
        .frame(width: Constants.discSize, height: Constants.discSize)
        .contentShape(Circle())
        .gesture(spin)
        .brightHaptic(.light, trigger: grabs)
        .brightHaptic(.soft, trigger: ticks)
        .onChange(of: coastEnds) {
            settle(resumes: coastResumes)
        }
    }

    private var spin: some Gesture {
        DragGesture(minimumDistance: .zero)
            .onChanged { value in
                let touch = touchAngle(at: value.location)

                if let lastTouch {
                    let turn = shortestTurn(from: lastTouch, to: touch)

                    if abs(turn.degrees) > Constants.turnThreshold { didTurn = true }

                    let interval = value.time.timeIntervalSince(lastMoveDate ?? value.time)
                    if interval > 0 {
                        let speed = turn.degrees / interval
                        turnSpeed += (speed - turnSpeed) * Constants.speedBlend
                    }
                    lastMoveDate = value.time

                    turnDisc(by: turn.degrees)
                } else {
                    let wasCoasting = coast != nil
                    coast?.cancel()
                    coast = nil
                    handOffTurn()

                    wasRunning = wasCoasting ? coastResumes : pauseDate == nil
                    grabDate = value.time
                    lastMoveDate = value.time
                    didTurn = false
                    turnSpeed = 0
                    heldAngle = spinAngle(at: .now)
                    if pauseDate == nil { onTogglePause() }

                    grabs += 1
                }

                self.lastTouch = touch
            }
            .onEnded { value in
                let held = didTurn || value.time.timeIntervalSince(grabDate ?? value.time) > Constants.tapWindow
                let stalled = value.time.timeIntervalSince(lastMoveDate ?? value.time) > Constants.stallSeconds
                let flick = held && !stalled ? turnSpeed : 0

                lastTouch = nil

                if abs(flick) > Constants.flickSpeed {
                    coastOff(at: flick, resumes: held == wasRunning)
                } else {
                    settle(resumes: held == wasRunning)
                }
            }
    }

    private func turnDisc(by degrees: Double) {
        fingerTurn += .degrees(degrees)
        untickedDegrees += degrees

        while abs(untickedDegrees) >= Constants.tickDegrees {
            let direction: Double = untickedDegrees < 0 ? -1 : 1
            untickedDegrees -= Constants.tickDegrees * direction
            ticks += 1
            ExerciseDiscClick.play()
            onScrub(Constants.tickSeconds * direction)
        }
    }

    private func coastOff(at flick: Double, resumes: Bool) {
        coastResumes = resumes
        coast = Task {
            var speed = min(max(flick, -Constants.coastCeiling), Constants.coastCeiling)
            var last = Date.now

            while !Task.isCancelled, abs(speed) > Constants.coastFloor {
                try? await Task.sleep(for: .seconds(Constants.coastFrame))
                guard !Task.isCancelled else { return }

                let now = Date.now
                let interval = now.timeIntervalSince(last)
                last = now

                turnDisc(by: speed * interval)
                speed *= exp(-interval / Constants.coastDrag)
            }

            guard !Task.isCancelled else { return }
            coast = nil
            coastEnds += 1
        }
    }

    private func settle(resumes: Bool) {
        if resumes { onTogglePause() }
        handOffTurn()
        onScrubEnd()
    }

    private func handOffTurn() {
        if let heldAngle {
            spinOffset += heldAngle + fingerTurn - spinAngle(at: .now)
        }
        heldAngle = nil
        fingerTurn = .zero
        untickedDegrees = 0
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

            BrightText("\(setCount) sets", size: .body2)
                .offset(x: Constants.discLabelOffset)

            Circle()
                .fill(Color.defaultCards)
                .frame(width: Constants.discHoleSize, height: Constants.discHoleSize)

            BrightText(exerciseName, size: .body2)
                .lineLimit(1)
                .offset(y: Constants.discNameOffset)
        }
        .frame(width: Constants.discSize, height: Constants.discSize)
    }

    private enum Constants {
        static let tapWindow: TimeInterval = 0.25
        static let turnThreshold: Double = 1
        static let tickDegrees: Double = 15
        static let tickSeconds: TimeInterval = 1
        static let speedBlend: Double = 0.35
        static let stallSeconds: TimeInterval = 0.08
        static let flickSpeed: Double = 90
        static let coastCeiling: Double = 720
        static let coastFloor: Double = 30
        static let coastDrag: TimeInterval = 0.55
        static let coastFrame: TimeInterval = 1.0 / 120
        static let discSize: CGFloat = 240
        static let discHoleSize: CGFloat = 35
        static let discMarkWidth: CGFloat = 4
        static let discMarkHeight: CGFloat = 76
        static let discMarkInset: CGFloat = 15
        static let discLabelOffset = (discSize + discHoleSize) / 4
        static let discNameOffset: CGFloat = 55
        static let discChipHeight: CGFloat = 27
        static let discChipStroke: CGFloat = 0.5
        static let discSpinSeconds: TimeInterval = 6
    }
}

#Preview {
    ExerciseDisc(
        startDate: .now,
        pauseDate: nil,
        isExpanded: true,
        blockName: "Working",
        exerciseName: "Bench Press",
        setCount: 3,
        onTogglePause: {},
        onScrub: { _ in },
        onScrubEnd: {}
    )
}
