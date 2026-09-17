//
//  BrightSoftScrollEdges.swift
//  Bright
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

struct BrightSoftScrollEdges: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectStyle(.soft, for: .vertical)
        } else {
            content
        }
    }
}

extension View {
    func brightSoftScrollEdges() -> some View {
        modifier(BrightSoftScrollEdges())
    }
}
