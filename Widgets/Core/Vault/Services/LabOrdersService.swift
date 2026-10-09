//
//  LabOrdersService.swift
//  Widgets
//

import Foundation

protocol LabOrdersServiceProtocol {
    func getLabTests() async throws -> [JunctionLabTest]
    func createPaymentIntent(_ body: LabPaymentIntentRequest) async throws -> LabPaymentIntentResponseData
    func getOrders() async throws -> [LabOrder]
    func getOrder(id: String) async throws -> LabOrder
    func getResults(id: String) async throws -> LabResults
    func simulate(id: String) async throws -> LabOrder
    func getEirlyTests() async throws -> [EirlyTest]
    func getEirlyQuote(tests: [String]) async throws -> EirlyQuote
    func createEirlyPaymentIntent(_ body: EirlyPaymentIntentRequest) async throws -> LabPaymentIntentResponseData
}

final class LabOrdersMockService: LabOrdersServiceProtocol {
    private static var orders = LabOrdersDemo.orders

    func getLabTests() async throws -> [JunctionLabTest] {
        LabOrdersDemo.tests
    }

    func createPaymentIntent(_ body: LabPaymentIntentRequest) async throws -> LabPaymentIntentResponseData {
        guard let test = LabOrdersDemo.tests.first(where: { $0.id == body.labTestId }) else {
            throw LabOrdersMockError.notFound
        }
        let id = Self.newOrderId()
        let order = LabOrder(
            id: id,
            provider: LabProvider.junction.rawValue,
            status: LabOrdersDemo.steps[0].status,
            statusLabel: LabOrdersDemo.steps[0].label,
            completedSteps: 1,
            totalSteps: LabOrdersDemo.steps.count,
            labTest: LabOrder.Test(id: test.id, name: test.name, method: test.method, sampleType: test.sampleType),
            amountTotal: test.price.map { Int(($0 * 100).rounded()) },
            currency: LabOrdersDemo.currency,
            tracking: nil,
            referralUrl: nil,
            referrals: nil,
            createdAt: Date.now.brightISOZoned
        )
        Self.orders.insert(order, at: 0)
        Log("Labs: demo order \(id) for \(test.name)")
        return LabPaymentIntentResponseData(clientSecret: "pi_demo_secret", paymentIntentId: "pi_demo", labOrderId: id)
    }

    func getEirlyTests() async throws -> [EirlyTest] {
        LabOrdersDemo.eirlyTests
    }

    func createEirlyPaymentIntent(_ body: EirlyPaymentIntentRequest) async throws -> LabPaymentIntentResponseData {
        let tests = LabOrdersDemo.eirlyTests.filter { body.tests.contains($0.id) }
        guard let test = tests.first else {
            throw LabOrdersMockError.notFound
        }
        let quote = try await getEirlyQuote(tests: body.tests)
        let id = Self.newOrderId()
        let order = LabOrder(
            id: id,
            provider: LabProvider.eirly.rawValue,
            status: LabOrdersDemo.eirlySteps[0].status,
            statusLabel: LabOrdersDemo.eirlySteps[0].label,
            completedSteps: 1,
            totalSteps: LabOrdersDemo.eirlySteps.count,
            labTest: LabOrder.Test(
                id: test.id,
                name: tests.count == 1 ? test.name : "\(tests.count) pathology tests",
                method: nil,
                sampleType: test.testType
            ),
            amountTotal: quote.amountTotal,
            currency: LabOrdersDemo.eirlyCurrency,
            tracking: nil,
            referralUrl: nil,
            referrals: LabOrdersDemo.referrals(for: tests, orderId: id),
            createdAt: Date.now.brightISOZoned
        )
        Self.orders.insert(order, at: 0)
        Log("Labs: demo Eirly order \(id) for \(test.name)")
        return LabPaymentIntentResponseData(clientSecret: "pi_demo_secret", paymentIntentId: "pi_demo", labOrderId: id)
    }

    func getOrders() async throws -> [LabOrder] {
        Self.orders
    }

    func getOrder(id: String) async throws -> LabOrder {
        guard let order = Self.orders.first(where: { $0.id == id }) else {
            throw LabOrdersMockError.notFound
        }
        return order
    }

