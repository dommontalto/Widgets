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
    func getResultsPDF(id: String) async throws -> LabResultsPDF
    func simulate(id: String) async throws -> LabOrder
    func getEirlyTests() async throws -> [EirlyTest]
    func getEirlyQuote(tests: [String]) async throws -> EirlyQuote
    func createEirlyPaymentIntent(_ body: EirlyPaymentIntentRequest) async throws -> LabPaymentIntentResponseData
    func getAvailability() async throws -> LabAvailability
}

// The iOS app's lab service with demo answers: new orders start "placing" and reach the lab a moment later, the way
// Stripe's webhook places them.
final class LabOrdersMockService: LabOrdersServiceProtocol {
    private static var orders = LabOrdersDemo.orders
    private static var placedAt: [String: Date] = [:]

    func getLabTests() async throws -> [JunctionLabTest] {
        LabOrdersDemo.tests
    }

    func getAvailability() async throws -> LabAvailability {
        LabOrdersDemo.availability
    }

    func createPaymentIntent(_ body: LabPaymentIntentRequest) async throws -> LabPaymentIntentResponseData {
        guard let test = LabOrdersDemo.tests.first(where: { $0.id == body.labTestId }) else {
            throw LabOrdersMockError.notFound
        }
        let id = Self.newOrderId()
        let order = LabOrder(
            id: id,
            provider: LabProvider.junction.rawValue,
            status: "placing",
            statusLabel: "Placing your order",
            completedSteps: 0,
            totalSteps: LabOrdersDemo.steps.count,
            labTest: LabOrder.Test(id: test.id, name: test.name, method: test.method, sampleType: test.sampleType),
            amountTotal: test.shownPrice.map { Int(($0 * 100).rounded()) },
            currency: LabOrdersDemo.currency,
            paymentStatus: "paid",
            refundedAmount: nil,
            failureKind: nil,
            tracking: nil,
            referralUrl: nil,
            referrals: nil,
            createdAt: Date.now.brightISOZoned
        )
        Self.add(order)
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
        let id = Self.newOrderId()
        let quote = try await getEirlyQuote(tests: body.tests)
        let order = LabOrder(
            id: id,
            provider: LabProvider.eirly.rawValue,
            status: "placing",
            statusLabel: "Placing your order",
            completedSteps: 0,
            totalSteps: LabOrdersDemo.eirlySteps.count,
            labTest: LabOrder.Test(id: test.id, name: tests.count == 1 ? test.name : "\(tests.count) pathology tests", method: nil, sampleType: test.testType),
            amountTotal: quote.amountTotal,
            currency: LabOrdersDemo.eirlyCurrency,
            paymentStatus: "paid",
            refundedAmount: nil,
            failureKind: nil,
            tracking: nil,
            referralUrl: nil,
            referrals: LabOrdersDemo.referrals(for: tests, orderId: id),
            createdAt: Date.now.brightISOZoned
        )
        Self.add(order)
        Log("Labs: demo Eirly order \(id) for \(test.name)")
        return LabPaymentIntentResponseData(clientSecret: "pi_demo_secret", paymentIntentId: "pi_demo", labOrderId: id)
    }

    func getOrders() async throws -> [LabOrder] {
        Self.placeDueOrders()
        return Self.orders
    }

    func getOrder(id: String) async throws -> LabOrder {
        Self.placeDueOrders()
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
        id == LabOrdersDemo.partialOrderId ? LabOrdersDemo.partialResults : LabOrdersDemo.results
    }

    func getResultsPDF(id: String) async throws -> LabResultsPDF {
        LabResultsPDF(url: LabOrdersDemo.reportUrl)
    }

    func simulate(id: String) async throws -> LabOrder {
        guard let index = Self.orders.firstIndex(where: { $0.id == id }) else {
            throw LabOrdersMockError.notFound
        }
        let order = Self.orders[index]
        let steps = order.isEirly ? LabOrdersDemo.eirlySteps : LabOrdersDemo.steps
        let next = min(order.completedSteps, steps.count - 1)
        let advanced = Self.order(order, at: next, of: steps)
        Self.orders[index] = advanced
        return advanced
    }

    private static func add(_ order: LabOrder) {
        orders.insert(order, at: 0)
        placedAt[order.id] = .now.addingTimeInterval(LabOrdersDemo.placingSeconds)
    }

    private static func placeDueOrders() {
        for (id, due) in placedAt where due <= .now {
            placedAt[id] = nil
            guard let index = orders.firstIndex(where: { $0.id == id }) else { continue }
            let steps = orders[index].isEirly ? LabOrdersDemo.eirlySteps : LabOrdersDemo.steps
            orders[index] = order(orders[index], at: 0, of: steps)
        }
    }

