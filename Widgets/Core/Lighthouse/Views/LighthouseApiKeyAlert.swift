//
//  LighthouseApiKeyAlert.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import SwiftUI

extension View {
    func lighthouseApiKeyAlert(isPresented: Binding<Bool>, onSave: @escaping (String) -> Void) -> some View {
        modifier(LighthouseApiKeyAlert(isPresented: isPresented, onSave: onSave))
    }
}

private struct LighthouseApiKeyAlert: ViewModifier {
    @Binding var isPresented: Bool
    let onSave: (String) -> Void

    @State private var key = ""

    func body(content: Content) -> some View {
        content
            .alert(Constants.title, isPresented: $isPresented) {
                TextField(Constants.placeholder, text: $key)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)

                Button(Constants.saveTitle, action: save)

                Button(Constants.cancelTitle, role: .cancel) {}
            } message: {
                Text(Constants.message)
            }
    }

    private func save() {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
    }

    private enum Constants {
        static let title = "Use your API key"
        static let message = "Paste a provider key and Lighthouse will run your prompts through it."
        static let placeholder = "API key"
        static let saveTitle = "Save"
        static let cancelTitle = "Cancel"
    }
}
