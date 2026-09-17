//
//  LighthouseWaypointSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 16/9/2026.
//

import SwiftUI

// The waypoint Lighthouse is setting up, or an existing check-in being edited:
// how often it checks in, on what day and when, how long for, and anything
// extra to keep in mind.
struct LighthouseWaypointSheet: View {
    private let checkIn: LighthouseCheckIn?
    private let onConfirm: (LighthouseCheckIn) -> Void
    private let onSkip: () -> Void

    @State private var name: String
    @State private var frequency: LighthouseCheckInFrequency
    @State private var day: LighthouseWeekday
    @State private var dayOfMonth: Int
    @State private var time: Date
    @State private var focus: String
    @State private var endDate = EndDate.endOfProgram
    @State private var nameNudge = 0
    @FocusState private var isNamingFocus: Bool
    @Environment(\.dismiss) private var dismiss

    init(
        checkIn: LighthouseCheckIn? = nil,
        onConfirm: @escaping (LighthouseCheckIn) -> Void = { _ in },
        onSkip: @escaping () -> Void = {}
    ) {
        self.checkIn = checkIn
        self.onConfirm = onConfirm
        self.onSkip = onSkip
        _name = State(initialValue: checkIn?.title ?? Constants.defaultName)
        _frequency = State(initialValue: checkIn?.frequency ?? .weekly)
        _day = State(initialValue: checkIn?.weekday ?? .sunday)
        _dayOfMonth = State(initialValue: checkIn?.dayOfMonth ?? 1)
        _time = State(initialValue: checkIn?.time ?? Constants.defaultTime)
        _focus = State(initialValue: checkIn?.detail ?? "")
    }

    private var isEditing: Bool { checkIn != nil }

