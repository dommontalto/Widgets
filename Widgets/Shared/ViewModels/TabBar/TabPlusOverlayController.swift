//
//  TabPlusOverlayController.swift
//  Widgets
//

import SwiftUI

@MainActor @Observable
final class TabPlusOverlayController {
    var isShowing = false
    var isPlusRotated = false
    let viewModel = TabPlusOverlayViewModel()

    func open() {
        guard !isShowing else { return }
        isShowing = true
        isPlusRotated = true
        viewModel.rotateX(false)
        viewModel.triggerOpenAnimation()
        BrightHaptic.medium.play()
    }

    func close() {
        guard isShowing else { return }
        viewModel.shouldClose = true
    }

    func dismissImmediately() {
        guard isShowing else { return }
        handleCloseStarted()
        isShowing = false
    }

    func handleCloseStarted() {
        isPlusRotated = false
        viewModel.rotateX(true)
    }

    func handleCloseFinished() {
        guard isShowing else { return }
        isShowing = false
    }
}
