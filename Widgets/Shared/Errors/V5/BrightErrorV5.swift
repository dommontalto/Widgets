//
//  BrightErrorV5.swift
//  Bright
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

private struct BrightErrorModifierV5: ViewModifier {
    @Binding var error: (any BrightError)?

    func body(content: Content) -> some View {
        content
            .onChange(of: error != nil, initial: true) { _, hasError in
                guard hasError, let error else { return }
                Log("BrightError: \(error)")
                switch error.surface {
                case .toast:
                    BrightToastPresenterV5.shared.error(error.message)
                    self.error = nil
                case .silent:
                    self.error = nil
                case .alert:
                    break
                }
            }
            .alert(error?.message ?? "", isPresented: isShowingAlert) {
                Button("OK", role: .cancel) {}
            }
    }

    private var isShowingAlert: Binding<Bool> {
        Binding(
            get: { error?.surface == .alert },
            set: { if !$0 { error = nil } }
        )
    }
}

extension View {
    func brightErrorV5(_ error: Binding<(any BrightError)?>) -> some View {
        modifier(BrightErrorModifierV5(error: error))
    }
}
