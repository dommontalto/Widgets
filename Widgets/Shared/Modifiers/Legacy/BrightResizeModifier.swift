//
//  BrightResizeModifier.swift
//  Widgets
//
//  Created by Zoe Friedman on 10/10/2023.
//

import SwiftUI

// Resizes views so that they scale to phone size.
// Enter width and height as per figma designs, and the height will scale based on
// a ratio calculated from the view's provided width.
struct BrightResizeModifier: ViewModifier {
    let width: CGFloat
    let height: CGFloat
    var heightAdjustedCallback: ((CGFloat) -> Void)?

    @State private var adjustedHeight: CGFloat = 0

    init(
        width: CGFloat,
        height: CGFloat,
        heightAdjustedCallback: ((CGFloat) -> Void)? = nil
    ) {
        self.width = width
        self.height = height
        adjustedHeight = height
        self.heightAdjustedCallback = heightAdjustedCallback
    }

    func body(content: Content) -> some View {
        content
            .modifier(
                SizeReader(
                    didReadSize: { size in
                        let ratio = size.width / width
                        let newHeight = height * ratio
                        guard abs(newHeight - adjustedHeight) > 0.5 else { return }
                        adjustedHeight = newHeight
                        heightAdjustedCallback?(adjustedHeight)
                    }
                )
            )
            .frame(
                idealHeight: adjustedHeight,
                maxHeight: adjustedHeight
            )
    }
}
