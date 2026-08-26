//
//  Color+StylingExtensions.swift
//  Bright
//
//  Created by Zoe Friedman on 8/8/2023.
//  Copyright © 2023 Bryan Jordan. All rights reserved.
//

import SwiftUI

nonisolated extension Color {
    
    // MARK: --  Main
    
    static let textColor = Color(light: .black, dark: .white)
    static let semiLightTextColor = Color(light: .black, dark: .white).opacity(.mediumOpacity)
    static let lightTextColor = Color(light: .black, dark: .white).opacity(.lowOpacity)
    
    static let defaultBackground = Color(light: .defaultGrey, dark: .black)
    static let defaultSheetBackground = Color(light: .defaultGrey, dark: .sheetGrey)
    
    static let defaultBlack = Color(light: .black, dark: .black)
    static let defaultWhite = Color(light: .white, dark: .white)
    static let defaultMainGrey = Color(light: .mainGreyLight, dark: .mainGreyDark)
    static let defaultWhiteBlack = Color(light: .black, dark: .white)
    static let defaultBlackWhite = Color(light: .white, dark: .black)
    
    static let defaultHomeCards = Color(light: .white, dark: .homeCardGrey)
    static let defaultCards = Color(light: .white, dark: .cardGrey)
    static let defaultModalCards = Color(light: .white, dark: .modalCardGrey)
    static let defaultSheetModalCards = Color(light: .white, dark: .sheetModalCardGrey)
    
    // MARK: -- Colours
    
    static let textFields = Color(light: .black.opacity(.finalBossLowOpacity), dark: .defaultTextFieldDark)
    static let defaultTextFieldDark = Color(hex: "#B4B4CF").opacity(.ultraLowOpacity)
    static let defaultSearchBarBg = Color(hex: "#9E9E9E").opacity(.minimalOpacity)
    
    static let defaultBlue = Color(light: .defaultElectricBlue, dark: .defaultSkyBlue)
    static let defaultSlateBlue = Color(light: .slateBlueLight, dark: .slateBlueDark)
    static let defaultCyan = Color(light: .cyanLight, dark: .cyanDark)
    // Sky blue that turns cyan in the dark — the exercise accent.
    static let defaultSkyBlueCyan = Color(light: .defaultSkyBlue, dark: .defaultCyan)
    static let defaultGreen = Color(light: .scoreGreenLight, dark: .scoreGreenDark)
    
    static let defaultGrey = Color(hex: "#EDEFF2")
    
    static let defaultDarkGreen = Color(hex: "#1A3D45")
    static let defaultBrightGreen = Color(hex: "#2FB360")
    
    static let defaultElectricBlue = Color(hex: "#506CFF")
    static let defaultSkyBlue = Color(hex: "#3DAEFF")
    
    static let defaultBrightViolet = Color(hex: "#B872FF")
    static let defaultPurple = Color(hex: "#D139FF")
    
    static let defaultCherry = Color(hex: "#4D132D")
    static let defaultBlackCurrent = Color(hex: "#412F45")
    static let defaultBrightPink = Color(hex: "#FF80B5")
    static let defaultPink = Color(hex: "#FF4CC9")
    
    static let defaultRed = Color(hex: "#FF3939")
    static let defaultOrange = Color(hex: "#FF512D")
    static let defaultYellow = Color(hex: "#FFBD13")
    
    // MARK: -- File private
    
    fileprivate static let scoreGreenLight = Color(hex: "#00D54F")
    fileprivate static let scoreGreenDark = Color(hex: "#00FF5F")
    
    fileprivate static let slateBlueLight = Color(hex: "#5C86B0")
    fileprivate static let slateBlueDark = Color(hex: "#9CC3E8")
    
    fileprivate static let cyanLight = Color(hex: "#00D2E1")
    fileprivate static let cyanDark = Color(hex: "#00EEFF")
    
    fileprivate static let mainGreyLight = Color(hex: "#CDD4D8")
    fileprivate static let mainGreyDark = Color(hex: "#232623")
    
    fileprivate static let sheetGrey = Color(hex: "#18181C")
    
    fileprivate static let homeCardGrey = Color(hex: "#0E0E14")
    fileprivate static let cardGrey = Color(hex: "#1B1B20")
    fileprivate static let modalCardGrey = Color(hex: "#27272E")
    fileprivate static let sheetModalCardGrey = Color(hex: "#2A2A2F")
    
    // MARK: -- Sections
    
    // Breakdown Widget Bar
    
    static let defaultBreakdownBarBackground = Color(light: .black.opacity(.veryMinimalOpacity),dark: .white.opacity(.veryMinimalOpacity))
    
    // Sleep
    
    static let defaultRemBlue = Color(hex: "#99E0FF")
    static let defaultDeepBlue = Color(hex: "#1D3ACE")
    static let defaultDeepBlueSecond = Color(hex: "#2D40A4")
    
    // Activity TDEE Breakdown
    
    static let defaultBMR = Color(hex: "#E8FAE3").opacity(.mediumOpacity)
    static let defaultNeat = Color(hex: "#B094D1").opacity(.mediumOpacity)
    static let defaultTef = Color(hex: "#F78296").opacity(.mediumOpacity)
    static let defaultEat = Color(hex: "#FF6B4F").opacity(.mediumOpacity)
    
    // Macros Breakdown
    
    static let defaultSaturatedYellow = Color(hex: "#FF9900")
    static let defaultPolyUnsaturatedYellow = Color(hex: "#FFB800")
    static let defaultTransFatYellow = Color(hex: "#FFED4D")
    
    // Macros Progress Bar
    
    static let progressBarStartingGreen = Color(hex: "58CB81")
    static let progressBarNearingEndMaroon = Color(hex: "B581A0")
    
    // Cycle Tracking

    static let defaultCapsule = Color(light: .black.opacity(.finalBossLowOpacity), dark: .sheetModalCardGrey)
    
    static let cycleSymptomsOnlyTop = Color(hex: "#F2E1FF")
    static let cycleSymptomsOnlyBottom = Color(hex: "#3DAEFF")
    
    static let cycleSymptomsAndFlowTop = Color(hex: "#FF7A5E")
    static let cycleSymptomsAndFlowBottom = Color(hex: "#6981FF")
    
    static let cycleFlowOnlyTop = Color(hex: "#FF9E66")
    static let cycleFlowOnlyBottom = Color(hex: "#FF5757")
    
    // Vault
    
    static let vaultGoalLongevityTop = Color(hex: "#FFEBAA")
    static let vaultGoalHormonesTop  = Color(hex: "#AAB8FF")
    static let vaultGoalGutHealthTop = Color(hex: "#FFC9E6")
    static let vaultGoalMetabolicTop = Color(hex: "#FFA98C")
    static let vaultGoalFertilityTop = Color(hex: "#AAF7FF")
    
    // Genome
    
    static let genomePRSCyan = Color(hex: "00EEFF")
    static let genomePRSGreen = Color(hex: "00FF5F")
    static let genomePRSYellow = Color(hex: "FFCA1D")
    static let genomePRSPink = Color(hex: "FF39C4")
    static let genomePRSRed = Color(hex: "FF3239")
    
    // Lighthouse
    
    static let defaultLighthouseBlue = Color(hex: "#CFEBFF")
    
    // Exercise
    
    static let exerciseLiveBar = Color(light: .white, dark: Color(hex: "#34343A").opacity(.veryLowOpacity))
    // The wash a set or block row tints with inside a card.
    static let exerciseRowTint = Color(
        light: .mainGreyLight.opacity(.ultraLowOpacity),
        dark: .sheetGrey.opacity(.veryLowOpacity)
    )
}

// MARK: - Support

nonisolated extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                return light
            case .dark:
                return dark
            @unknown default:
                return light
            }
        }
    }
}

nonisolated extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor(light: UIColor(light), dark: UIColor(dark)))
    }
}

nonisolated extension Color {
    init(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        guard cString.count == 6 else {
            self.init(red: 0, green: 0, blue: 0)
            return
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
    
    func interpolated(to color: Color, fraction: CGFloat) -> Color {
        let clampedFraction = min(max(fraction, 0), 1)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(color).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 + (r2 - r1) * clampedFraction
        let g = g1 + (g2 - g1) * clampedFraction
        let b = b1 + (b2 - b1) * clampedFraction
        let a = a1 + (a2 - a1) * clampedFraction
        
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}