    private static func order(_ order: LabOrder, at step: Int, of steps: [(status: String, label: String)]) -> LabOrder {
        let status = steps[step].status
        let referralReady = status == "referral_ready"
        return LabOrder(
            id: order.id,
            provider: order.provider,
            status: status,
            statusLabel: steps[step].label,
            completedSteps: step + 1,
            totalSteps: order.totalSteps,
            labTest: order.labTest,
            amountTotal: order.amountTotal,
            currency: order.currency,
            paymentStatus: order.paymentStatus,
            refundedAmount: order.refundedAmount,
            failureKind: order.failureKind,
            tracking: status == "shipping" ? LabOrdersDemo.tracking : order.tracking,
            referralUrl: referralReady ? LabOrdersDemo.referralUrl : order.referralUrl,
            referrals: referralReady ? order.referrals.map(LabOrdersDemo.issued) : order.referrals,
            createdAt: order.createdAt
        )
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
    static let placingSeconds: TimeInterval = 4
    static let eirlyFees = [
        EirlyQuote.Line(label: "Collection fee", amount: 2_500),
        EirlyQuote.Line(label: "Service fee", amount: 1_000),
        EirlyQuote.Line(label: "GST", amount: 350),
    ]
    static let referralUrl = "https://example.com/referral.pdf"
    static let reportUrl = "https://example.com/lab-report.pdf"
    static let partialOrderId = "lab_demo_partial"

    static let availability = LabAvailability(providers: [
        LabProvider.junction.rawValue: LabAvailability.Provider(provider: LabProvider.junction.rawValue, available: true, message: nil, excludedStates: ["NY", "NJ", "RI"]),
        LabProvider.eirly.rawValue: LabAvailability.Provider(provider: LabProvider.eirly.rawValue, available: true, message: nil, excludedStates: nil),
    ])

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
            displayPrice: 45,
            isActive: true,
            fasting: false,
            description: nil,
            markers: [
                marker("Hormones", ["Estradiol", "Progesterone", "FSH", "LH"]),
                marker("Thyroid", ["TSH", "Free T4"]),
                marker("HbA1c"),
            ]
        ),
        JunctionLabTest(
            id: "jx-male-hormone",
            name: "Male Hormone Panel",
            method: "testkit",
            sampleType: "saliva",
            price: 89,
            displayPrice: 89,
            isActive: true,
            fasting: false,
            description: nil,
            markers: [marker("Testosterone"), marker("Estradiol"), marker("DHEA"), marker("Cortisol")]
        ),
        JunctionLabTest(
            id: "jx-heart-health",
            name: "Lipid Panel: At Home",
            method: "testkit",
            sampleType: "dried_blood_spot",
            price: 79,
            displayPrice: 79,
            isActive: true,
            fasting: true,
            description: nil,
            markers: [marker("Lipid panel", ["Total Cholesterol", "LDL Cholesterol", "HDL Cholesterol", "Triglycerides"]), marker("ApoB")]
        ),
        JunctionLabTest(
            id: "jx-metabolic",
            name: "CMP",
            method: "testkit",
            sampleType: "dried_blood_spot",
            price: 59,
            displayPrice: 59,
            isActive: true,
            fasting: true,
            description: nil,
            markers: [marker("Glucose"), marker("HbA1c"), marker("Kidney", ["Creatinine", "eGFR", "BUN"])]
        ),
        JunctionLabTest(
            id: "jx-vitamins",
            name: "Vitamin & Iron Check",
            method: "testkit",
            sampleType: "dried_blood_spot",
            price: nil,
            displayPrice: 69,
            isActive: true,
            fasting: false,
            description: nil,
            markers: [marker("Vitamin D"), marker("Vitamin B12"), marker("Ferritin")]
        ),
        JunctionLabTest(
            id: "jx-comprehensive-walk-in",
            name: "Comprehensive Walk-in Panel",
            method: "walk_in_test",
            sampleType: "serum",
            price: 129,
            displayPrice: 129,
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
        EirlyTest(id: "coeliac-serology", name: "Coeliac Serology", testType: "blood", price: nil),
        EirlyTest(id: "microba-explorer-essentials", name: "Microba Explorer Essentials", testType: "stool-kit", price: 299),
        EirlyTest(id: "calprotectin-stool-nutripath-2001", name: "Calprotectin", testType: "stool-kit", price: 110),
        EirlyTest(id: "cortisol-awakening-response-nutripath-1012", name: "Cortisol Awakening Response", testType: "saliva-kit", price: 160),
    ]

