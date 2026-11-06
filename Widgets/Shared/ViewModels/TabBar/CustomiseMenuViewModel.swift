//
//  CustomiseMenuViewModel.swift
//  Widgets
//
//  Created by Amin Zabihi on 30/12/2025.
//

import SwiftUI

@MainActor @Observable
class CustomiseMenuViewModel {
    var selectedTab: CustomiseMenuTab = .active
    var activeItems: [CustomiseMenuItemRowState]
    var inactiveItems: [CustomiseMenuItemRowState]

    var didSave = false

    private let initialActiveItems: [CustomiseMenuItemRowState]
    private let initialInactiveItems: [CustomiseMenuItemRowState]

    var hasChanges: Bool {
        activeItems != initialActiveItems || inactiveItems != initialInactiveItems
    }

    init() {
        let config = TabPlusMenuConfigurationStore.loadOrDefault()
        let active = config
            .filter(\.isActive)
            .sorted { $0.order < $1.order }
            .compactMap { cfg -> CustomiseMenuItemRowState? in
                guard let item = TabPlusItem(rawValue: cfg.id) else { return nil }
                return CustomiseMenuItemRowState(id: cfg.id, item: item, isEnabled: true)
            }
        let inactive = config
            .filter { !$0.isActive }
            .sorted { $0.order < $1.order }
            .compactMap { cfg -> CustomiseMenuItemRowState? in
                guard let item = TabPlusItem(rawValue: cfg.id) else { return nil }
                return CustomiseMenuItemRowState(id: cfg.id, item: item, isEnabled: false)
            }
        activeItems = active
        inactiveItems = inactive
        initialActiveItems = active
        initialInactiveItems = inactive
    }
}

extension CustomiseMenuViewModel {
    func save() {
        let movedToInactive = activeItems
            .filter { !$0.isEnabled }
            .map { row -> CustomiseMenuItemRowState in
                var copy = row
                copy.isEnabled = false
                return copy
            }

        var nextActive = activeItems
            .filter(\.isEnabled)
            + inactiveItems
            .filter(\.isEnabled)
            .map { row -> CustomiseMenuItemRowState in
                var copy = row
                copy.isEnabled = true
                return copy
            }

        var nextInactive = inactiveItems
            .filter { !$0.isEnabled }
            + movedToInactive

        if nextActive.isEmpty, let firstInactive = nextInactive.first {
            var promoted = firstInactive
            promoted.isEnabled = true
            nextActive = [promoted]
            nextInactive = Array(nextInactive.dropFirst())
        }

        var next: [TabPlusMenuItemConfig] = []
        next.reserveCapacity(nextActive.count + nextInactive.count)

        for (idx, row) in nextActive.enumerated() {
            next.append(TabPlusMenuItemConfig(id: row.id, isActive: true, order: idx))
        }
        for (idx, row) in nextInactive.enumerated() {
            next.append(TabPlusMenuItemConfig(id: row.id, isActive: false, order: nextActive.count + idx))
        }

        TabPlusMenuConfigurationStore.save(next)
        didSave = true
    }
}
