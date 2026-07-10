//
//  Color+StylingExtensions.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

extension Color {
    static let primaryBlue = Color(hex: "#5599FF")
    static let progressYellow = Color(hex: "#FFD129")
}

/// V4. Use these only.
extension Color {
    static let loading = Color(light: .mainBlack, dark: .mainBlack)
    static let bG = Color(light: .mediumGrey, dark: .mainBlack)

    static let homeCards = Color(light: .mainWhite, dark: Color(hex: "0E0E14"))
    static let cards = Color(light: .mainWhite, dark: .componentGrey)
    static let modalCards = Color(light: .mainWhite, dark: .componentModalCardGrey)

    static let sheetModalCards = Color(light: .mainWhite, dark: .sheetCardGrey)
    static let sheetBackground = Color(light: .mediumGrey, dark: .sheetGrey)

    static let textColor = Color(light: .black, dark: .white)
    static let reverseTextColor = Color(light: .white, dark: .black)

    static let templatesToolbarButton = Color(light: .fluorescentGreen, dark: .fluorescentGreen)

    static let largePillButtonText = Color(light: .darkGreen, dark: .darkGreen)
    static let largePillButton = Color(light: .brightGreen, dark: .brightGreen)

    static let lightTextColor = Color(light: .black, dark: .white).opacity(.lowOpacity)

    static let semiLightTextColor = Color(light: .black, dark: .white).opacity(.mediumOpacity)

    static let paragraphText = Color(light: .black, dark: .white).opacity(.lowOpacity)

    static let anchoredSheet = Color(light: .mediumGrey, dark: .sheetGrey)

    static let textFields = Color(light: .textFieldLight, dark: .textFieldDark)

    static let defaultSelectedTab = Color(light: .mainWhite, dark: .selectedTabGreyDark)
    static let defaultDeselectedTab = Color(light: .deselectedTabGreyLight, dark: .deselectedTabGreyDark)

    static let warningText = Color(light: .warningRed, dark: .pastelPink)

    static let defaultMainBlack = Color(light: .mainBlack, dark: .mainBlack)
    static let defaultMainWhite = Color(light: .mainWhite, dark: .mainWhite)
    static let defaultMainGrey = Color(light: .mainGreyLight, dark: .mainGreyDark)
    static let defaultWhiteBlack = Color(light: .mainBlack, dark: .mainWhite)
    static let defaultBlackWhite = Color(light: .mainWhite, dark: .mainBlack)

    static let defaultDarkGreen = Color(light: .darkGreen, dark: .darkGreen)

    static let defaultBrightGreen = Color(light: .brightGreen, dark: .brightGreen)

    // Genome PRS gradient stops
    static let genomePRSCyan   = Color(hex: "00EEFF")
    static let genomePRSGreen  = Color(hex: "00FF5F")
    static let genomePRSYellow = Color(hex: "FFCA1D")
    static let genomePRSPink   = Color(hex: "FF39C4")
    static let genomePRSRed    = Color(hex: "FF3239")

    static let successGreen = Color(light: .darkGreen, dark: .brightGreen)
    static let defaultPastelPink = Color(light: .pastelPink, dark: .pastelPink)

    static let defaultElectricBlue = Color(light: .electricBlue, dark: .electricBlue)
    static let defaultSkyBlue = Color(light: .skyBlue, dark: .skyBlue)
    static let defaultLighthouseBlue = Color(light: .lighthouseBlue, dark: .lighthouseBlue)
    static let defaultBlue = Color(light: .electricBlue, dark: .skyBlue)
    static let defaultCyan = Color(light: .cyanLight, dark: .cyanDark)

    static let defaultBrightViolet = Color(light: .brightViolet, dark: .brightViolet)
    static let defaultPurple = Color(light: .vibrantPurple, dark: .vibrantPurple)

    static let defaultCherry = Color(light: .cherry, dark: .cherry)
    static let brightCherryPink = Color(light: .cherry, dark: .brightPink)

