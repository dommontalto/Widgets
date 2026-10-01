//
//  BackgroundImageViewModifier.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 12/10/2024.
//

import SwiftUI

struct BackgroundImageViewModifier: ViewModifier {
    @State var image: String

    func body(content: Content) -> some View {
        content
            .background(
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: UIScreen.main.bounds.width,
                        height: UIScreen.main.bounds.height
                    )
                    .ignoresSafeArea()
            )
    }
}
