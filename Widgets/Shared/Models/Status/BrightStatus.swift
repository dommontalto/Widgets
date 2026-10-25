//
//  BrightStatus.swift
//  Bright
//
//  Created by Gangajaliya Sandeep on 21/5/2024.
//  Copyright © 2024 Bryan Jordan. All rights reserved.
//
import SwiftUI

struct BrightStatus: View {
    let status: String?
    var withStroke = false

    private var text: String {
        (status ?? "").uppercased()
    }

    private var isNumber: Bool {
        Double(text) != nil || text == "--"
    }

    var body: some View {
        if !text.isEmpty {
            BrightText(
                text,
                size: isNumber ? .heading : .body3,
                color: color,
                weight: isNumber ? .regular : .light
            )
            .padding(.spacing1x)
            .padding(.vertical, isNumber ? -.spacing05x : .zero)
            // The fill is drawn in the shape rather than the view clipped to it:
            // a clip is an offscreen pass per pill, a shaped fill is not, and
            // the text never overflows the capsule anyway.
            .background(isRPE ? Color.clear : color.opacity(.minimalOpacity), in: shape)
            .overlay(shape.stroke(strokeColor, lineWidth: strokeWidth))
        }
    }

    private var strokeColor: Color {
        isRPE ? color.opacity(.veryLowOpacity) : color
    }

    private var strokeWidth: CGFloat {
        if isRPE { return 1 }
        return withStroke ? 0.5 : 0
    }

    private var shape: AnyShape {
        isNumber
            ? AnyShape(RoundedRectangle(cornerRadius: .squareCornerRadius))
            : AnyShape(Capsule())
    }

    private var isRPE: Bool {
        rpe != nil
    }

    private var rpe: Int? {
        guard text.hasPrefix("RPE ") else { return nil }
        return Int(text.dropFirst(4))
    }

    private var zone: Int? {
        guard text.hasPrefix("ZONE ") else { return nil }
        return Int(text.dropFirst(5))
    }

    private static func rampColor(_ step: Int) -> Color {
        switch step {
        case ...1: .defaultBlue
        case 2: .defaultGreen
        case 3: .defaultYellow
        case 4: .defaultOrange
        default: .defaultRed
        }
    }

    var color: Color {
        if let rpe { return Self.rampColor((rpe + 1) / 2) }
        if let zone { return Self.rampColor(zone) }

        return switch text {
        case "OPTIMAL", "IN PROGRESS":
            Color.defaultGreen
        case "SUB-OPTIMAL":
            Color.defaultOrange
        case "LOW", "HIGH", "LOWER", "HIGHER":
            Color.defaultRed
        default:
            Color.lightTextColor
        }
    }
}

#Preview {
    BrightStatus(status: "OPTIMAL")
}
