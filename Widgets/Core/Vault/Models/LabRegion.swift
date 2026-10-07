//
//  LabRegion.swift
//  Widgets
//

import Foundation

enum LabRegion: String, CaseIterable, Identifiable {
    case us
    case au

    var id: String { rawValue }

    var title: String {
        switch self {
        case .us: "United States"
        case .au: "Australia"
        }
    }

    var systemImage: String {
        switch self {
        case .us: "globe.americas"
        case .au: "globe.asia.australia"
        }
    }

    var provider: LabProvider {
        switch self {
        case .us: .junction
        case .au: .eirly
        }
    }

    init?(countryCode: String?) {
        guard let match = Self.allCases.first(where: { $0.provider.countryCode == countryCode?.uppercased() }) else {
            return nil
        }
        self = match
    }

    static var saved: LabRegion? {
        get { LocalStorage.labRegion.flatMap(LabRegion.init(rawValue:)) }
        set { LocalStorage.labRegion = newValue?.rawValue }
    }

    @MainActor static func resolve() async -> LabRegion {
        if let saved { return saved }
        let addressBook = BrightAddressBook()
        await addressBook.loadIfNeeded()
        return LabRegion(countryCode: addressBook.defaultAddress?.countryCode)
            ?? LabRegion(countryCode: Locale.current.region?.identifier)
            ?? .au
    }
}
