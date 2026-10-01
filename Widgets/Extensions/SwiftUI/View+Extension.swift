//
//  View+Extension.swift
//  Widgets
//
//  Created by Anthony Uccello on 2022-11-14.
//

import SwiftUI

extension View {
    func swipeGestures(
        swipeLeftAction: (() -> Void)? = nil,
        swipeRightAction: (() -> Void)? = nil,
        swipeUpAction: (() -> Void)? = nil,
        swipeDownAction: (() -> Void)? = nil
    ) -> some View {
        simultaneousGesture(
            DragGesture()
                .onEnded { gesture in
                    let horizontalTranslation = gesture.translation.width
                    let verticalTranslation = gesture.translation.height

                    let threshold: CGFloat = 60

                    if abs(horizontalTranslation) > abs(verticalTranslation) {
                        if horizontalTranslation > threshold {
                            swipeRightAction?()
                        } else if horizontalTranslation < -threshold {
                            swipeLeftAction?()
                        }
                    } else {
                        if verticalTranslation > threshold {
                            swipeDownAction?()
                        } else if verticalTranslation < -threshold {
                            swipeUpAction?()
                        }
                    }
                }
        )
    }
}

extension View {
    public func addBorder(_ content: some ShapeStyle, width: CGFloat = 1, cornerRadius: CGFloat) -> some View {
        let roundedRect = RoundedRectangle(cornerRadius: cornerRadius)
        return clipShape(roundedRect)
            .overlay(roundedRect.strokeBorder(content, lineWidth: width))
    }

    func cornerRadius(_ radius: CGFloat, corner: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corner))
    }

    func roundedCorners() -> some View {
        cornerRadius(.cornerRadius22, corner: .allCorners)
    }

    func roundedTopCorners(_ radius: CGFloat = 10) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: [.topLeft, .topRight]))
    }

    func roundedCorners(withRadius: CGFloat) -> some View {
        cornerRadius(withRadius, corner: .allCorners)
    }

    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(TapGesture().onEnded { _ in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        })
    }

    func dismissKeyboardOnSwipeDown() -> some View {
        simultaneousGesture(DragGesture().onEnded { value in
            if value.translation.height > 50 {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        })
    }

    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

extension View {
    func swipe(
        up: @escaping (() -> Void) = {},
        down: @escaping (() -> Void) = {},
        left: @escaping (() -> Void) = {},
        right: @escaping (() -> Void) = {}
    ) -> some View {
        gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onEnded { value in
                if value.translation.width < 0 { left() }
                if value.translation.width > 0 { right() }
                if value.translation.height < 0 { up() }
                if value.translation.height > 0 { down() }
            })
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

private struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        edges.map { edge -> Path in
            switch edge {
            case .top: return Path(.init(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom: return Path(.init(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading: return Path(.init(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing: return Path(.init(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }.reduce(into: Path()) { $0.addPath($1) }
    }
}

// User for graph average background
extension View {
    @ViewBuilder
    func averageBackground(
        isDisabled: Bool,
        isSameAverage: Bool,
        enabledColor: Color,
        cardColor: Color = .defaultCards
    ) -> some View {
        if isDisabled {
            frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadius22)
                        .strokeBorder(Color.textColor.opacity(0.3), lineWidth: 0.5)
                )
                .clipShape(.rect(cornerRadius: .cornerRadius22))
        } else {
            frame(height: 40)
                .modifier(
                    BrightCardModifierV5(
                        color: isSameAverage ? enabledColor : cardColor,
                        cornerRadius: .cornerRadius22
                    )
                )
        }
    }
}
