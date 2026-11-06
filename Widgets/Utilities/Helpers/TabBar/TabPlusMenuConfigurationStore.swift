//
//  TabPlusMenuConfigurationStore.swift
//  Widgets
//
//  Created by Amin Zabihi on 30/12/2025.
//

import Foundation

enum TabPlusMenuConfigurationStore {
    static func loadOrDefault() -> [TabPlusMenuItemConfig] {
        let stored = LocalStorage.tabPlusMenuConfiguration
        if !stored.isEmpty {
            return normalize(stored)
        }
        return makeDefault()
    }

    static func save(_ config: [TabPlusMenuItemConfig]) {
        LocalStorage.tabPlusMenuConfiguration = normalize(config)
    }

    static func activeItems() -> [TabPlusItem] {
        let config = loadOrDefault()
        return config
            .filter(\.isActive)
            .sorted { $0.order < $1.order }
            .compactMap { TabPlusItem(rawValue: $0.id) }
    }

    static func inactiveItems() -> [TabPlusItem] {
        let config = loadOrDefault()
        return config
            .filter { !$0.isActive }
            .sorted { $0.order < $1.order }
            .compactMap { TabPlusItem(rawValue: $0.id) }
    }

    // MARK: - Private

    private static func makeDefault() -> [TabPlusMenuItemConfig] {
        let order: [TabPlusItem] = [
            .lighthouse,
            .uploadDocument,
            .startExercise,
            .describeMeal,
            .imageSearch,
            .savedMeals,
            .logActivity,
            .logWater,
            .logWeight,
            .logCycle,
            .createRecipe,
            .searchMeal,
            .manualLog,
            .scanBarcode,
            .importRecipe,
        ]
        return order.enumerated().map { idx, item in
            TabPlusMenuItemConfig(id: item.rawValue, isActive: true, order: idx)
        }
    }

    private static func normalize(_ config: [TabPlusMenuItemConfig]) -> [TabPlusMenuItemConfig] {
        var byId: [String: TabPlusMenuItemConfig] = [:]
        byId.reserveCapacity(config.count)
        for entry in config {
            byId[entry.id] = entry
        }

        let defaults = makeDefault()
        for (idx, item) in defaults.enumerated() {
            if byId[item.id] == nil {
                byId[item.id] = TabPlusMenuItemConfig(id: item.id, isActive: item.isActive, order: idx)
            }
        }

        let allowedIds = Set(defaults.map(\.id))
        byId = byId.filter { allowedIds.contains($0.key) }

        let defaultOrderById: [String: Int] = Dictionary(uniqueKeysWithValues: defaults.enumerated().map { (
            $0.element.id,
            $0.offset
        ) })
        let sorted = byId.values.sorted { lhs, rhs in
            if lhs.order != rhs.order { return lhs.order < rhs.order }
            return (defaultOrderById[lhs.id] ?? .max) < (defaultOrderById[rhs.id] ?? .max)
        }
        var active = sorted.filter(\.isActive)
        var inactive = sorted.filter { !$0.isActive }

        if active.isEmpty, let firstInactive = inactive.first {
            var promoted = firstInactive
            promoted.isActive = true
            inactive = Array(inactive.dropFirst())
            active = [promoted]
        }

        for i in active.indices {
            active[i].order = i
        }
        for j in inactive.indices {
            inactive[j].order = active.count + j
        }

        return active + inactive
    }
}
