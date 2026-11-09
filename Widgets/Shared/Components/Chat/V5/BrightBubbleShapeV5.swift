//
//  BrightBubbleShapeV5.swift
//  Widgets
//

import SwiftUI

struct BrightBubbleShapeV5: Shape {
    var cornerRadius: CGFloat = .cardCornerRadius

    func path(in rect: CGRect) -> Path {
        let body = CGRect(x: rect.minX, y: rect.minY, width: rect.width - BrightBubbleShapeV5.tailWidth, height: rect.height)
        let bodyPath = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: body)
        let rise = min(BrightBubbleShapeV5.tailRise, body.height / 2)

        let tail = Path { path in
            path.move(to: CGPoint(x: body.maxX - BrightBubbleShapeV5.tailReach, y: body.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                control: CGPoint(x: body.maxX - BrightBubbleShapeV5.tailWidth / 2, y: rect.maxY)
            )
            path.addQuadCurve(
                to: CGPoint(x: body.maxX, y: body.maxY - rise),
                control: CGPoint(x: body.maxX, y: rect.maxY - BrightBubbleShapeV5.tailWidth / 2)
            )
            path.addLine(to: CGPoint(x: body.maxX - BrightBubbleShapeV5.tailReach, y: body.maxY - rise))
            path.closeSubpath()
        }

        return Path(bodyPath.cgPath.union(tail.cgPath))
    }

    static let tailWidth: CGFloat = .spacing1x
    private static let tailReach: CGFloat = .spacing3x
    private static let tailRise: CGFloat = .spacing3x
}

#Preview {
    BrightText("How did I sleep last night?", size: .subheading, color: .white)
        .padding(.leading, .spacing2x)
        .padding(.trailing, .spacing2x + BrightBubbleShapeV5.tailWidth)
        .padding(.vertical, .spacing105x)
        .background(Color.defaultSkyBlue, in: BrightBubbleShapeV5())
        .padding(.spacing3x)
}
