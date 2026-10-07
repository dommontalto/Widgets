//
//  LabCart.swift
//  Widgets
//

import Foundation

struct LabCartItem: Codable, Hashable, Identifiable {
    let labTestId: String
    let testId: String
    let name: String
    let price: Double

    var id: String { labTestId }
}

@MainActor
@Observable
final class LabCart {
    static let shared = LabCart()
    static let maxItems = 20

    private(set) var items: [LabCartItem] = LocalStorage.labCart {
        didSet { LocalStorage.labCart = items }
    }

    var isFull: Bool {
        items.count >= Self.maxItems
    }

    var labTestIds: [String] {
        items.map(\.labTestId)
    }

    func contains(_ test: VaultClinicTest) -> Bool {
        items.contains { $0.labTestId == test.labTestId }
    }

    func add(_ test: VaultClinicTest) {
        guard let labTestId = test.labTestId, !contains(test), !isFull else { return }
        items.append(LabCartItem(labTestId: labTestId, testId: test.id, name: test.name, price: test.price))
    }

    func remove(_ item: LabCartItem) {
        items.removeAll { $0.id == item.id }
    }

    func clear() {
        items = []
    }
}
