//
//  TabPlusMenuItemConfig.swift
//  Widgets
//
//  Created by Amin Zabihi on 30/12/2025.
//

import Foundation

// Persisted configuration for the TabBar "+" menu.
// - Note: This is local-only for now. If we need cross-device sync, we should move this to the server.
struct TabPlusMenuItemConfig: Codable, Identifiable, Hashable {
    let id: String
    var isActive: Bool
    var order: Int
}
