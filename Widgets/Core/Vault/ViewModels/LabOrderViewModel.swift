//
//  LabOrderViewModel.swift
//  Widgets
//

import SwiftUI

enum LabPatientSex: String, CaseIterable, Identifiable {
    case female
    case male

    var id: String { rawValue }

    var title: String { rawValue.capitalized }
}

@MainActor
@Observable
final class LabOrderViewModel {
    let tests: [VaultClinicTest]
    let clinic: VaultTestingClinic

    var firstName = ""
    var lastName = ""
    var email = ""
    var phone = ""
    var phoneCountry = BrightCountry.default
    // Chosen by the person, never assumed.
    var dateOfBirth: Date?
    var sex: LabPatientSex?
    // The results go to this account's Vault, so the test must be for them.
    var isForMe = false
    var acceptedConsents = Set<String>()
    private(set) var formNudge = 0

    var showingCheckout = false
    var showingFormError = false
    var showingCheckoutError = false
    private(set) var errorMessage = ""
    private(set) var isPaying = false
    private(set) var isStartingCheckout = false
    // What checkout charges: Eirly's quote adds its fees and GST to the tests.
    private(set) var amountTotal: Double?

    private let service: LabOrdersServiceProtocol
    private let onOrder: (VaultTestOrder) -> Void

    init(
        tests: [VaultClinicTest],
        clinic: VaultTestingClinic,
        // Optional because default arguments are evaluated off the main actor,
        // where the main-actor mock service can't be created.
        service: LabOrdersServiceProtocol? = nil,
        onOrder: @escaping (VaultTestOrder) -> Void
    ) {
        self.tests = tests
        self.clinic = clinic
        self.service = service ?? LabOrdersMockService()
        self.onOrder = onOrder

        firstName = Constants.demoFirstName
        lastName = Constants.demoLastName
        email = Constants.demoEmail
        phoneCountry = Self.country(for: provider)
    }

    private var provider: LabProvider {
        tests.first?.labProvider ?? .junction
    }

    private var labTestIds: [String] {
        tests.compactMap(\.labTestId)
    }

    private var type: VaultTestAvailability {
        tests.first?.type ?? .atHomeKit
    }

    private var detail: String {
        tests.count == 1 ? tests[0].detail : tests.map(\.name).joined(separator: ", ")
    }

    private var title: String {
        tests.count == 1 ? tests[0].name : "\(tests.count) pathology tests"
    }

    private var price: Double {
        amountTotal ?? tests.reduce(0) { $0 + ($1.price ?? 0) }
    }

    private var currency: String {
        tests.first?.currency ?? "AUD"
    }

    var dateOfBirthRange: ClosedRange<Date> {
        Constants.oldestDateOfBirth...Constants.youngestDateOfBirth
    }

    var datePickerDate: Date {
        get { dateOfBirth ?? Constants.defaultDateOfBirth }
        set { dateOfBirth = newValue }
    }

    // Junction's patient consents; Eirly takes none.
    var consents: [LabConsent] {
        provider == .junction ? LabConsent.junction : []
    }

    func toggleConsent(_ consent: LabConsent) {
        if acceptedConsents.contains(consent.type) {
            acceptedConsents.remove(consent.type)
        } else {
            acceptedConsents.insert(consent.type)
        }
    }

    var checkoutItem: BrightCheckoutItem {
        BrightCheckoutItem(
            title: title,
            subtitle: type.rawValue,
            systemImage: type.systemImage,
            detail: detail,
            priceText: Decimal(price).formatted(.currency(code: currency).locale(.bright)),
            currency: currency,
            fulfilment: provider == .junction ? .shipped : .residence,
            countryCode: provider.countryCode
        )
    }

    // MARK: - Patient details

    func handleContinue() {
        guard !isStartingCheckout else { return }
        guard isFormComplete else {
            formNudge += 1
            return
        }
        isStartingCheckout = true

        Task {
            defer { isStartingCheckout = false }
            do {
                switch provider {
                case .junction:
                    try await Task.sleep(for: .seconds(Constants.demoConfigSeconds))
                    amountTotal = nil
                case .eirly:
                    let quote = try await service.getEirlyQuote(tests: labTestIds)
                    amountTotal = Double(quote.amountTotal) / 100
                }
                showingCheckout = true
            } catch {
                Log("Labs: demo checkout start failed – \(error)")
                showError(Constants.genericError)
            }
        }
    }

    private var isFormComplete: Bool {
        ![firstName, lastName, phone].contains { trim($0).isEmpty } && sex != nil && dateOfBirth != nil
            && trim(email).contains("@") && isForMe && consents.allSatisfy { acceptedConsents.contains($0.type) }
    }

    // MARK: - Checkout

