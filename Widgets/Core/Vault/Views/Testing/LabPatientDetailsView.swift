//
//  LabPatientDetailsView.swift
//  Widgets
//

import SwiftUI

struct LabPatientDetailsView: View {
    @State private var viewModel: LabOrderViewModel

    init(test: VaultClinicTest, clinic: VaultTestingClinic, onOrder: @escaping (VaultTestOrder) -> Void) {
        _viewModel = State(initialValue: LabOrderViewModel(test: test, clinic: clinic, onOrder: onOrder))
    }

    var body: some View {
        BrightPageViewV5(
            title: Constants.title,
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultSheetBackground
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing2x) {
                    BrightText(Constants.subtitle, size: .body1, color: .lightTextColor)
                        .lineSpacing(.lineSpacingMedium)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, .spacing2x)

                    BrightTextFieldV5(
                        Constants.firstNamePlaceholder,
                        editingText: $viewModel.firstName,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )

                    BrightTextFieldV5(
                        Constants.lastNamePlaceholder,
                        editingText: $viewModel.lastName,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .words
                    )

                    dateOfBirthField

                    sexField

                    BrightTextFieldV5(
                        Constants.emailPlaceholder,
                        editingText: $viewModel.email,
                        keyboardType: .emailAddress,
                        backgroundColor: .defaultSheetModalCards,
                        textInputAutocapitalization: .never,
                        disableAutocorrection: true
                    )
                    .padding(.top, .spacing2x)

                    BrightPhoneFieldV5(
                        placeholder: Constants.phonePlaceholder,
                        number: $viewModel.phone,
                        country: $viewModel.phoneCountry
                    )
                }
                .brightWiggleV5(trigger: viewModel.formNudge)
                .padding(.horizontal, .spacing3x)
                .padding(.bottom, .spacing12x)
            }
            .scrollIndicators(.hidden)
        }
        .brightBottomButtonV5 {
            BrightPillButton(
                Constants.continueTitle,
                systemImage: "arrow.right",
                buttonSize: .large,
                onTapCallback: viewModel.handleContinue
            )
        }
        .navigationDestination(isPresented: $viewModel.showingCheckout) {
            LabCheckoutView(viewModel: viewModel)
        }
        .alert(Constants.errorTitle, isPresented: $viewModel.showingFormError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // The date reads as plain text; the compact picker sits invisibly on top
    // of it so a tap still opens the calendar.
    private var dateOfBirthField: some View {
        BrightRowV5(Constants.dateOfBirthTitle, color: .defaultSheetModalCards, trailing: {
            BrightText(viewModel.dateOfBirth.formatted(.brightSlashDate), size: .body1)
                .frame(maxHeight: .infinity)
                .overlay {
                    DatePicker(
                        Constants.dateOfBirthTitle,
                        selection: $viewModel.dateOfBirth,
                        in: viewModel.dateOfBirthRange,
                        displayedComponents: .date
                    )
                    .tint(.textColor)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, .bright)
                    .blendMode(.destinationOver)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
        })
    }

    private var sexField: some View {
        BrightRowGroupV5(header: Constants.sexPlaceholder, color: .defaultSheetModalCards) {
            ForEach(LabPatientSex.allCases) { option in
                BrightRowV5(option.title, trailing: .tick(viewModel.sex == option)) {
                    viewModel.sex = option
                }
            }
        }
    }

    private enum Constants {
        static let title = "Patient Details"
        static let subtitle = "The lab needs these to process your sample. They go on the order with your kit and stay private."
        static let firstNamePlaceholder = "First name"
        static let lastNamePlaceholder = "Last name"
        static let dateOfBirthTitle = "Date of birth"
        static let sexPlaceholder = "Sex at birth"
        static let emailPlaceholder = "Email"
        static let phonePlaceholder = "Phone"
        static let continueTitle = "Continue"
        static let errorTitle = "Lab test"
    }
}
