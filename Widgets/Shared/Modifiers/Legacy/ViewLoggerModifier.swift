//
//  ViewLoggerModifier.swift
//  Widgets
//
//

import SwiftUI

private struct TrackViewModifier: ViewModifier {
    let name: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                Log("Open view: \(name)")
            }
    }
}

extension View {
    func track() -> some View {
        modifier(TrackViewModifier(name: String(describing: Self.self)))
    }
}
