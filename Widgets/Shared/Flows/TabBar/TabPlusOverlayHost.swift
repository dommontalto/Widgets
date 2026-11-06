//
//  TabPlusOverlayHost.swift
//  Widgets
//

import SwiftUI

struct TabPlusOverlayHost: View {
    @Bindable var controller: TabPlusOverlayController

    var body: some View {
        ZStack {
            if controller.isShowing {
                TabPlusOverlayView(viewModel: controller.viewModel)
            }
        }
        .onChange(of: controller.viewModel.didStartClose) {
            if controller.viewModel.didStartClose {
                controller.viewModel.didStartClose = false
                controller.handleCloseStarted()
            }
        }
        .onChange(of: controller.viewModel.didTapClose) {
            if controller.viewModel.didTapClose {
                controller.viewModel.didTapClose = false
                controller.handleCloseFinished()
            }
        }
    }
}
