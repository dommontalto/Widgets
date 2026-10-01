//
//  AsyncImageWidget.swift
//  Widgets
//
//  Created by Zoe Friedman on 5/8/2023.
//

import SwiftUI

struct AsyncImageWidget: View {
    let imageURL: URL?
    let title: String
    let width: CGFloat?
    let height: CGFloat

    init(
        imageUrl: String?,
        title: String = "",
        width: CGFloat?,
        height: CGFloat
    ) {
        if let imageUrl {
            imageURL = URL(string: imageUrl)
        } else {
            imageURL = nil
        }
        self.title = title
        self.width = width
        self.height = height
    }

    var body: some View {
        AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.5))) { phase in
            if let image = phase.image {
                image
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.clear
            }
        }
            .modifier(WidthViewModifier(width: width))
            .frame(height: height)
            .clipped()
    }

    struct WidthViewModifier: ViewModifier {
        let width: CGFloat?
        func body(content: Content) -> some View {
            if let width {
                content.frame(width: width)
            } else {
                content.frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    AsyncImageWidget(
        imageUrl: "https://images.unsplash.com/photo-1575936123452-b67c3203c357?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8aW1hZ2V8ZW58MHx8MHx8fDA%3D&w=1000&q=80",
        width: 200,
        height: 250
    )
}
