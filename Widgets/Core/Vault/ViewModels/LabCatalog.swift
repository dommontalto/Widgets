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

    private let service: LabOrdersServiceProtocol
    private var loaded: [LabRegion: VaultTestingClinic] = [:]
    private var loadingRegions: Set<LabRegion> = []

    // Optional because default arguments are evaluated off the main actor,
    // where the main-actor mock service can't be created.
    init(service: LabOrdersServiceProtocol? = nil) {
        self.service = service ?? LabOrdersMockService()
    }

    var isLoading: Bool {
        guard let region else { return true }
        return loadingRegions.contains(region)
    }

    func clinic(for region: LabRegion) -> VaultTestingClinic? {
        loaded[region]
    }

    func loadIfNeeded() async {
        if let region {
            await load(region)
        } else {
            await load(LabRegion.resolve())
        }
    }

    func select(_ region: LabRegion) async {
        LabRegion.saved = region
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
    }

    private func loadJunction() async -> VaultTestingClinic? {
        do {
            let tests = try await service.getLabTests().filter(\.isOrderable).map(Self.junctionTest)
            Log("Labs: \(tests.count) orderable Junction tests")
            return tests.isEmpty ? nil : Self.clinic(.junction, tests: tests)
        } catch {
            Log("Labs: Junction catalogue load failed – \(error)")
            return nil
        }
    }

    private func loadEirly() async -> VaultTestingClinic? {
        do {
            let tests = try await service.getEirlyTests().map(Self.eirlyTest)
            Log("Labs: \(tests.count) Eirly tests")
            return tests.isEmpty ? nil : Self.clinic(.eirly, tests: tests)
        } catch {
            Log("Labs: Eirly catalogue load failed – \(error)")
            return nil
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
            services: VaultTestCategory.demo.filter { category in
                tests.contains { $0.categoryIds.contains(category.id) }
            }.map(\.name),
            tests: tests,
            shipsToYou: true
        )
    }

    private static func junctionTest(_ test: JunctionLabTest) -> VaultClinicTest {
        let markers = test.markers?.compactMap(\.name) ?? []
        return VaultClinicTest(
            id: test.id,
            name: test.name,
            detail: junctionDetail(for: test),
            categoryIds: LabTestTypes.junction(test.name),
            included: markers.isEmpty ? [sampleLabel(test.sampleType) ?? Constants.kitTitle] : markers,
            availability: [.atHomeKit],
            price: test.price ?? 0,
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
            price: test.price ?? 0,
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
