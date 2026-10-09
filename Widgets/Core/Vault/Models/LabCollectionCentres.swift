//
//  LabCollectionCentres.swift
//  Widgets
//

import CoreLocation
import Foundation

nonisolated struct LabCollectionCentre: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let brand: String
    let address: String
    let phone: String
    let lat: Double
    let lng: Double
    let network: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var phoneURL: URL? {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        return digits.isEmpty ? nil : URL(string: "tel:\(digits)")
    }

    func distanceKm(from location: CLLocation?) -> Double? {
        location.map { $0.distance(from: CLLocation(latitude: lat, longitude: lng)) / 1000 }
    }
}

nonisolated struct LabCentreTest: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let genetic: Bool
}

nonisolated struct LabCollectionCentres: Decodable {
    let tests: [String: [LabCentreTest]]
    let centres: [LabCollectionCentre]

    func tests(at centre: LabCollectionCentre) -> [LabCentreTest] {
        tests[centre.network] ?? []
    }

    @MainActor static func load() async -> LabCollectionCentres? {
        let result = await Task.detached(priority: .userInitiated) { () -> Result<LabCollectionCentres, Error> in
            Result {
                guard let url = Bundle.main.url(forResource: "au-collection-centres", withExtension: "json") else {
                    throw CocoaError(.fileNoSuchFile)
                }
                return try JSONDecoder().decode(LabCollectionCentres.self, from: Data(contentsOf: url))
            }
        }.value
        switch result {
        case let .success(centres):
            return centres
        case let .failure(error):
            Log("Labs: collection centres failed to load – \(error)")
            return nil
        }
    }
}
