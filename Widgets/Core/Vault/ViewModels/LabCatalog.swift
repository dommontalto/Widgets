//
//  LabCatalog.swift
//  Widgets
//

import Foundation

@MainActor
@Observable
final class LabCatalog {
    static let shared = LabCatalog()

    private(set) var clinics: [VaultTestingClinic] = []
    private(set) var region: LabRegion?
    // Unknown until GET labs/availability answers; ordering stays closed until then.
    private(set) var availability: [LabProvider: LabAvailability.Provider] = [:]

    private let service: LabOrdersServiceProtocol
    private var loaded: [LabRegion: VaultTestingClinic] = [:]
    private var loadingRegions: Set<LabRegion> = []

    // Optional because default arguments are evaluated off the main actor,
    // where the main-actor mock service can't be created.
    init(service: LabOrdersServiceProtocol? = nil) {
        self.service = service ?? LabOrdersMockService()
    }

    var isLoading: Bool {
        guard let region else { return LabOrdering.isAvailable }
        return loadingRegions.contains(region)
    }

    func clinic(for region: LabRegion) -> VaultTestingClinic? {
        loaded[region]
    }

    func canOrder(_ provider: LabProvider) -> Bool {
        availability[provider]?.available == true
    }

    func unavailableMessage(_ provider: LabProvider) -> String {
        availability[provider]?.message ?? Constants.unavailableMessage
    }

    func refreshAvailability() async {
        do {
            let answer = try await service.getAvailability()
            availability = Dictionary(uniqueKeysWithValues: LabProvider.allCases.compactMap { provider in
                answer.providers[provider.rawValue].map { (provider, $0) }
            })
        } catch {
            Log("Labs: availability failed – \(error)")
            availability = [:]
        }
    }

    func loadIfNeeded() async {
        guard LabOrdering.isAvailable else { return }
        await refreshAvailability()
        if let region {
            await load(region)
        } else {
            await load(LabRegion.resolve())
        }
    }

    func select(_ region: LabRegion) async {
        LabRegion.saved = region
        // The home view loads through here: without this, ordering stays "Coming soon".
        if availability.isEmpty { await refreshAvailability() }
        await load(region)
    }

    private func load(_ region: LabRegion) async {
        self.region = region
        if let clinic = loaded[region] {
            clinics = [clinic]
            return
        }
        clinics = []
        guard !loadingRegions.contains(region) else { return }
        loadingRegions.insert(region)
        defer { loadingRegions.remove(region) }

        let clinic: VaultTestingClinic?
        switch region.provider {
        case .junction: clinic = await loadJunction()
        case .eirly: clinic = await loadEirly()
        }
        loaded[region] = clinic
        if self.region == region {
            clinics = clinic.map { [$0] } ?? []
        }
        Log("Labs: \(region.title) catalogue shows \(clinic.map { "\($0.name) (\($0.tests.count) tests)" } ?? "nothing")")
    }

    private func loadJunction() async -> VaultTestingClinic? {
        Log("Labs: loading demo Junction catalogue")
        do {
            let all = try await service.getLabTests()
            Log("Labs: Junction returned \(all.count) tests")
            for test in all {
                Log("Labs: test \(test.id) '\(test.name)' method \(test.method ?? "nil") active \(test.isActive.map(String.init) ?? "nil") price \(test.price.map { "\($0)" } ?? "nil") markers \(test.markers?.count ?? 0) results \(test.markers?.reduce(0) { $0 + ($1.expectedResults?.count ?? 0) } ?? 0) orderable \(test.isOrderable)")
            }
            let tests = all.filter(\.isOrderable).map(Self.junctionTest)
            logCategories(tests)
            Log("Labs: \(tests.count) orderable Junction tests")
            return tests.isEmpty ? nil : Self.clinic(.junction, tests: tests)
        } catch {
            Log("Labs: Junction catalogue load failed – \(error)")
            return nil
        }
    }

    private func loadEirly() async -> VaultTestingClinic? {
        Log("Labs: loading demo Eirly catalogue")
        do {
            let all = try await service.getEirlyTests()
            Log("Labs: Eirly returned \(all.count) tests")
            let tests = all.map(Self.eirlyTest)
            logCategories(tests)
            return tests.isEmpty ? nil : Self.clinic(.eirly, tests: tests)
        } catch {
            Log("Labs: Eirly catalogue load failed – \(error)")
            return nil
        }
    }

