//
//  PopoverViewModifier.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 3/2/2025.
//

import SwiftUI

private struct PopoverViewModifier<PopoverContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let attachmentAnchor: PopoverAttachmentAnchor
    let popoverContent: () -> PopoverContent

    func body(content: Content) -> some View {
        content
            .popover(
                isPresented: $isPresented,
                attachmentAnchor: attachmentAnchor
            ) {
                popoverContent()
                    .presentationCompactAdaptation(.none)
            }
    }
}

extension View {
    func popoverModifier(
        isPresented: Binding<Bool>,
        attachmentAnchor: PopoverAttachmentAnchor = .point(.center),
        @ViewBuilder popoverContent: @escaping () -> some View
    ) -> some View {
        modifier(
            PopoverViewModifier(
                isPresented: isPresented,
                attachmentAnchor: attachmentAnchor,
                popoverContent: popoverContent
            )
        )
    }
}