    func handlePay(_ details: BrightCheckoutDetails) {
        guard !isPaying else { return }
        guard let address = details.address, address.countryCode == provider.countryCode else {
            showError(provider == .junction ? Constants.usOnlyError : Constants.auOnlyError)
            return
        }
        guard let labTestId = labTestIds.first, let sex, let dateOfBirth else { return }
        isPaying = true

        Task {
            defer { isPaying = false }
            do {
                let intent: LabPaymentIntentResponseData
                switch provider {
                case .junction:
                    intent = try await service.createPaymentIntent(
                        junctionRequest(labTestId: labTestId, address: address, sex: sex, dateOfBirth: dateOfBirth)
                    )
                case .eirly:
                    intent = try await service.createEirlyPaymentIntent(
                        eirlyRequest(address: address, sex: sex, dateOfBirth: dateOfBirth)
                    )
                }
                let number = String(intent.labOrderId.suffix(Constants.orderNumberLength)).uppercased()
                onOrder(
                    VaultTestOrder(
                        number: number,
                        test: purchasedTest,
                        clinic: clinic,
                        type: type,
                        details: details,
                        labOrderId: intent.labOrderId
                    )
                )
            } catch {
                Log("Labs: demo order failed – \(error)")
                showError(Constants.genericError)
            }
        }
    }

    private var purchasedTest: VaultClinicTest {
        VaultClinicTest(
            id: tests.map(\.id).joined(separator: "+"),
            name: title,
            detail: detail,
            categoryIds: tests.first?.categoryIds ?? [],
            included: tests.map(\.name),
            availability: [type],
            price: price,
            currency: currency,
            labProvider: provider
        )
    }

    private var internationalPhone: String {
        let digits = phone.filter(\.isNumber)
        let local = digits.hasPrefix("0") ? String(digits.dropFirst()) : digits
        return phoneCountry.dialCode + local
    }

    private func junctionRequest(
        labTestId: String,
        address: BrightShippingAddress,
        sex: LabPatientSex,
        dateOfBirth: Date
    ) -> LabPaymentIntentRequest {
        LabPaymentIntentRequest(
            labTestId: labTestId,
            patientDetails: LabPatientDetails(
                firstName: trim(firstName),
                lastName: trim(lastName),
                dob: dateOfBirth.brightDayKey,
                gender: sex.rawValue,
                phoneNumber: internationalPhone,
                email: trim(email)
            ),
            patientAddress: LabPatientAddress(
                firstLine: address.line1,
                secondLine: address.line2,
                city: address.city,
                state: trim(address.state ?? "").uppercased(),
                zip: trim(address.postalCode),
                country: provider.countryCode,
                receiverName: address.name
            ),
            savePaymentMethod: false,
            testIsForMe: isForMe,
            consents: consents.map(\.type).filter { acceptedConsents.contains($0) },
            consentsVersion: LabConsent.version
        )
    }

    private func eirlyRequest(
        address: BrightShippingAddress,
        sex: LabPatientSex,
        dateOfBirth: Date
    ) -> EirlyPaymentIntentRequest {
        EirlyPaymentIntentRequest(
            tests: labTestIds,
            patient: EirlyPatient(
                firstName: trim(firstName),
                lastName: trim(lastName),
                email: trim(email),
                dob: dateOfBirth.brightDayKey,
                gender: sex.rawValue,
                phone: internationalPhone
            ),
            address: EirlyAddress(
                addressLine1: address.line1,
                addressLine2: address.line2,
                city: address.city,
                state: trim(address.state ?? "").uppercased(),
                postCode: trim(address.postalCode)
            ),
            savePaymentMethod: false,
            testIsForMe: isForMe
        )
    }

    private func showError(_ message: String) {
        errorMessage = message
        if showingCheckout {
            showingCheckoutError = true
        } else {
            showingFormError = true
        }
    }

    private func trim(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func country(for provider: LabProvider) -> BrightCountry {
        BrightCountry.all.first { $0.code == provider.countryCode } ?? .default
    }

    private enum Constants {
        static let orderNumberLength = 6
        static let demoConfigSeconds = 0.6
        static let demoFirstName = "Alex"
        static let demoLastName = "Morgan"
        static let demoEmail = "alex@example.com"
        static let genericError = "Something went wrong. Please try again later."
        static let usOnlyError = "Junction kits ship to US addresses only. Choose or add a US address to continue."
        static let auOnlyError = "Eirly referrals are for Australian addresses only. Choose or add an Australian address to continue."

        static var defaultDateOfBirth: Date { years(ago: 30) }
        static var youngestDateOfBirth: Date { years(ago: 18) }
        static var oldestDateOfBirth: Date { years(ago: 110) }

        static func years(ago years: Int) -> Date {
            Calendar.autoupdatingCurrent.date(byAdding: .year, value: -years, to: .now) ?? .now
        }
    }
}

// Junction's patient consents, accepted before payment and sent with the order. The wording
// still needs sign-off.
struct LabConsent: Identifiable, Hashable {
    let type: String
    let title: String

    var id: String { type }

    static let version = "draft-2026-10-29"
    static let junction = [
        LabConsent(type: "hipaa-authorization", title: "HIPAA authorization"),
        LabConsent(type: "terms-of-use", title: "Lab partner terms of use"),
        LabConsent(type: "telehealth-informed-consent", title: "Telehealth review of my order"),
    ]
}
