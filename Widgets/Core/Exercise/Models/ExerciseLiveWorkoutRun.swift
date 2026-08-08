//
//  ExerciseLiveWorkoutRun.swift
//  Widgets
//
//  Created by Dom Montalto on 8/8/2026.
//

import SwiftUI

// The workout in progress. It lives outside the live sheet so closing that
// sheet only puts the run away — the sets, the clock and the rest timer are
// still here when it's opened back up.
@MainActor @Observable
final class ExerciseLiveWorkoutRun {
    let name: String
    // The saved workout this started from, so the run can be folded back into it.
    let workout: ExerciseQuickWorkout?
    var exercises: [ExerciseActiveExercise]
    var currentIndex = 0
    var restEndDate: Date?
    let startDate = Date()

    init(name: String = "Gym workout", workout: ExerciseQuickWorkout? = nil, templateItems: [ExerciseTemplateItem]? = nil) {
        self.name = name
        self.workout = workout
        exercises = templateItems.map(ExerciseActiveExercise.fromTemplate) ?? ExerciseDemoData.activeExercises
    }

    var currentExercise: ExerciseActiveExercise {
        exercises[currentIndex]
    }

    var activeSet: ExerciseActiveSet? {
        currentExercise.sets.first { !$0.isDone }
    }

    var completedSets: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isDone).count }
    }

    // MARK: - Status

    // Drives the card, whether it's in the live sheet or docked behind it.
    var status: ExerciseLiveWorkoutStatusWidget.Status {
        if let restEndDate {
            .resting(upNext: currentBlockName, until: restEndDate)
        } else if activeSet == nil {
            isLastExercise ? .allSetsComplete : .nextExercise(name: exercises[currentIndex + 1].name)
        } else {
            .working(label: currentBlockName)
        }
    }

    var isLastExercise: Bool {
        currentIndex == exercises.count - 1
    }

    var currentBlockName: String {
        guard let activeSet else { return "Finished" }
        if activeSet.isWarmup { return "Warmup" }
        return "Set \(workingIndex(of: activeSet))"
    }

    func workingIndex(of set: ExerciseActiveSet) -> Int {
        let counted = currentExercise.sets.filter(\.kind.countsAsSet)
        return (counted.firstIndex { $0.id == set.id } ?? 0) + 1
    }

    // MARK: - Actions

    // Returns false once there's nothing left to advance to, so the caller can
    // finish the workout — the run doesn't own what comes after itself.
    @discardableResult
    func completeActiveSet() -> Bool {
        guard let activeSet, let index = currentExercise.sets.firstIndex(where: { $0.id == activeSet.id }) else {
            return advance()
        }
        exercises[currentIndex].sets[index].isDone = true
        if self.activeSet != nil {
            restEndDate = Date().addingTimeInterval(Constants.restSeconds)
        }
        return true
    }

    // Cuts rest short so the next set becomes active straight away.
    func skip() {
        restEndDate = nil
    }

    func extendRest(by seconds: TimeInterval) {
        restEndDate = restEndDate?.addingTimeInterval(seconds)
    }

    @discardableResult
    func advance() -> Bool {
        guard currentIndex + 1 < exercises.count else { return false }
        currentIndex += 1
        return true
    }

    private enum Constants {
        static let restSeconds: TimeInterval = 90
    }
}
