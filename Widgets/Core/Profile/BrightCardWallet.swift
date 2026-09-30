//
//  BrightCardWallet.swift
//  Widgets
//

import Foundation

struct CardData: Codable, Identifiable, Hashable {
    let id: String
    let brand: String
    let last4: String
    let expMonth: Int
    let expYear: Int
    let wallet: String?
}

@MainActor
@Observable
final class BrightCardWallet {
    private static var storage: [CardData] = [
        CardData(id: "pm_demo_visa", brand: "visa", last4: "4242", expMonth: 8, expYear: 2029, wallet: nil),
        CardData(id: "pm_demo_mastercard", brand: "mastercard", last4: "4444", expMonth: 3, expYear: 2028, wallet: nil),
    ]

    private(set) var cards: [CardData] = []
    private(set) var hasLoaded = false

    func load() async {
        cards = Self.storage
        hasLoaded = true
    }

    func remove(_ card: CardData) async {
        Self.storage.removeAll { $0.id == card.id }
        cards = Self.storage
    }
}

extension CardData {
    var brandName: String {
        switch brand {
        case "amex": "American Express"
        case "diners": "Diners Club"
        case "jcb": "JCB"
        case "unionpay": "UnionPay"
        case "unknown": "Card"
        default: brand.capitalized
        }
    }

    var markName: String? {
        brand == "mastercard" ? ImageNames.paymentMastercardV5 : nil
    }

    var expiry: String {
        String(format: "%02d/%02d", expMonth, expYear % 100)
    }
}