    static let defaultBlackCurrent = Color(light: .blackCurrent, dark: .blackCurrent)
    static let warningPurple = Color(light: .blackCurrent, dark: .brightViolet)

    static let defaultBrightPink = Color(light: .brightPink, dark: .brightPink)

    static let defaultCarbsPurple = Color(light: .carbsPurple, dark: .carbsPurple)
    static let defaultRestingPurple = Color(light: .restingPurple, dark: .restingPurple)

    static let defaultMediumGrey = Color(light: .mediumGrey, dark: .mediumGrey)

    static let defaultWarningRed = Color(light: .warningRed, dark: .warningRed)
    static let defaultRed = Color(light: .scoreRed, dark: .scoreRed)
    static let defaultOrange = Color(light: .brightOrange, dark: .brightOrange)
    static let defaultClaudeOrange = Color(light: .claudeOrange, dark: .claudeOrange)
    static let defaultYellow = Color(light: .brightYellow, dark: .brightYellow)
    static let defaultGreen = Color(light: .scoreGreen, dark: .scoreGreen)
    static let activityYellow = Color(light: .moderateActivityYellow, dark: .moderateActivityYellow)
    static let defaultLightGrey = Color(light: .lightGrey, dark: .lightGrey)

    static let defaultTextFieldDark = Color(light: .textFieldDark, dark: .textFieldDark)

    static let defaultSearchBarBg = Color(light: .searchBarBg, dark: .searchBarBg).opacity(0.2)
    static let defaultSearchBarText = Color(light: .searchBarText, dark: .searchBarText)

    static let suggestionHighlightText: Color = .defaultWhiteBlack
    static let suggestionDimText: Color = .defaultWhiteBlack.opacity(0.45)

    static let defaultRemBlue = Color(light: .remBlue, dark: .remBlue)
    static let defaultDeepBlue = Color(light: .deepBlue, dark: .deepBlue)
    static let defaultDeepBlueSecond = Color(light: .deepBlueSecond, dark: .deepBlueSecond)

    static let defaultBMR = Color(light: .bmr, dark: .bmr)
    static let defaultNeat = Color(light: .neat, dark: .neat)
    static let defaultTef = Color(light: .tef, dark: .tef)
    static let defaultEat = Color(light: .eat, dark: .eat)

    static let defaultDrink = Color(light: .drink, dark: .drink)

    static let defaultSaturatedYellow = Color(light: .saturatedYellow, dark: .saturatedYellow)
    static let defaultPolyUnsaturatedYellow = Color(light: .polyUnsaturatedYellow, dark: .polyUnsaturatedYellow)
    static let defaultTransFatYellow = Color(light: .transFatYellow, dark: .transFatYellow)

    static let defaultBreakdownBarBackground = Color(
        light: .black.opacity(0.15),
        dark: .white.opacity(0.15)
    )

    static let progressBarStartingGreen = Color(light: .startingGreenComponent, dark: .startingGreenComponent)
    static let progressBarNearingEndMaroon = Color(light: .nearEndingMaroonComponent, dark: .nearEndingMaroonComponent)
    static let progressBarEndingRed = Color(light: .endingRedComponent, dark: .endingRedComponent)

    fileprivate static let brightGreen = Color(hex: "#2FB360")
    fileprivate static let darkGreen = Color(hex: "#1A3D45")
    fileprivate static let fluorescentGreen = Color(hex: "#00D750")
    fileprivate static let scoreGreen = Color(hex: "#00C74A")

    fileprivate static let brightViolet = Color(hex: "#B872FF")
    fileprivate static let vibrantPurple = Color(hex: "#D139FF")
    fileprivate static let blackCurrent = Color(hex: "#412F45")
    fileprivate static let brightPink = Color(hex: "#FF80B5")
    fileprivate static let cherry = Color(hex: "#4D132D")
    fileprivate static let pastelPink = Color(hex: "#FFD4F6")

