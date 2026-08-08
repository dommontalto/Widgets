//
//  BrightStatus.swift
//  Bright
//
//  Created by Gangajaliya Sandeep on 21/5/2024.
//  Copyright © 2024 Bryan Jordan. All rights reserved.
//

import SwiftUI

struct BrightStatus: View {
    let status: String
    var withStroke = false

    private var text: String {
        let uppercased = status.uppercased()
        if uppercased == "NODATA" { return "NO DATA" }
        if uppercased == "SUBOPTIMAL" { return "SUB-OPTIMAL" }
        return !status.isEmpty ? uppercased : "NO DATA"
    }

    private var isNoData: Bool {
        text.uppercased() == "NO DATA"
    }

    private var isNumber: Bool {
        Double(status) != nil || status == "--"
    }

    var body: some View {
        ZStack {
            BrightText(
                text.uppercased(),
                size: isNumber ? .heading : .body3,
                color: isNoData ? .lightTextColor : color,
                weight: isNumber ? .regular : .light
            )
            .padding(isNoData ? .zero : .spacing1x)
            .padding(.vertical, isNumber ? -.spacing05x : .zero)
        }
        .background(
            isNoData || isRPE ? Color.clear : color.opacity(.minimalOpacity)
        )
        .clipShape(shape)
        .overlay(
            shape
                .stroke(strokeColor, lineWidth: strokeWidth)
        )
    }

    private var strokeColor: Color {
        isRPE ? color.opacity(.veryLowOpacity) : color
    }

    private var strokeWidth: CGFloat {
        if isRPE { return 1 }
        return withStroke && !isNoData ? 0.5 : 0
    }

    private var shape: AnyShape {
        isNumber
            ? AnyShape(RoundedRectangle(cornerRadius: .cornerRadius10))
            : AnyShape(Capsule())
    }

    private var isRPE: Bool {
        rpeColor != nil
    }

    private var rpeColor: Color? {
        guard text.hasPrefix("RPE "), let value = Int(text.dropFirst(4)) else { return nil }
        let ramp: Color = switch value {
        case ...3: .defaultBlue
        case 4...5: .defaultBrightPink
        case 6...7: .defaultOrange
        default: .defaultRed
        }
        return ramp
    }

    var color: Color {
        if let rpeColor { return rpeColor }

        return switch text.uppercased() {
        case "EXCELLENT", "OPTIMAL", "AVG ZONE 2", "IN RANGE":
            Color.defaultBrightGreen
        case "GOOD":
            Color.defaultBlue
        case "AVERAGE", "MODERATE":
            Color.defaultBrightPink
        case "SUB-OPTIMAL", "AVG ZONE 4", "BORDERLINE":
            Color.defaultOrange
        case "POOR", "LOW", "HIGH", "AVG ZONE 5", "LOWER", "HIGHER", "OUT OF RANGE", "WARNING":
            Color.defaultRed
        case "STANDARD":
            Color.defaultBlue
        case "AVG ZONE 1":
            Color.defaultBlue
        case "AVG ZONE 3":
            Color.defaultYellow
        case "NO DATA":
            Color.textColor
        default:
            Color.defaultBrightGreen
        }
    }
}

#Preview {
    BrightStatus(status: "GOOD")
}
