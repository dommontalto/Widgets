//
//  VaultTestingModels.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import Foundation

struct VaultTestCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let backgroundName: String
    let tileName: String
    let systemImage: String
    var iconName: String?
}

enum VaultTestAvailability: String, CaseIterable, Identifiable {
    case atHomeKit = "At Home Kit"
    case inPerson = "In Person"
    case homeVisit = "Home Visit"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .atHomeKit: "cross.case"
        case .inPerson: "figure.walk"
        case .homeVisit: "house"
        }
    }

    func fulfilment(at clinic: VaultTestingClinic) -> BrightCheckoutFulfilment {
        switch self {
        case .atHomeKit: .shipped
        case .homeVisit: .delivered
        case .inPerson: .inPerson(name: clinic.name, address: clinic.address)
        }
    }
}

enum LabProvider: String, Hashable {
    case junction
    case eirly

    var countryCode: String {
        switch self {
        case .junction: "US"
        case .eirly: "AU"
        }
    }
}

struct VaultClinicTest: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let categoryId: String
    let included: [String]
    let availability: [VaultTestAvailability]
    var price: Double = 499.99
    var currency = "AUD"
    var labTestId: String?
    var labProvider: LabProvider?

    var type: VaultTestAvailability {
        availability.first ?? .inPerson
    }

    var priceText: String {
        "$\(price.formatted(.number.precision(.fractionLength(2))))"
    }
}

struct VaultTestingClinic: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let distanceKm: Double
    let latitude: Double
    let longitude: Double
    let services: [String]
    let tests: [VaultClinicTest]
    var shipsToYou = false

    var distance: String {
        shipsToYou ? "Ships to you" : String(format: "%.1f km away", distanceKm)
    }

    var provider: LabProvider? {
        LabProvider(rawValue: id)
    }

    var categories: [VaultTestCategory] {
        VaultTestCategory.demo.filter { offers($0.id) }
    }

    func offers(_ categoryId: String) -> Bool {
        tests.contains { $0.categoryId == categoryId }
    }
}

struct VaultTestDelivery: Hashable {
    let arrivesOn: Date
    var progress: Double
    var deliveredAt: Date?

    var status: String {
        guard let deliveredAt else { return "Arrives \(arrivesOn.formatted(.brightWeekday))" }
        return "Delivered: \(deliveredAt.formatted(.brightTimestamp))"
    }
}

struct VaultTestOrder: Identifiable, Hashable {
    let id = UUID()
    let number: String
    let test: VaultClinicTest
    let clinic: VaultTestingClinic
    let type: VaultTestAvailability
    let placedAt: Date
    var scheduledAt: Date?
    var address: String?
    var delivery: VaultTestDelivery?
    var paymentMethod: BrightPaymentMethod?
    var labOrderId: String?

    var reference: String {
        "Order #\(number)"
    }

    static func newNumber() -> String {
        String(Int.random(in: 100_000...999_999))
    }
}

extension VaultTestOrder {
    init(
        number: String = VaultTestOrder.newNumber(),
        test: VaultClinicTest,
        clinic: VaultTestingClinic,
        type: VaultTestAvailability,
        details: BrightCheckoutDetails,
        labOrderId: String? = nil
    ) {
        let fulfilment = type.fulfilment(at: clinic)
        self.init(
            number: number,
            test: test,
            clinic: clinic,
            type: type,
            placedAt: .now,
            scheduledAt: fulfilment.needsShipping ? nil : Constants.scheduledAt,
            address: details.address?.street ?? clinic.address,
            delivery: fulfilment.needsShipping ? Constants.delivery : nil,
            paymentMethod: details.paymentMethod,
            labOrderId: labOrderId
        )
    }

    private enum Constants {
        static let appointmentDays = 2
        static let deliveryDays = 3
        static let startingProgress = 0.25

        static var scheduledAt: Date {
            Calendar.autoupdatingCurrent.date(byAdding: .day, value: appointmentDays, to: .now) ?? .now
        }

        static var delivery: VaultTestDelivery {
            let arrives = Calendar.autoupdatingCurrent.date(byAdding: .day, value: deliveryDays, to: .now) ?? .now
            return VaultTestDelivery(arrivesOn: arrives, progress: startingProgress)
        }
    }
}

extension VaultClinicTest {
    func checkoutItem(type: VaultTestAvailability, clinic: VaultTestingClinic) -> BrightCheckoutItem {
        BrightCheckoutItem(
            title: name,
            subtitle: type.rawValue,
            systemImage: type.systemImage,
            detail: detail,
            priceText: priceText,
            currency: currency,
            fulfilment: type.fulfilment(at: clinic)
        )
    }
}

enum VaultTestingSortOrder: String, CaseIterable, Identifiable {
    case proximity = "Proximity"
    case alphabetical = "Alphabetical"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .proximity: "location"
        case .alphabetical: "textformat.abc"
        }
    }

    func sorted(_ clinics: [VaultTestingClinic]) -> [VaultTestingClinic] {
        switch self {
        case .proximity:
            clinics.sorted { $0.distanceKm < $1.distanceKm }
        case .alphabetical:
            clinics.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}