    private static func marker(_ name: String, _ results: [String] = []) -> JunctionLabTest.Marker {
        JunctionLabTest.Marker(name: name, expectedResults: results.map { JunctionLabTest.Marker.Result(name: $0) })
    }

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
        order(
            id: "lab_demo_split",
            provider: .eirly,
            status: "referral_ready",
            statusLabel: "Referral ready",
            completedSteps: 2,
            totalSteps: 4,
            labTest: LabOrder.Test(id: "hba1c", name: "3 pathology tests", method: nil, sampleType: "blood"),
            amountTotal: 37_950,
            referralUrl: referralUrl,
            referrals: [
                LabOrder.Referral(uuid: "lab_demo_split-blood", kit: false, tests: ["hba1c", "lipid-studies-inc-hdl"], status: "issued", referralUrl: referralUrl),
                LabOrder.Referral(uuid: "lab_demo_split-microba", kit: true, tests: ["microba-explorer-essentials"], status: "issued", referralUrl: nil),
            ],
            daysAgo: 0
        ),
        order(
            id: "lab_demo_shipping",
            provider: .junction,
            status: "shipping",
            statusLabel: "Kit on its way",
            completedSteps: 2,
            totalSteps: 6,
            labTest: LabOrder.Test(id: "jx-male-hormone", name: "Male Hormone Panel", method: "testkit", sampleType: "saliva"),
            amountTotal: 8_900,
            tracking: tracking,
            daysAgo: 2
        ),
        order(
            id: partialOrderId,
            provider: .junction,
            status: "partial_results",
            statusLabel: "Some results ready",
            completedSteps: 5,
            totalSteps: 6,
            labTest: LabOrder.Test(id: "jx-metabolic", name: "CMP", method: "testkit", sampleType: "dried_blood_spot"),
            amountTotal: 5_900,
            daysAgo: 9
        ),
        order(
            id: "lab_demo_ready",
            provider: .junction,
            status: "ready",
            statusLabel: "Results ready",
            completedSteps: 6,
            totalSteps: 6,
            labTest: LabOrder.Test(id: "jx-heart-health", name: "Lipid Panel: At Home", method: "testkit", sampleType: "dried_blood_spot"),
            amountTotal: 7_900,
            daysAgo: 18
        ),
        order(
            id: "lab_demo_refunded",
            provider: .junction,
            status: "failed",
            statusLabel: "Order failed",
            completedSteps: 0,
            totalSteps: 6,
            labTest: LabOrder.Test(id: "jx-female-wellness", name: "Female General Wellness", method: "testkit", sampleType: "dried_blood_spot"),
            amountTotal: 4_500,
            paymentStatus: "refunded",
            refundedAmount: 4_500,
            failureKind: "rejected",
            daysAgo: 26
        ),
    ]

    static let results = LabResults(
        status: "final",
        markers: [
            biomarker("Total Cholesterol", 198, "mg/dL", 125, 200, "normal"),
            biomarker("LDL Cholesterol", 142, "mg/dL", nil, 100, "abnormal"),
            biomarker("HDL Cholesterol", 58, "mg/dL", 40, nil, "normal"),
            biomarker("Triglycerides", 110, "mg/dL", nil, 150, "normal"),
            biomarker("ApoB", 96, "mg/dL", nil, 90, "abnormal"),
        ],
        missing: [],
        pdfAvailable: true,
        criticalNotice: nil
    )

    static let partialResults = LabResults(
        status: "partial",
        markers: [
            biomarker("Glucose", 92, "mg/dL", 70, 99, "normal"),
            biomarker("HbA1c", 5.4, "%", nil, 5.7, "normal"),
            biomarker("Creatinine", 1.0, "mg/dL", 0.6, 1.3, "normal"),
        ],
        missing: [
            LabResults.Missing(name: "eGFR", reason: nil),
            LabResults.Missing(name: "BUN", reason: "Sample haemolysed"),
        ],
        pdfAvailable: false,
        criticalNotice: nil
    )

    private static func biomarker(
        _ name: String,
        _ value: Double,
        _ unit: String,
        _ low: Double?,
        _ high: Double?,
        _ interpretation: String
    ) -> LabResults.Biomarker {
        LabResults.Biomarker(
            name: name,
            value: value,
            result: value.formatted(),
            unit: unit,
            referenceLow: low,
            referenceHigh: high,
            interpretation: interpretation
        )
    }

    private static func order(
        id: String,
        provider: LabProvider,
        status: String,
        statusLabel: String,
        completedSteps: Int,
        totalSteps: Int,
        labTest: LabOrder.Test,
        amountTotal: Int,
        paymentStatus: String = "paid",
        refundedAmount: Int? = nil,
        failureKind: String? = nil,
        tracking: LabOrder.Tracking? = nil,
        referralUrl: String? = nil,
        referrals: [LabOrder.Referral]? = nil,
        daysAgo days: Int
    ) -> LabOrder {
        LabOrder(
            id: id,
            provider: provider.rawValue,
            status: status,
            statusLabel: statusLabel,
            completedSteps: completedSteps,
            totalSteps: totalSteps,
            labTest: labTest,
            amountTotal: amountTotal,
            currency: provider == .eirly ? eirlyCurrency : currency,
            paymentStatus: paymentStatus,
            refundedAmount: refundedAmount,
            failureKind: failureKind,
            tracking: tracking,
            referralUrl: referralUrl,
            referrals: referrals,
            createdAt: (Calendar.autoupdatingCurrent.date(byAdding: .day, value: -days, to: .now) ?? .now).brightISOZoned
        )
    }
}

