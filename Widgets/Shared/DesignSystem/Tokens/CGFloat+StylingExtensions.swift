//
//  CGFloat+StylingExtensions.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import Foundation
import SwiftUI

nonisolated extension CGFloat {
    // MARK: - Spacing

    private static var base: CGFloat = 6

    // 0pt spacing.
    static var spacing0x: CGFloat = 0

    // 1.5pt spacing.
    static var spacing025x: CGFloat = base / 4

    // 3pt spacing.
    static var spacing05x: CGFloat = base / 2

    // 6pt spacing.
    static var spacing1x: CGFloat = base

    // 9pt spacing.
    static var spacing105x: CGFloat = base + base / 2

    // 12pt spacing.
    static var spacing2x: CGFloat = base * 2

    // 15pt spacing.
    static var spacing205x: CGFloat = base * 2 + base / 2

    // 18pt spacing.
    static var spacing3x: CGFloat = base * 3

    // 24pt spacing.
    static var spacing4x: CGFloat = base * 4

    // 30pt spacing.
    static var spacing5x: CGFloat = base * 5

    // 36pt spacing.
    static var spacing6x: CGFloat = base * 6

    // 42pt spacing.
    static var spacing7x: CGFloat = base * 7

    // 48pt spacing.
    static var spacing8x: CGFloat = base * 8

    // 54pt spacing.
    static var spacing9x: CGFloat = base * 9

    // 60pt spacing.
    static var spacing10x: CGFloat = base * 10

    static var spacing11x: CGFloat = base * 11

    static var spacing12x: CGFloat = base * 12

    // MARK: - Kerning

    // Kerning size 0.
    static var defaultKerning: CGFloat = 0

    // Kerning size 0.2381.
    static var smallKerning: CGFloat = 0.2381

    // Kerning size 0.5.
    static var mediumKerning: CGFloat = 0.5

    // MARK: - Corner Radius

    static let screenCornerRadius: CGFloat = 50

    static let cardCornerRadius: CGFloat = 30

    static let squareCornerRadius: CGFloat = 14

    func concentric(inset: CGFloat) -> CGFloat {
        Swift.max(0, self - inset)
    }

    // MARK: - View

    static let viewPaddingBottom: CGFloat = .spacing8x

    static let rowHeight: CGFloat = 52

    // MARK: - Line Spacing

    static let lineSpacingLarge: CGFloat = 10

    static let lineSpacingMedium: CGFloat = 3.5
}
