//
//  BrightScreenLogV5.swift
//  Bright
//

import SwiftUI

private struct BrightScreenLogModifierV5: ViewModifier {
    let name: String

    func body(content: Content) -> some View {
        content
            .onAppear { BrightScreenLog.record("Screen: open \(name)") }
            .onDisappear { BrightScreenLog.record("Screen: close \(name)") }
    }
}

extension View {
    func brightScreenLogV5(file: String?, title: String) -> some View {
        let name = file.map { URL(filePath: $0).deletingPathExtension().lastPathComponent }
            ?? (title.isEmpty ? "Untitled" : title)
        return modifier(BrightScreenLogModifierV5(name: name))
    }
}