    private func logCategories(_ tests: [VaultClinicTest]) {
        for test in tests {
            Log("Labs: '\(test.name)' → categories \(test.categoryIds)")
        }
    }

    private static func clinic(_ provider: LabProvider, tests: [VaultClinicTest]) -> VaultTestingClinic {
        VaultTestingClinic(
            id: provider.rawValue,
            name: provider == .junction ? Constants.junctionName : Constants.eirlyName,
            address: provider == .junction ? Constants.junctionAddress : Constants.eirlyAddress,
            distanceKm: 0,
            latitude: 0,
            longitude: 0,
            services: VaultTestCategory.all.filter { category in
                tests.contains { $0.categoryIds.contains(category.id) }
            }.map(\.name),
            tests: tests,
            shipsToYou: true
        )
    }

    private static func junctionTest(_ test: JunctionLabTest) -> VaultClinicTest {
        // A panel is usually one marker whose individual tests are its expected results.
        let markers = test.markers?.flatMap { marker in
            let results = marker.expectedResults?.compactMap(\.name) ?? []
            return results.isEmpty ? [marker.name].compactMap { $0 } : results
        } ?? []
        return VaultClinicTest(
            id: test.id,
            name: test.name,
            detail: junctionDetail(for: test),
            categoryIds: LabTestTypes.junction(test.name),
            included: markers.isEmpty ? [sampleLabel(test.sampleType) ?? Constants.kitTitle] : markers,
            availability: [.atHomeKit],
            price: test.shownPrice,
            currency: Constants.junctionCurrency,
            labTestId: test.id,
            labProvider: .junction
        )
    }

    private static func eirlyTest(_ test: EirlyTest) -> VaultClinicTest {
        VaultClinicTest(
            id: "eirly-\(test.id)",
            name: test.name,
            detail: test.isKit ? Constants.eirlyKitDetail : Constants.eirlyDetail,
            categoryIds: LabTestTypes.eirly(test.id),
            included: [eirlyIncluded(test)],
            availability: [test.isKit ? .atHomeKit : .inPerson],
            price: test.price,
            currency: Constants.eirlyCurrency,
            labTestId: test.id,
            labProvider: .eirly
        )
    }

    private static func junctionDetail(for test: JunctionLabTest) -> String {
        if let description = test.description, !description.isEmpty { return description }
        let kit = sampleLabel(test.sampleType).map { "\($0) kit" } ?? Constants.kitTitle
        let fasting = test.fasting == true ? Constants.fastingNote : ""
        return "\(kit), posted to you. Collect your sample at home, mail it back, and your results appear in Bright.\(fasting)"
    }

    private static func eirlyIncluded(_ test: EirlyTest) -> String {
        guard let label = sampleLabel(test.testType) else {
            return test.isKit ? Constants.kitTitle : Constants.referralTitle
        }
        return test.isKit ? label : "\(label) test"
    }

    private static func sampleLabel(_ sampleType: String?) -> String? {
        guard let sampleType, !sampleType.isEmpty else { return nil }
        let words = sampleType.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
        return words.prefix(1).uppercased() + words.dropFirst()
    }

    private enum Constants {
        static let junctionName = "Junction"
        static let junctionAddress = "At-home lab kits · ships to US addresses"
        static let junctionCurrency = "USD"
        static let eirlyName = "Eirly"
        static let eirlyAddress = "Pathology referrals · Australian collection centres"
        static let eirlyCurrency = "AUD"
        static let unavailableMessage = "Lab test ordering isn't available yet"
        static let eirlyDetail = "A pathology referral emailed to you. Take it to any partner collection centre in Australia, and your results appear in Bright. Collection fees and GST are added at checkout."
        static let eirlyKitDetail = "A test kit posted to your Australian address. Follow the instructions inside to collect your sample, and your results appear in Bright. Fees and GST are added at checkout."
        static let kitTitle = "At-home test kit"
        static let referralTitle = "Pathology referral"
        static let fastingNote = " Fasting is required before collection."
    }
}

extension VaultTestingClinic {
    @MainActor static var all: [VaultTestingClinic] {
        LabCatalog.shared.clinics + demo
    }
}
