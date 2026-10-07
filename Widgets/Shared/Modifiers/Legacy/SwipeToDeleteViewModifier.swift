//
//  SwipeToDeleteViewModifier.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 14/8/2024.
//

import SwiftUI

private struct SwipeToDeleteViewModifier<Content: View>: ViewModifier {
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false

    let swipeView: Content
    @State private var swipeViewWidth: CGFloat = 0
    @State private var onDeleted = false
    @State private var width: CGFloat = 0
    var onDelete: (() -> Void)?

    func body(content: _ViewModifier_Content<Self>) -> some View {
        ZStack {
            HStack {
                Spacer()
                Button {
                    onDeleted = true
                    onDelete?()
                } label: {
                    swipeView
                        .opacity(onDeleted ? 0 : 1)
                        .modifier(
                            SizeReader(didReadSize: { size in
                                swipeViewWidth = size.width
                            })
                        )
                }
            }
            content
                .offset(x: offset)
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { value in
                            onChanged(value: value)
                        }
                        .onEnded { value in
                            onEnd(value: value)
                        }
                )
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
    }

    private func onChanged(value: DragGesture.Value) {
        if value.translation.width < 0 {
            if isSwiped {
                offset = value.translation.width - swipeViewWidth
            } else {
                offset = value.translation.width
            }
        }
    }

    private func onEnd(value: DragGesture.Value) {
        withAnimation(.brightEaseInOut) {
            if value.translation.width < 0 {
                if -value.translation.width > width / 2 {
                    offset = -1000
                    onDeleted = true
                    onDelete?()
                } else if -offset > 50 {
                    isSwiped = true
                    offset = -swipeViewWidth
                } else {
                    isSwiped = false
                    offset = 0
                }
            } else {
                isSwiped = false
                offset = 0
            }
        }
    }
}

extension View {
    func swipeToDelete(
        swipeView: some View,
        onDelete: (() -> Void)?
    ) -> some View {
        modifier(
            SwipeToDeleteViewModifier(
                swipeView: swipeView,
                onDelete: onDelete
            )
        )
    }
}