// MARK: - Structures used in data requests and responses

struct LabAvailability: Codable, Hashable {
    struct Provider: Codable, Hashable {
        let provider: String
        let available: Bool
        let message: String?
        let excludedStates: [String]?
    }

    let providers: [String: Provider]
}

struct JunctionLabTest: Codable, Hashable {
    struct Marker: Codable, Hashable {
        struct Result: Codable, Hashable {
            let name: String?
        }

        let name: String?
        let expectedResults: [Result]?

        enum CodingKeys: String, CodingKey {
            case name
            case expectedResults = "expected_results"
        }
    }

    let id: String
    let name: String
    let method: String?
    let sampleType: String?
    let price: Double?
    // The price to show: `price` stays null while Junction can't sell (the App Store build
    // offers any priced test); whether this app can order comes from labs/availability.
    let displayPrice: Double?
    let isActive: Bool?
    let fasting: Bool?
    let description: String?
    let markers: [Marker]?

    var shownPrice: Double? { displayPrice ?? price }

    var isOrderable: Bool {
        method == "testkit" && isActive != false && shownPrice != nil
    }

    enum CodingKeys: String, CodingKey {
        case id, name, method, price, displayPrice, fasting, description, markers
        case sampleType = "sample_type"
        case isActive = "is_active"
    }
}

struct JunctionLabTestList: Codable {
    let tests: [JunctionLabTest]

    private enum CodingKeys: String, CodingKey {
        case data
        case labTests = "lab_tests"
    }

