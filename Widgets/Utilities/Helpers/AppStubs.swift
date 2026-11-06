//
//  AppStubs.swift
//  Widgets
//

import Foundation
import OSLog

enum LocalStorage {
    static var brightReorderOrders: [String: [String]] {
        get { UserDefaults.standard.dictionary(forKey: "brightReorderOrders") as? [String: [String]] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "brightReorderOrders") }
    }

    static var labRegion: String? {
        get { UserDefaults.standard.string(forKey: "labRegion") }
        set { UserDefaults.standard.set(newValue, forKey: "labRegion") }
    }

    static var tabPlusMenuConfiguration: [TabPlusMenuItemConfig] {
        get {
            guard let data = UserDefaults.standard.data(forKey: "tabPlusMenuConfiguration") else { return [] }
            return (try? JSONDecoder().decode([TabPlusMenuItemConfig].self, from: data)) ?? []
        }
        set { UserDefaults.standard.set(try? JSONEncoder().encode(newValue), forKey: "tabPlusMenuConfiguration") }
    }

    static var didViewCustomiseMenuOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "viewedCustomiseMenuOnboardingScreen") }
        set { UserDefaults.standard.set(newValue, forKey: "viewedCustomiseMenuOnboardingScreen") }
    }

    static var tabPlusMenuIsExpanded: Bool {
        get { UserDefaults.standard.object(forKey: "tabPlusMenuIsExpanded") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "tabPlusMenuIsExpanded") }
    }
}

@discardableResult
func Log(_ message: @autoclosure () -> String) -> String {
    let text = message()
    Logger(subsystem: Bundle.main.bundleIdentifier ?? "Widgets", category: "App").info("\(text, privacy: .public)")
    return text
}

enum BrightScreenLog {
    static func record(_ line: String) {
        Log(line)
    }
}