    func getEirlyQuote(tests: [String]) async throws -> EirlyQuote {
        let priced = LabOrdersDemo.eirlyTests.filter { tests.contains($0.id) }
        guard !priced.isEmpty else { throw LabOrdersMockError.notFound }
        let lines = priced.map { EirlyQuote.Line(label: $0.name, amount: Int((($0.price ?? 0) * 100).rounded())) }
            + LabOrdersDemo.eirlyFees
        return EirlyQuote(lines: lines, amountTotal: lines.reduce(0) { $0 + $1.amount }, currency: LabOrdersDemo.eirlyCurrency)
    }

    func getResults(id: String) async throws -> LabResults {
        LabResults(results: LabOrdersDemo.results, missingResults: nil)
    }

    func simulate(id: String) async throws -> LabOrder {
        guard let index = Self.orders.firstIndex(where: { $0.id == id }) else {
            throw LabOrdersMockError.notFound
        }
        let order = Self.orders[index]
        let steps = order.isEirly ? LabOrdersDemo.eirlySteps : LabOrdersDemo.steps
        let next = min(order.completedSteps, steps.count - 1)
        let step = steps[next]
        let referralReady = step.status == "referral_ready"
        let advanced = LabOrder(
            id: order.id,
            provider: order.provider,
            status: step.status,
            statusLabel: step.label,
            completedSteps: next + 1,
            totalSteps: order.totalSteps,
            labTest: order.labTest,
            amountTotal: order.amountTotal,
            currency: order.currency,
            tracking: step.status == "shipping" ? LabOrdersDemo.tracking : order.tracking,
            referralUrl: referralReady ? LabOrdersDemo.referralUrl : order.referralUrl,
            referrals: referralReady ? order.referrals.map(LabOrdersDemo.issued) : order.referrals,
            createdAt: order.createdAt
        )
        Self.orders[index] = advanced
        return advanced
    }