    fileprivate static let electricBlue = Color(hex: "#506CFF")
    fileprivate static let skyBlue = Color(hex: "#3DAEFF")
    fileprivate static let lighthouseBlue = Color(hex: "#CFEBFF")
    fileprivate static let cyanLight = Color(hex: "#00D2E1")
    fileprivate static let cyanDark = Color(hex: "#00EEFF")

    fileprivate static let carbsPurple = Color(hex: "#B472FF")
    fileprivate static let restingPurple = Color(hex: "#A5A4FF")

    fileprivate static let mainBlack = Color(hex: "#000000")
    fileprivate static let mainComponentGrey = Color(hex: "#121215")
    fileprivate static let componentGrey = Color(hex: "#1B1B20")
    fileprivate static let componentModalCardGrey = Color(hex: "#2A2A2F")
    fileprivate static let sheetGrey = Color(hex: "#18181C")
    fileprivate static let sheetCardGrey = Color(hex: "#27272E")
    fileprivate static let textFieldDark = Color(hex: "#B4B4CF").opacity(0.12)
    fileprivate static let textFieldLight = Color(hex: "#767680").opacity(0.12)

    fileprivate static let mainGreyLight = Color(hex: "#CDD4D8")
    fileprivate static let mainGreyDark = Color(hex: "#232623")
    fileprivate static let mediumGrey = Color(hex: "#EDEFF2")
    fileprivate static let lightGrey = Color(hex: "#F6F7F8")
    fileprivate static let mainWhite = Color(hex: "#FFFFFF")
    fileprivate static let selectedTabGreyDark = Color(hex: "#5A5A5A")
    fileprivate static let deselectedTabGreyLight = Color(hex: "#D7DBE5")
    fileprivate static let deselectedTabGreyDark = Color(hex: "#171717")
    fileprivate static let warningRed = Color(hex: "#FF3939")
    fileprivate static let scoreRed = Color(hex: "#FF3239")
    fileprivate static let brightOrange = Color(hex: "#FF512D")
    fileprivate static let claudeOrange = Color(hex: "#D77655")
    fileprivate static let brightYellow = Color(hex: "#FFBD13")

    fileprivate static let searchBarBg = Color(hex: "#9E9E9E")
    fileprivate static let searchBarText = Color(hex: "#767574")

    fileprivate static let remBlue = Color(hex: "#99E0FF")
    fileprivate static let deepBlue = Color(hex: "#1D3ACE")
    fileprivate static let deepBlueSecond = Color(hex: "#2D40A4")

    fileprivate static let bmr = Color(red: 0.91, green: 0.98, blue: 0.89).opacity(0.8)
    fileprivate static let neat = Color(red: 0.69, green: 0.58, blue: 0.82).opacity(0.8)
    fileprivate static let tef = Color(red: 0.97, green: 0.51, blue: 0.59).opacity(0.8)
    fileprivate static let eat = Color(red: 1, green: 0.42, blue: 0.31).opacity(0.8)

    fileprivate static let drink = Color(hex: "#5C85D3")

    fileprivate static let saturatedYellow = Color(hex: "#FF9900")
    fileprivate static let polyUnsaturatedYellow = Color(hex: "#FFB800")
    fileprivate static let transFatYellow = Color(hex: "#FFED4D")
    fileprivate static let moderateActivityYellow = Color(hex: "#E2BE00")

    fileprivate static let startingGreenComponent = Color(hex: "58CB81")
    fileprivate static let nearEndingMaroonComponent = Color(hex: "B581A0")
    fileprivate static let endingRedComponent = Color(hex: "FF3A3A")

    static let defaultCapsule = Color(light: .defaultMediumGrey.opacity(0.40), dark: .defaultLightGrey.opacity(0.15))

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
}

// MARK: - Dark Mode Support

extension UIColor {
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

extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor(light: UIColor(light), dark: UIColor(dark)))
    }
}

extension Color {
    init(redRGB: Int, greenRGB: Int, blueRGB: Int) {
        self.init(
            red: Double(redRGB) / Double(255),
            green: Double(greenRGB) / Double(255),
            blue: Double(blueRGB) / Double(255)
        )
    }

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
