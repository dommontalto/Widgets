//
//  SizeReader.swift
//  Widgets
//
//  Created by Zoe Friedman on 12/9/2023.
//

import SwiftUI

struct SizeReader: ViewModifier {
    let didReadSize: (CGSize) -> Void

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .task(id: geo.size) {
                            didReadSize(geo.size)
                        }
                }
            )
    }
}

#Preview {
    Text("Hello")
        .modifier(SizeReader(didReadSize: { _ in }))
}
