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

    static var labCart: [LabCartItem] {
        get {
            guard let data = UserDefaults.standard.data(forKey: "labCart") else { return [] }
            return (try? JSONDecoder().decode([LabCartItem].self, from: data)) ?? []
        }
        set { UserDefaults.standard.set(try? JSONEncoder().encode(newValue), forKey: "labCart") }
    }
}

@discardableResult
func Log(_ message: @autoclosure () -> String) -> String {
    let text = message()
    Logger(subsystem: Bundle.main.bundleIdentifier ?? "Widgets", category: "App").info("\(text, privacy: .public)")
    return text
}
