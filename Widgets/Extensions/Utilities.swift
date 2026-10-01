//
//  Utilities.swift
//  Widgets
//
//  Created by Phong Ngo on 2/8/21.
//

import SwiftUI

@MainActor @Observable
class BrightAlert {
    static let shared = BrightAlert()
    var isShowing = false
    var message = ""

    func show(message: String) {
        self.message = message
        isShowing = true
    }
}

private struct BrightAlertModifier: ViewModifier {
    @Bindable var alert = BrightAlert.shared

    func body(content: Content) -> some View {
        content
            .alert("Alert", isPresented: $alert.isShowing) {
                Button("Dismiss", role: .cancel) {}
            } message: {
                Text(alert.message)
            }
    }
}

extension View {
    func brightAlert() -> some View {
        modifier(BrightAlertModifier())
    }
}

// Keep backward compatibility
class Utilities {
    @MainActor
    class func showAlert(message: String) {
        BrightAlert.shared.show(message: message)
    }
}
