//
//  TabPlusOverlayViewModel.swift
//  Widgets
//
//  Created by Zoe Friedman on 28/11/2023.
//

import SwiftUI

@MainActor @Observable
class TabPlusOverlayViewModel {
    var showingCreateRecipe = false
    var showingQuickLog = false
    var showingImageSearch = false
    var showingDescribe = false
    var showingScanBarcode = false
    var showingImportRecipe = false
    var showingSearchMeal = false
    var showingSavedMeals = false
    var showingLogWeight = false
    var showingLogActivity = false
    var showingLogWater = false
    var showingLogCycle = false
    var showingLighthouse = false
    var showingUploadDocument = false
    var showingStartExercise = false
    var isXRotated = true

    var shouldClose = false
    var didStartClose = false
    var didTapClose = false

    private class Constants {
        static let animationDuration: TimeInterval = 0.3
        static let delay: TimeInterval = 0.03
        static let bounce: TimeInterval = 0.1
    }

    init() {}

    func rotateX(_ isRotated: Bool) {
        isXRotated = isRotated
    }

    func triggerOpenAnimation() {
        animateInItems()
    }
}

extension TabPlusOverlayViewModel {
    func handleOnAppear() {
        animateInItems()
    }

    func handleOnDisappear() {
        reset()
    }

    func handleItemTapped(_ item: TabPlusItem) {
        shouldClose = true
    }

    func isShowing(_ item: TabPlusItem) -> Bool {
        switch item {
        case .createRecipe: showingCreateRecipe
        case .manualLog: showingQuickLog
        case .imageSearch: showingImageSearch
        case .describeMeal: showingDescribe
        case .scanBarcode: showingScanBarcode
        case .importRecipe: showingImportRecipe
        case .searchMeal: showingSearchMeal
        case .savedMeals: showingSavedMeals
        case .logWeight: showingLogWeight
        case .logActivity: showingLogActivity
        case .logWater: showingLogWater
        case .logCycle: showingLogCycle
        case .lighthouse: showingLighthouse
        case .uploadDocument: showingUploadDocument
        case .startExercise: showingStartExercise
        }
    }

    func setShowing(_ item: TabPlusItem, _ isShowing: Bool) {
        switch item {
        case .createRecipe: showingCreateRecipe = isShowing
        case .manualLog: showingQuickLog = isShowing
        case .imageSearch: showingImageSearch = isShowing
        case .describeMeal: showingDescribe = isShowing
        case .scanBarcode: showingScanBarcode = isShowing
        case .importRecipe: showingImportRecipe = isShowing
        case .searchMeal: showingSearchMeal = isShowing
        case .savedMeals: showingSavedMeals = isShowing
        case .logWeight: showingLogWeight = isShowing
        case .logActivity: showingLogActivity = isShowing
        case .logWater: showingLogWater = isShowing
        case .logCycle: showingLogCycle = isShowing
        case .lighthouse: showingLighthouse = isShowing
        case .uploadDocument: showingUploadDocument = isShowing
        case .startExercise: showingStartExercise = isShowing
        }
    }

    func applyMenuConfigToVisibilityFlags() {
        reset()
        for item in TabPlusMenuConfigurationStore.activeItems() {
            setShowing(item, true)
        }
    }
}

extension TabPlusOverlayViewModel {
    private func animateInItems() {
        // Reset all items first (without animation) to ensure animation always plays
        reset()

        // Small delay to let SwiftUI process the reset before animating
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.02))
            let items = TabPlusMenuConfigurationStore.activeItems()
            for (index, item) in items.enumerated() {
                withAnimation(
                    .bouncy(
                        duration: Constants.animationDuration,
                        extraBounce: Constants.bounce
                    )
                    .delay(Double(index) * Constants.delay)
                ) {
                    self.setShowing(item, true)
                }
            }
        }
    }

    private func reset() {
        showingCreateRecipe = false
        showingQuickLog = false
        showingImageSearch = false
        showingDescribe = false
        showingScanBarcode = false
        showingImportRecipe = false
        showingSearchMeal = false
        showingSavedMeals = false
        showingLogWeight = false
        showingLogActivity = false
        showingLogWater = false
        showingLogCycle = false
        showingLighthouse = false
        showingUploadDocument = false
        showingStartExercise = false
    }
}