    var body: some View {
        BrightPageSheetView(
            trailing: {
                ToolbarItem(placement: .principal) {
                    title
                }

                if !isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(Constants.skipTitle) {
                            onSkip()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.defaultSkyBlue)
                    }
                }
            },
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: .spacing3x) {
                        nameField

                        scheduleCard

                        endDateCard

                        BrightText(Constants.focusTitle, size: .body1)
                            .padding(.horizontal, .spacing2x)

                        focusField
                    }
                    .padding(.top, .spacing2x)
                    .padding(.bottom, .spacing4x)
                }
                .safeAreaInset(edge: .bottom, spacing: .spacing0x) {
                    BrightPillButton(confirmTitle, systemImage: "checkmark", buttonSize: .large) {
                        confirm()
                    }
                    .padding(.bottom, .spacing2x)
                }
            }
        )
    }

    private var title: some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: "circle.dotted")
                .font(.standard(size: .body1, weight: .regular))
                .foregroundStyle(Color.textColor)

            BrightText(Constants.title, size: .body1, weight: .regular)
        }
    }

    private var confirmTitle: String {
        isEditing ? Constants.saveTitle : Constants.confirmTitle
    }

    private var nameField: some View {
        TextField(Constants.namePlaceholder, text: $name)
            .focused($isNamingFocus)
            .font(.standard(size: .heading, weight: .light))
            .foregroundStyle(Color.textColor)
            .brightWiggle(trigger: nameNudge)
            .padding(.horizontal, .spacing2x)
    }

    private var scheduleCard: some View {
        VStack(spacing: .spacing0x) {
            pickerRow(symbol: "gauge.with.needle", title: Constants.frequencyTitle, selection: $frequency, isLast: false)

            switch frequency {
            case .daily:
                EmptyView()
            case .weekly:
                pickerRow(symbol: "calendar", title: Constants.dayTitle, selection: $day, isLast: false)
            case .monthly:
                dayOfMonthRow
            }

            timeRow
        }
        .padding(.horizontal, .spacing3x)
        .padding(.vertical, .spacing1x)
        .modifier(CardModifier())
        .animation(.brightEaseInOut, value: frequency)
    }

    // Each choice sits in a small pill that opens a ticked menu of the rest.
    private func pickerRow<Option: PickerOption>(
        symbol: String,
        title: String,
        selection: Binding<Option>,
        isLast: Bool
    ) -> some View {
        VStack(spacing: .spacing0x) {
            HStack(spacing: .spacing2x) {
                rowLabel(symbol: symbol, title: title)

                Spacer(minLength: .spacing2x)

                Menu {
                    ForEach(Option.allCases) { option in
                        Button {
                            selection.wrappedValue = option
                        } label: {
                            Label {
                                Text(option.title)
                            } icon: {
                                if option == selection.wrappedValue {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    BrightPillButton(selection.wrappedValue.title, buttonSize: .small) {}
                        .allowsHitTesting(false)
                }
                .brightHaptic(.light, trigger: selection.wrappedValue)
            }
            .padding(.vertical, .spacing2x)

            if !isLast {
                BrightDivider()
            }
        }
    }

    private var dayOfMonthRow: some View {
        VStack(spacing: .spacing0x) {
            HStack(spacing: .spacing2x) {
                rowLabel(symbol: "calendar", title: Constants.dateTitle)

                Spacer(minLength: .spacing2x)

                Menu {
                    ForEach(Constants.daysOfMonth, id: \.self) { option in
                        Button {
                            dayOfMonth = option
                        } label: {
                            Label {
                                Text(option.ordinalSuffix())
                            } icon: {
                                if option == dayOfMonth {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    BrightPillButton(dayOfMonth.ordinalSuffix(), buttonSize: .small) {}
                        .allowsHitTesting(false)
                }
                .brightHaptic(.light, trigger: dayOfMonth)
            }
            .padding(.vertical, .spacing2x)

            BrightDivider()
        }
    }

    private var timeRow: some View {
        HStack(spacing: .spacing2x) {
            rowLabel(symbol: "clock", title: Constants.timeTitle)

            Spacer(minLength: .spacing2x)

            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(.textColor)
                .modifier(GlassEffect(shape: .capsule))
        }
        .padding(.vertical, .spacing2x)
    }

    private var endDateCard: some View {
        HStack(spacing: .spacing2x) {
            rowLabel(symbol: "smallcircle.filled.circle", title: Constants.endDateTitle)

            Spacer(minLength: .spacing2x)

            Menu {
                ForEach(EndDate.allCases) { option in
                    Button {
                        endDate = option
                    } label: {
                        Label {
                            Text(option.title)
                        } icon: {
                            if option == endDate {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: .spacing2x) {
                    BrightText(endDate.title, size: .body1, weight: .regular)

                    BrightRoundButton(systemImage: "chevron.up.chevron.down", size: .small) {}
                        .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
            }
            .brightHaptic(.light, trigger: endDate)
        }
        .padding(.horizontal, .spacing3x)
        .padding(.vertical, .spacing2x)
        .modifier(CardModifier())
    }

    private var focusField: some View {
        ZStack(alignment: .topLeading) {
            if focus.isEmpty {
                BrightText(Constants.focusPlaceholder, size: .body1, color: .lightTextColor)
                    .allowsHitTesting(false)
            }

            TextField("", text: $focus, axis: .vertical)
                .font(.standard(size: .body1, weight: .light))
                .foregroundStyle(Color.textColor)
                .lineLimit(Constants.focusLines, reservesSpace: true)
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    private func rowLabel(symbol: String, title: String) -> some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: symbol)
                .font(.standard(size: .body1, weight: .light))
                .foregroundStyle(Color.semiLightTextColor)
                .frame(width: Constants.glyphWidth)

            BrightText(title, size: .body1, color: .semiLightTextColor)
        }
    }

    private func confirm() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            nameNudge += 1
            isNamingFocus = true
            return
        }

        if var updated = checkIn {
            updated.title = trimmed
            updated.frequency = frequency
            updated.weekday = day
            updated.dayOfMonth = dayOfMonth
            updated.time = time
            updated.detail = focus
            onConfirm(updated)
        } else {
            onConfirm(
                LighthouseCheckIn(
                    title: trimmed,
                    frequency: frequency,
                    weekday: day,
                    dayOfMonth: dayOfMonth,
                    time: time,
                    detail: focus,
                    isOn: true
                )
            )
        }

        dismiss()
    }

    private enum EndDate: PickerOption {
        case endOfProgram
        case oneMonth
        case threeMonths
        case never

        var title: String {
            switch self {
            case .endOfProgram: "End of Program"
            case .oneMonth: "In a month"
            case .threeMonths: "In 3 months"
            case .never: "Never"
            }
        }
    }

    private enum Constants {
        static let title = "Waypoint"
        static let defaultName = "Weekly Climbing Check In"
        static let namePlaceholder = "Check-in name"
        static let skipTitle = "Skip"
        static let confirmTitle = "Confirm"
        static let saveTitle = "Save"
        static let frequencyTitle = "Frequency"
        static let dayTitle = "Check-in day"
        static let dateTitle = "Check-in date"
        static let timeTitle = "Time"
        static let endDateTitle = "End Date"
        static let focusTitle = "Focus"
        static let focusPlaceholder = "Add extra context to your waypoint check in."
        static let focusLines = 4
        static let glyphWidth: CGFloat = .spacing4x
        static let daysOfMonth = Array(1 ... 28)
        static let defaultTime = Calendar.autoupdatingCurrent.date(bySettingHour: 18, minute: 0, second: 0, of: .now) ?? .now
    }
}

private protocol PickerOption: CaseIterable, Identifiable, Hashable where AllCases: RandomAccessCollection {
    var title: String { get }
}

private extension PickerOption {
    var id: Self { self }
}

extension LighthouseCheckInFrequency: PickerOption {}

extension LighthouseWeekday: PickerOption {}

#Preview {
    LighthouseWaypointSheet()
}
