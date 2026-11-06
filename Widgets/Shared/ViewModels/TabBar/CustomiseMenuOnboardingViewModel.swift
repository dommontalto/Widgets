//
//  CustomiseMenuOnboardingViewModel.swift
//  Widgets
//
//  Created by Amin Zabihi on 30/12/2025.
//

import SwiftUI

@MainActor @Observable
class CustomiseMenuOnboardingViewModel {
    var title: String
    var subtitle: String

    var didTapContinue = false

    init(
        title: String = "Your Menu",
        subtitle: String = "Choose the Actions you'd like to quickly access on Bright. You can also specify the datapoint you want to see."
    ) {
        self.title = title
        self.subtitle = subtitle
    }
}

extension CustomiseMenuOnboardingViewModel {
    func handleContinueTapped() {
        didTapContinue = true
    }
}
