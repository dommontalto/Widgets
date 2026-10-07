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
    let test: VaultClinicTest
    let clinic: VaultTestingClinic

    var firstName = ""
    var lastName = ""
    var email = ""
    var phone = ""
    var phoneCountry = BrightCountry.default
    var dateOfBirth = Constants.defaultDateOfBirth
    var sex: LabPatientSex?
    private(set) var formNudge = 0

    var showingCheckout = false
    var showingFormError = false
    var showingCheckoutError = false
    private(set) var errorMessage = ""
    private(set) var isPaying = false

    private let service: LabOrdersServiceProtocol
    private let onOrder: (VaultTestOrder) -> Void

    init(
        test: VaultClinicTest,
        clinic: VaultTestingClinic,
        // Optional because default arguments are evaluated off the main actor,
        // where the main-actor mock service can't be created.
        service: LabOrdersServiceProtocol? = nil,
        onOrder: @escaping (VaultTestOrder) -> Void
    ) {
        self.test = test
        self.clinic = clinic
        self.service = service ?? LabOrdersMockService()
        self.onOrder = onOrder

        phoneCountry = Self.country(for: provider)
    }

    private var provider: LabProvider {
        test.labProvider ?? .junction
    }

    var dateOfBirthRange: ClosedRange<Date> {
        Constants.oldestDateOfBirth...Constants.youngestDateOfBirth
    }

    var checkoutItem: BrightCheckoutItem {
        BrightCheckoutItem(
            title: test.name,
            subtitle: test.type.rawValue,
            systemImage: test.type.systemImage,
            detail: test.detail,
            priceText: Decimal(test.price).formatted(.currency(code: test.currency).locale(.bright)),
            currency: test.currency,
            fulfilment: provider == .junction ? .shipped : .delivered
        )
    }

    // MARK: - Patient details

    func handleContinue() {
        guard isFormComplete else {
            formNudge += 1
            return
        }
        showingCheckout = true
    }

    private var isFormComplete: Bool {
        ![firstName, lastName, phone].contains { trim($0).isEmpty } && sex != nil && trim(email).contains("@")
    }

    // MARK: - Checkout

    func handlePay(_ details: BrightCheckoutDetails) {
        guard !isPaying else { return }
        guard let address = details.address, address.countryCode == provider.countryCode else {
            showError(provider == .junction ? Constants.usOnlyError : Constants.auOnlyError)
            return
        }
        guard let labTestId = test.labTestId, let sex else { return }
        isPaying = true

        Task {
            defer { isPaying = false }
            do {
                let intent: LabPaymentIntentResponseData
                switch provider {
                case .junction:
                    intent = try await service.createPaymentIntent(
                        junctionRequest(labTestId: labTestId, address: address, sex: sex)
                    )
                case .eirly:
                    intent = try await service.createEirlyPaymentIntent(
                        eirlyRequest(labTestId: labTestId, address: address, sex: sex)
                    )
                }
                let number = String(intent.labOrderId.suffix(Constants.orderNumberLength)).uppercased()
                onOrder(VaultTestOrder(number: number, test: test, clinic: clinic, type: test.type, details: details))
            } catch {
                Log("Labs: demo order failed – \(error)")
                showError(Constants.genericError)
            }
        }
    }

    private var internationalPhone: String {
        let digits = phone.filter(\.isNumber)
        let local = digits.hasPrefix("0") ? String(digits.dropFirst()) : digits
        return phoneCountry.dialCode + local
    }

    private func junctionRequest(
        labTestId: String,
        address: BrightShippingAddress,
        sex: LabPatientSex
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
            savePaymentMethod: false
        )
    }

    private func eirlyRequest(
        labTestId: String,
        address: BrightShippingAddress,
        sex: LabPatientSex
    ) -> EirlyPaymentIntentRequest {
        EirlyPaymentIntentRequest(
            tests: [labTestId],
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
            savePaymentMethod: false
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
