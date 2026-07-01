//
//  CGFloat+StylingExtensions.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import Foundation
import SwiftUI

extension CGFloat {
    // MARK: - Spacing

    private static var base: CGFloat = 6

    /// 0pt spacing.
    static var spacing0x: CGFloat = 0

    /// 1.5pt spacing.
    static var spacing025x: CGFloat = base / 4

    /// 3pt spacing.
    static var spacing05x: CGFloat = base / 2

    /// 6pt spacing.
    static var spacing1x: CGFloat = base

    /// 9pt spacing.
    static var spacing105x: CGFloat = base + base / 2

    /// 12pt spacing.
    static var spacing2x: CGFloat = base * 2

    /// 18pt spacing.
    static var spacing3x: CGFloat = base * 3

    /// 24pt spacing.
    static var spacing4x: CGFloat = base * 4

    /// 30pt spacing.
    static var spacing5x: CGFloat = base * 5

    /// 36pt spacing.
    static var spacing6x: CGFloat = base * 6

    /// 42pt spacing.
    static var spacing7x: CGFloat = base * 7

    /// 48pt spacing.
    static var spacing8x: CGFloat = base * 8

    /// 54pt spacing.
    static var spacing9x: CGFloat = base * 9

    /// 60pt spacing.
    static var spacing10x: CGFloat = base * 10

    static var spacing11x: CGFloat = base * 11

    static var spacing12x: CGFloat = base * 12

    // MARK: - Kerning

    /// Kerning size 0.
    static var defaultKerning: CGFloat = 0

    /// Kerning size 0.2381.
    static var smallKerning: CGFloat = 0.2381

    /// Kerning size 0.5.
    static var mediumKerning: CGFloat = 0.5

    // MARK: - Corner Radius

    static var cornerRadius4: CGFloat = 4

    static var cornerRadius6: CGFloat = 6

    static var cornerRadius8: CGFloat = 8

    static var cornerRadius9: CGFloat = 9

    static var cornerRadius10: CGFloat = 10

    static var cornerRadius12: CGFloat = 12

    static var cornerRadius14: CGFloat = 14

    static var cornerRadius18: CGFloat = 18

    static var cornerRadius20: CGFloat = 20

    static var cornerRadius22: CGFloat = 22

    static var cornerRadius24: CGFloat = 24

    static let cornerRadius50: CGFloat = 50

    static let largePillCornerRadius: CGFloat = 27

    static let smallPillCornerRadius: CGFloat = 32

    static let secondarySmallPillCornerRadius: CGFloat = 17

    static let modalCornerRadius: CGFloat = 30

    static let cardCornerRadius: CGFloat = 30

    // MARK: - View

    static let viewPaddingBottom: CGFloat = .spacing8x

    // MARK: - Line Spacing

    static let lineSpacingLarge: CGFloat = 10

    static let lineSpacingMedium: CGFloat = 3.5
}
