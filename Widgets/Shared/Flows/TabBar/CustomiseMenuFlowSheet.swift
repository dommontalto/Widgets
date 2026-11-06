//
//  CustomiseMenuFlowSheet.swift
//  Widgets
//
//  Created by Amin Zabihi on 30/12/2025.
//

import SwiftUI

private enum CustomiseMenuFlowRoute: Hashable {
    case editor
}

struct CustomiseMenuFlowSheet: View {
    let shouldShowOnboarding: Bool
    let onDismiss: () -> Void
    @State private var path: [CustomiseMenuFlowRoute] = []
    @State private var onboardingVM = CustomiseMenuOnboardingViewModel()
    @State private var editorVM = CustomiseMenuViewModel()

    var body: some View {
        NavigationStack(path: $path) {
            if shouldShowOnboarding {
                CustomiseMenuOnboardingView(viewModel: onboardingVM)
                    .onAppear { LocalStorage.didViewCustomiseMenuOnboarding = true }
                    .navigationDestination(for: CustomiseMenuFlowRoute.self) { route in
                        switch route {
                        case .editor:
                            CustomiseMenuView(viewModel: editorVM)
                        }
                    }
            } else {
                CustomiseMenuView(viewModel: editorVM)
            }
        }
        .onChange(of: onboardingVM.didTapContinue) {
            if onboardingVM.didTapContinue {
                onboardingVM.didTapContinue = false
                path.append(.editor)
            }
        }
        .onChange(of: editorVM.didSave) {
            if editorVM.didSave {
                editorVM.didSave = false
                onDismiss()
            }
        }
    }
}