    private static func newOrderId() -> String {
        "lab_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}

enum LabOrdersMockError: Error {
    case notFound
}

enum LabOrdersDemo {
    static let currency = "usd"
    static let eirlyCurrency = "aud"
    static let eirlyFees = [
        EirlyQuote.Line(label: "Collection fee", amount: 2_500),
        EirlyQuote.Line(label: "Service fee", amount: 1_000),
    ]
    static let referralUrl = "https://example.com/referral.pdf"

    static let steps: [(status: String, label: String)] = [
        ("ordered", "Order placed"),
        ("shipping", "Kit on its way"),
        ("with_you", "Kit delivered"),
        ("returning", "Sample on its way to the lab"),
        ("at_lab", "Sample at the lab"),
        ("ready", "Results ready"),
    ]

    static let eirlySteps: [(status: String, label: String)] = [
        ("ordered", "Order placed"),
        ("referral_ready", "Referral ready"),
        ("at_lab", "Sample at the lab"),
        ("ready", "Results ready"),
    ]

    static let tracking = LabOrder.Tracking(
        outboundTrackingUrl: "https://tools.usps.com/go/TrackConfirmAction?tLabels=9400111899223197428490",
        inboundTrackingUrl: nil
    )

    static let tests: [JunctionLabTest] = [
        JunctionLabTest(
            id: "jx-female-wellness",
            name: "Female General Wellness",
            method: "testkit",
            sampleType: "dried_blood_spot",
            price: 45,
            isActive: true,
            fasting: false,
            description: nil,
            markers: nil
        ),
        JunctionLabTest(
            id: "jx-male-hormone",
            name: "Male Hormone Panel",
            method: "testkit",
            sampleType: "saliva",
            price: 89,
            isActive: true,
            fasting: false,
            description: nil,
            markers: [JunctionLabTest.Marker(name: "Testosterone"), JunctionLabTest.Marker(name: "Estradiol"), JunctionLabTest.Marker(name: "DHEA")]
        ),
        JunctionLabTest(
            id: "jx-heart-health",
            name: "Lipid Panel: At Home",
            method: "testkit",
            sampleType: "dried_blood_spot",
            price: 79,
            isActive: true,
            fasting: true,
            description: nil,
            markers: [JunctionLabTest.Marker(name: "LDL Cholesterol"), JunctionLabTest.Marker(name: "HDL Cholesterol"), JunctionLabTest.Marker(name: "ApoB")]
        ),
        JunctionLabTest(
            id: "jx-metabolic",
            name: "CMP",
            method: "testkit",
            sampleType: "dried_blood_spot",
            price: 59,
            isActive: true,
            fasting: true,
            description: nil,
            markers: [JunctionLabTest.Marker(name: "Glucose"), JunctionLabTest.Marker(name: "HbA1c")]
        ),
        JunctionLabTest(
            id: "jx-comprehensive-walk-in",
            name: "Comprehensive Walk-in Panel",
            method: "walk_in_test",
            sampleType: "serum",
            price: 129,
            isActive: true,
            fasting: true,
            description: nil,
            markers: nil
        ),
    ]

    static let eirlyTests: [EirlyTest] = [
        EirlyTest(id: "tft", name: "Thyroid Function Test", testType: "blood", price: 30),
        EirlyTest(id: "fbc", name: "Full Blood Count", testType: "blood", price: 18),
        EirlyTest(id: "iron-studies-inc-ferretin", name: "Iron Studies", testType: "blood", price: 25),
        EirlyTest(id: "vitamin-d", name: "Vitamin D", testType: "blood", price: 35),
        EirlyTest(id: "hba1c", name: "HbA1c", testType: "blood", price: 20),
        EirlyTest(id: "lipid-studies-inc-hdl", name: "Lipid Studies", testType: "blood", price: 22),
        EirlyTest(id: "testosterone", name: "Testosterone", testType: "blood", price: 30),
        EirlyTest(id: "anti-mullerian-hormone", name: "Anti-Mullerian Hormone", testType: "blood", price: 75),
        EirlyTest(id: "apolipoprotein-e", name: "Apolipoprotein E Genotype", testType: "blood", price: 95),
        EirlyTest(id: "microba-explorer-essentials", name: "Microba Explorer Essentials", testType: "stool-kit", price: 299),
        EirlyTest(id: "calprotectin-stool-nutripath-2001", name: "Calprotectin", testType: "stool-kit", price: 110),
        EirlyTest(id: "cortisol-awakening-response-nutripath-1012", name: "Cortisol Awakening Response", testType: "saliva-kit", price: 160),
    ]

    static func referrals(for tests: [EirlyTest], orderId: String) -> [LabOrder.Referral] {
        let clinic = tests.filter { !$0.isKit }
        let kits = tests.filter(\.isKit)
        let clinicReferral = clinic.isEmpty ? [] : [
            LabOrder.Referral(uuid: "\(orderId)-blood", kit: false, tests: clinic.map(\.id), status: "pending", referralUrl: nil),
        ]
        return clinicReferral + kits.map { test in
            LabOrder.Referral(uuid: "\(orderId)-\(test.id)", kit: true, tests: [test.id], status: "pending", referralUrl: nil)
        }
    }

    static func issued(_ referrals: [LabOrder.Referral]) -> [LabOrder.Referral] {
        referrals.map { referral in
            LabOrder.Referral(
                uuid: referral.uuid,
                kit: referral.kit,
                tests: referral.tests,
                status: "issued",
                referralUrl: referral.kit ? nil : referralUrl
            )
        }
    }

    static let orders: [LabOrder] = [
        LabOrder(
            id: "lab_demo_split",
            provider: LabProvider.eirly.rawValue,
            status: "referral_ready",
            statusLabel: "Referral ready",
            completedSteps: 2,
            totalSteps: 4,
            labTest: LabOrder.Test(id: "hba1c", name: "3 pathology tests", method: nil, sampleType: "blood"),
            amountTotal: 37_600,
            currency: eirlyCurrency,
            tracking: nil,
            referralUrl: referralUrl,
            referrals: [
                LabOrder.Referral(uuid: "lab_demo_split-blood", kit: false, tests: ["hba1c", "lipid-studies-inc-hdl"], status: "issued", referralUrl: referralUrl),
                LabOrder.Referral(uuid: "lab_demo_split-microba", kit: true, tests: ["microba-explorer-essentials"], status: "issued", referralUrl: nil),
            ],
            createdAt: daysAgo(0)
        ),
        LabOrder(
            id: "lab_demo_referral",
            provider: LabProvider.eirly.rawValue,
            status: "referral_ready",
            statusLabel: "Referral ready",
            completedSteps: 2,
            totalSteps: 4,
            labTest: LabOrder.Test(id: "tft", name: "Thyroid Function Test", method: nil, sampleType: "blood"),
            amountTotal: 3000,
            currency: eirlyCurrency,
            tracking: nil,
            referralUrl: referralUrl,
            referrals: nil,
            createdAt: daysAgo(1)
        ),
        LabOrder(
            id: "lab_demo_shipping",
            provider: LabProvider.junction.rawValue,
            status: "shipping",
            statusLabel: "Kit on its way",
            completedSteps: 2,
            totalSteps: 6,
            labTest: LabOrder.Test(id: "jx-male-hormone", name: "Male Hormone Panel", method: "testkit", sampleType: "saliva"),
            amountTotal: 8900,
            currency: currency,
            tracking: tracking,
            referralUrl: nil,
            referrals: nil,
            createdAt: daysAgo(2)
        ),
        LabOrder(
            id: "lab_demo_ready",
            provider: LabProvider.junction.rawValue,
            status: "ready",
            statusLabel: "Results ready",
            completedSteps: 6,
            totalSteps: 6,
            labTest: LabOrder.Test(id: "jx-heart-health", name: "Lipid Panel: At Home", method: "testkit", sampleType: "dried_blood_spot"),
            amountTotal: 7900,
            currency: currency,
            tracking: nil,
            referralUrl: nil,
            referrals: nil,
            createdAt: daysAgo(18)
        ),
    ]

    static let results: [LabResults.Biomarker] = [
        LabResults.Biomarker(name: "Total Cholesterol", result: "198", unit: "mg/dL", interpretation: "normal", isAboveMaxRange: false, isBelowMinRange: false),
        LabResults.Biomarker(name: "LDL Cholesterol", result: "142", unit: "mg/dL", interpretation: "abnormal", isAboveMaxRange: true, isBelowMinRange: false),
        LabResults.Biomarker(name: "HDL Cholesterol", result: "58", unit: "mg/dL", interpretation: "normal", isAboveMaxRange: false, isBelowMinRange: false),
        LabResults.Biomarker(name: "Triglycerides", result: "110", unit: "mg/dL", interpretation: "normal", isAboveMaxRange: false, isBelowMinRange: false),
        LabResults.Biomarker(name: "ApoB", result: "96", unit: "mg/dL", interpretation: "normal", isAboveMaxRange: false, isBelowMinRange: false),
    ]

    private static func daysAgo(_ days: Int) -> String {
        (Calendar.autoupdatingCurrent.date(byAdding: .day, value: -days, to: .now) ?? .now).brightISOZoned
    }
}

// MARK: - Structures used in data requests and responses

struct JunctionLabTest: Codable, Hashable {
    struct Marker: Codable, Hashable {
        let name: String?
    }

    let id: String
    let name: String
    let method: String?
    let sampleType: String?
    let price: Double?
    let isActive: Bool?
    let fasting: Bool?
    let description: String?
    let markers: [Marker]?

    var isOrderable: Bool {
        method == "testkit" && isActive != false && price != nil
    }

    enum CodingKeys: String, CodingKey {
        case id, name, method, price, fasting, description, markers
        case sampleType = "sample_type"
        case isActive = "is_active"
    }
}

struct EirlyTest: Codable, Hashable {
    let id: String
    let name: String
    let testType: String?
    let price: Double?

    var isKit: Bool {
        let kind = testType?.lowercased() ?? ""
        return kind.contains("kit") || kind.contains("card")
    }
}

struct EirlyQuote: Codable, Hashable {
    struct Line: Codable, Hashable {
        let label: String
        let amount: Int
    }

    let lines: [Line]
    let amountTotal: Int
    let currency: String

    var totalText: String {
        Self.text(amountTotal, currency: currency)
    }

    static func text(_ cents: Int, currency: String) -> String {
        (Decimal(cents) / 100).formatted(.currency(code: currency.uppercased()).locale(.bright))
    }
}

struct EirlyPatient: Codable, Hashable {
    let firstName: String
    let lastName: String
    let email: String
    let dob: String
    let gender: String
    let phone: String
}

struct EirlyAddress: Codable, Hashable {
    let addressLine1: String
    let addressLine2: String?
    let city: String
    let state: String
    let postCode: String
}

struct EirlyPaymentIntentRequest: Codable {
    let tests: [String]
    let patient: EirlyPatient
    let address: EirlyAddress
    let savePaymentMethod: Bool
}

struct LabPatientDetails: Codable, Hashable {
    let firstName: String
    let lastName: String
    let dob: String
    let gender: String
    let phoneNumber: String
    let email: String
}

struct LabPatientAddress: Codable, Hashable {
    let firstLine: String
    let secondLine: String?
    let city: String
    let state: String
    let zip: String
    let country: String
    let receiverName: String?
}

struct LabPaymentIntentRequest: Codable {
    let labTestId: String
    let patientDetails: LabPatientDetails
    let patientAddress: LabPatientAddress
    let savePaymentMethod: Bool
}

struct LabPaymentIntentResponseData: Codable {
    let clientSecret: String
    let paymentIntentId: String
    let labOrderId: String
}

struct LabOrder: Codable, Identifiable, Hashable {
    struct Test: Codable, Hashable {
        let id: String?
        let name: String?
        let method: String?
        let sampleType: String?
    }

    struct Tracking: Codable, Hashable {
        let outboundTrackingUrl: String?
        let inboundTrackingUrl: String?
    }

    struct Referral: Codable, Hashable, Identifiable {
        let uuid: String
        let kit: Bool
        let tests: [String]?
        let status: String?
        let referralUrl: String?

        var id: String { uuid }

        var referralURL: URL? {
            referralUrl.flatMap(URL.init(string:))
        }
    }

    let id: String
    let provider: String?
    let status: String
    let statusLabel: String
    let completedSteps: Int
    let totalSteps: Int
    let labTest: Test
    let amountTotal: Int?
    let currency: String?
    let tracking: Tracking?
    let referralUrl: String?
    let referrals: [Referral]?
    let createdAt: String?

    var isEirly: Bool { provider == "eirly" }
    var isPlaced: Bool { status != "awaiting_payment" && status != "placing" }
    var isReady: Bool { status == "ready" }
    var isFailed: Bool { status == "failed" || status == "cancelled" }

    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(completedSteps) / Double(totalSteps)
    }

    var placedAt: Date? {
        createdAt.flatMap { Date(brightISOZoned: $0) }
    }

    var referralURL: URL? {
        referralUrl.flatMap(URL.init(string:))
    }

    var eirlyReferrals: [Referral] {
        if let referrals, !referrals.isEmpty { return referrals }
        return [Referral(uuid: id, kit: false, tests: nil, status: nil, referralUrl: referralUrl)]
    }

    var providerName: String {
        isEirly ? "Eirly" : "Junction"
    }

    var availability: VaultTestAvailability {
        guard isEirly else { return .atHomeKit }
        let referrals = referrals ?? []
        return !referrals.isEmpty && referrals.allSatisfy(\.kit) ? .atHomeKit : .inPerson
    }

    var trackingURL: URL? {
        (tracking?.inboundTrackingUrl ?? tracking?.outboundTrackingUrl).flatMap(URL.init(string:))
    }

    var totalText: String? {
        guard let amountTotal else { return nil }
        let code = (currency ?? "usd").uppercased()
        return (Decimal(amountTotal) / 100).formatted(.currency(code: code).locale(.bright))
    }
}

struct LabResults: Codable {
    struct Biomarker: Codable, Hashable, Identifiable {
        let name: String
        let result: String?
        let unit: String?
        let interpretation: String?
        let isAboveMaxRange: Bool?
        let isBelowMinRange: Bool?

        var id: String { name }

        var isFlagged: Bool {
            interpretation == "abnormal" || interpretation == "critical" || isAboveMaxRange == true || isBelowMinRange == true
        }

        var valueText: String {
            [result ?? "–", unit].compactMap { $0 }.joined(separator: " ")
        }

        enum CodingKeys: String, CodingKey {
            case name, result, unit, interpretation
            case isAboveMaxRange = "is_above_max_range"
            case isBelowMinRange = "is_below_min_range"
        }
    }

    let results: [Biomarker]
    let missingResults: [String]?

    enum CodingKeys: String, CodingKey {
        case results
        case missingResults = "missing_results"
    }
}