    init(from decoder: Decoder) throws {
        if let tests = try? decoder.singleValueContainer().decode([JunctionLabTest].self) {
            self.tests = tests
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tests = try container.decodeIfPresent([JunctionLabTest].self, forKey: .data)
            ?? container.decodeIfPresent([JunctionLabTest].self, forKey: .labTests)
            ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(tests)
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

struct EirlyQuoteRequest: Codable {
    let tests: [String]
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
    let testIsForMe: Bool
}

struct LabPaymentConfigResponseData: Codable {
    let publishableKey: String
    let amount: Int
    let currency: String
    let productName: String
    let customerId: String?
    let ephemeralKeySecret: String?
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
    let testIsForMe: Bool
    let consents: [String]
    let consentsVersion: String
}

struct LabPaymentIntentResponseData: Codable {
    let clientSecret: String
    let paymentIntentId: String
    let labOrderId: String
}

struct LabOrderList: Codable {
    let orders: [LabOrder]
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
    let paymentStatus: String?
    let refundedAmount: Int?
    let failureKind: String?
    let tracking: Tracking?
    let referralUrl: String?
    let referrals: [Referral]?
    let createdAt: String?

    var isEirly: Bool { provider == "eirly" }
    var isPlaced: Bool { status != "awaiting_payment" && status != "placing" }
    var isReady: Bool { status == "ready" }
    var hasResults: Bool { status == "ready" || status == "partial_results" }
    var isRefunded: Bool { paymentStatus == "refunded" }
    var isFailed: Bool { status == "failed" || status == "cancelled" || isRefunded }

    // What the person is told about the order as a whole: a refund wins, then why placing stopped.
    var headline: (title: String, detail: String?) {
        if isRefunded { return ("Refunded", "Your refund usually reaches your card within 5–10 business days.") }
        switch status {
        case "failed" where failureKind == "unknown":
            return ("Checking with the lab", "Something went wrong placing your order. We're checking with the lab and will be in touch.")
        case "failed":
            return ("Order failed", "We couldn't place your order with the lab, so we're refunding you in full.")
        case "cancelled":
            return ("Order cancelled", "Get in touch if you have questions about this order.")
        default:
            return (statusLabel, nil)
        }
    }

    // The six the iOS receipt and Slack show; support finds the order by it.
    var reference: String { String(id.suffix(6)).uppercased() }

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

    // The kit's way out until it's delivered, then the return leg; none for a failed order.
    var trackingURL: URL? {
        guard !isFailed else { return nil }
        let returning = ["with_you", "returning", "at_lab"].contains(status)
        let first = returning ? tracking?.inboundTrackingUrl : tracking?.outboundTrackingUrl
        let second = returning ? tracking?.outboundTrackingUrl : tracking?.inboundTrackingUrl
        return (first ?? second).flatMap(URL.init(string:))
    }

    var totalText: String? {
        guard let amountTotal else { return nil }
        let code = (currency ?? "usd").uppercased()
        return (Decimal(amountTotal) / 100).formatted(.currency(code: code).locale(.bright))
    }
}

struct LabResultsPDF: Codable {
    let url: String
}

// GET junction/lab-orders/{id}/results: both providers in one shape. Older
// servers send only `results` / `missing_results`, which still decode.
struct LabResults: Codable {
    struct Biomarker: Codable, Hashable {
        let name: String
        let value: Double?
        let result: String?
        let unit: String?
        let referenceLow: Double?
        let referenceHigh: Double?
        let interpretation: String?

        var isOutOfRange: Bool {
            guard let value else { return false }
            return referenceHigh.map { value > $0 } == true || referenceLow.map { value < $0 } == true
        }

        var isFlagged: Bool {
            interpretation == "abnormal" || interpretation == "critical" || isOutOfRange
        }

        // The server sends "critical" only once the provider's doctor contacts the person.
        var needsPromptAttention: Bool { interpretation == "critical" }

        var valueText: String {
            [result ?? "–", unit].compactMap { $0 }.joined(separator: " ")
        }

        var rangeText: String? {
            switch (referenceLow, referenceHigh) {
            case let (low?, high?): "\(low.formatted())–\(high.formatted())"
            case let (nil, high?): "Under \(high.formatted())"
            case let (low?, nil): "Over \(low.formatted())"
            default: nil
            }
        }
    }

    struct Missing: Codable, Hashable {
        let name: String
        let reason: String?
    }

    let status: String?
    let markers: [Biomarker]
    let missing: [Missing]
    let pdfAvailable: Bool
    let criticalNotice: String?

    // Final results with failed markers aren't partial: nothing more is coming for those.
    var isPartial: Bool { status == "partial" }

    private enum CodingKeys: String, CodingKey {
        case status, markers, missing, pdfAvailable, criticalNotice, results
        case missingResults = "missing_results"
    }

    private struct LegacyBiomarker: Decodable {
        let name: String
        let value: Double?
        let result: String?
        let unit: String?
        let interpretation: String?
        let minRangeValue: Double?
        let maxRangeValue: Double?

        enum CodingKeys: String, CodingKey {
            case name, value, result, unit, interpretation
            case minRangeValue = "min_range_value"
            case maxRangeValue = "max_range_value"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        pdfAvailable = (try? container.decodeIfPresent(Bool.self, forKey: .pdfAvailable)) ?? false
        criticalNotice = try? container.decodeIfPresent(String.self, forKey: .criticalNotice)
        if let markers = try? container.decode([Biomarker].self, forKey: .markers) {
            self.markers = markers
        } else {
            let legacy = (try? container.decode([LegacyBiomarker].self, forKey: .results)) ?? []
            markers = legacy.map {
                Biomarker(
                    name: $0.name, value: $0.value, result: $0.result, unit: $0.unit,
                    referenceLow: $0.minRangeValue, referenceHigh: $0.maxRangeValue, interpretation: $0.interpretation
                )
            }
        }
        if let missing = try? container.decode([Missing].self, forKey: .missing) {
            self.missing = missing
        } else {
            let names = (try? container.decode([String].self, forKey: .missingResults)) ?? []
            missing = names.map { Missing(name: $0, reason: nil) }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encode(markers, forKey: .markers)
        try container.encode(missing, forKey: .missing)
        try container.encode(pdfAvailable, forKey: .pdfAvailable)
        try container.encodeIfPresent(criticalNotice, forKey: .criticalNotice)
    }
}

extension LabResults {
    init(status: String?, markers: [Biomarker], missing: [Missing], pdfAvailable: Bool, criticalNotice: String?) {
        self.status = status
        self.markers = markers
        self.missing = missing
        self.pdfAvailable = pdfAvailable
        self.criticalNotice = criticalNotice
    }
}
