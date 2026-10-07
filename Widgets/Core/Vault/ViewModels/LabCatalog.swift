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
            services: Array(Set(tests.map(\.categoryId))).sorted().compactMap { id in
                VaultTestCategory.demo.first { $0.id == id }?.name
            },
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
            categoryId: category(for: test.name, markers: markers),
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
            detail: Constants.eirlyDetail,
            categoryId: category(for: test.name, markers: []),
            included: [sampleLabel(test.testType).map { "\($0) test" } ?? Constants.referralTitle],
            availability: [.inPerson],
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

    private static func sampleLabel(_ sampleType: String?) -> String? {
        guard let sampleType, !sampleType.isEmpty else { return nil }
        let words = sampleType.replacingOccurrences(of: "_", with: " ")
        return words.prefix(1).uppercased() + words.dropFirst()
    }

    private static func category(for name: String, markers: [String]) -> String {
        let text = ([name] + markers).joined(separator: " ").lowercased()
        return Constants.categoryKeywords.first { _, keywords in
            keywords.contains { text.contains($0) }
        }?.id ?? Constants.defaultCategory
    }

    private enum Constants {
        static let junctionName = "Junction"
        static let junctionAddress = "At-home lab kits · ships to US addresses"
        static let junctionCurrency = "USD"
        static let eirlyName = "Eirly"
        static let eirlyAddress = "Pathology referrals · Australian collection centres"
        static let eirlyCurrency = "AUD"
        static let eirlyDetail = "A pathology referral emailed to you. Take it to any partner collection centre in Australia, and your results appear in Bright. Collection fees and GST are added at checkout."
        static let kitTitle = "At-home test kit"
        static let referralTitle = "Pathology referral"
        static let fastingNote = " Fasting is required before collection."
        static let defaultCategory = "longevity"
        static let categoryKeywords: [(id: String, keywords: [String])] = [
            ("fertility", ["fertility", "amh", "ovarian", "sperm"]),
            ("hormones", ["hormone", "testosterone", "estradiol", "oestradiol", "estrogen", "thyroid", "tsh", "tft", "cortisol", "dhea"]),
            ("heart", ["heart", "lipid", "cholesterol", "cardio", "apob", "ldl", "hdl"]),
            ("metabolic", ["metabolic", "glucose", "a1c", "diabetes", "insulin"]),
            ("vitamins", ["vitamin", "ferritin", "iron", "b12", "folate", "magnesium", "zinc"]),
            ("gut", ["gut", "stool", "microbiome", "coeliac", "celiac", "digest"]),
            ("sleep", ["sleep", "melatonin"]),
        ]
    }
}

extension VaultTestingClinic {
    @MainActor static var all: [VaultTestingClinic] {
        LabCatalog.shared.clinics + demo
    }
}
