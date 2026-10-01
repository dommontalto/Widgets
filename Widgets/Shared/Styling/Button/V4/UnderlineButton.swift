//
//  UnderlineButton.swift
//  Widgets
//
//  Created by Zoe Friedman on 25/10/2023.
//

import SwiftUI

struct UnderlineButton: View {
    let title: String
    let size: FontSizes
    let color: Color
    let onTapCallback: (() -> Void)?

    init(
        _ title: String,
        size: FontSizes = .subheading,
        color: Color = .textColor,
        onTapCallback: (() -> Void)?
    ) {
        self.title = title
        self.size = size
        self.color = color
        self.onTapCallback = onTapCallback
    }

    var body: some View {
        Button(action: { onTapCallback?() }) {
            BrightText(
                title,
                size: size,
                color: color
            )
            .underline()
        }
    }
}

#Preview {
    UnderlineButton("") {}
}
