//
//  BrightAddressBook.swift
//  Widgets
//

import Foundation

@MainActor
@Observable
final class BrightAddressBook {
    private static var saved: [BrightShippingAddress] = []

    private(set) var addresses: [BrightShippingAddress] = []
    private(set) var hasLoaded = false

    var defaultAddress: BrightShippingAddress? {
        addresses.first(where: \.isDefault) ?? addresses.first
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        addresses = Self.saved
        hasLoaded = true
    }

    func add(_ address: BrightShippingAddress) async -> BrightShippingAddress? {
        var address = address
        address.isDefault = address.isDefault || addresses.isEmpty
        if address.isDefault {
            addresses = addresses.map { existing in
                var existing = existing
                existing.isDefault = false
                return existing
            }
        }
        addresses.insert(address, at: 0)
        Self.saved = addresses
        return address
    }

    func remove(_ address: BrightShippingAddress) async {
        addresses.removeAll { $0.id == address.id }
        if !addresses.isEmpty, !addresses.contains(where: \.isDefault) {
            addresses[0].isDefault = true
        }
        Self.saved = addresses
    }
}
