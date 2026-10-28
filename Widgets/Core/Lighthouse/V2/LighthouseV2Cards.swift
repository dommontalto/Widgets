//
//  LighthouseV2Cards.swift
//  Widgets
//
//

import SwiftUI

// What a card body says, per `card_type`, decoded from the block's JSON. Every field is
// optional: a card shows what the server sent, and a body this version can't read falls
// back to the placeholder rather than failing the reply.
enum LighthouseV2CardBody {
    case food(Food)
    case water(Water)
    case weight(Weight)
    case activity(Activity)
    case undo(Undo)
    case program(Program)
    case checkIn(CheckIn)
    case document(Document)
    case waypoint(Waypoint)
    case adjustment(Adjustment)
    case memory(Memory)
    case unknown(String)

    init(_ card: LighthouseV2Block.Card) {
        let body = card.body
        let decoded: LighthouseV2CardBody? = switch card.cardType {
        case "food_log": body.decode(Food.self).map(Self.food)
        case "water_log": body.decode(Water.self).map(Self.water)
        case "weight_log": body.decode(Weight.self).map(Self.weight)
        case "activity_log": body.decode(Activity.self).map(Self.activity)
        case "undo": body.decode(Undo.self).map(Self.undo)
        case "program": body.decode(Program.self).map(Self.program)
        case "checkin": body.decode(CheckIn.self).map(Self.checkIn)
        case "document": body.decode(Document.self).map(Self.document)
        case "waypoint": body.decode(Waypoint.self).map(Self.waypoint)
        case "adjustment": body.decode(Adjustment.self).map(Self.adjustment)
        case "memory": body.decode(Memory.self).map(Self.memory)
        default: nil
        }
        self = decoded ?? .unknown(card.cardType)
    }

    struct Nutrition: Decodable, Equatable {
        let energyKcal: Double?
        let proteinG: Double?
        let carbsG: Double?
        let fatG: Double?
        let includesEstimates: Bool?

        private enum CodingKeys: String, CodingKey {
            case energyKcal = "energy_kcal"
            case proteinG = "protein_g"
            case carbsG = "carbs_g"
            case fatG = "fat_g"
            case includesEstimates = "includes_estimates"
        }
    }

    struct Food: Decodable, Equatable {
        let mealType: String?
        let eatenAt: String?
        let eatenAtLabel: String?
        let timezoneFallback: Bool?
        let items: [Item]
        let totals: Nutrition?

        private enum CodingKeys: String, CodingKey {
            case items, totals
            case mealType = "meal_type"
            case eatenAt = "eaten_at"
            case eatenAtLabel = "eaten_at_label"
            case timezoneFallback = "timezone_fallback"
        }

        struct Item: Decodable, Equatable {
            let name: String
            let description: String?
            let quantity: Double?
            let unit: String?
            let grams: Double?
            let portionSource: String?
            let source: String?
            let match: Match?
            let nutrition: Nutrition?
            // FD1: numbers that failed the plausibility check twice; the engine never logs this item.
            let needsChecking: NeedsChecking?

            struct NeedsChecking: Decodable, Equatable {
                let reason: String?
            }

            private enum CodingKeys: String, CodingKey {
                case name, description, quantity, unit, grams, source, match, nutrition
                case portionSource = "portion_source"
                case needsChecking = "needs_checking"
            }

            // "estimated portion" or an estimate's own source; a database match with its weighed portion isn't.
            var isEstimate: Bool {
                source != "food_db" || portionSource?.localizedCaseInsensitiveContains("estimat") == true
            }
        }

        struct Match: Decodable, Equatable {
            let title: String?
        }
    }

    struct Water: Decodable, Equatable {
        let ml: Double
        let estimated: Bool?
        let at: String?
        let atLabel: String?
        let timezoneFallback: Bool?

        private enum CodingKeys: String, CodingKey {
            case ml, estimated, at
            case atLabel = "at_label"
            case timezoneFallback = "timezone_fallback"
        }
    }

    struct Weight: Decodable, Equatable {
        let kg: Double
        let entered: Entered?
        let at: String?
        let atLabel: String?
        let existing: Bool?

        private enum CodingKeys: String, CodingKey {
            case kg, entered, at, existing
            case atLabel = "at_label"
        }

        struct Entered: Decodable, Equatable {
            let value: Double?
            let unit: String?
        }
    }

    // LG2's manual activity (`tools/log_activity.py`).
    struct Activity: Decodable, Equatable {
        let title: String?
        let intensity: String?
        let intensityAssumed: Bool?
        let minutes: Double?
        let energyKcal: Double?
        let kcalNote: String?
        let at: String?
        let atLabel: String?

        private enum CodingKeys: String, CodingKey {
            case title, intensity, start, kcal
            case intensityAssumed = "intensity_assumed"
            case durationMin = "duration_min"
            case kcalNote = "kcal_note"
            case startLabel = "start_label"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            title = try c.decodeIfPresent(String.self, forKey: .title)
            intensity = try c.decodeIfPresent(String.self, forKey: .intensity)
            intensityAssumed = try c.decodeIfPresent(Bool.self, forKey: .intensityAssumed)
            minutes = try c.decodeIfPresent(Double.self, forKey: .durationMin)
            energyKcal = try c.decodeIfPresent(Double.self, forKey: .kcal)
            kcalNote = try c.decodeIfPresent(String.self, forKey: .kcalNote)
            at = try c.decodeIfPresent(String.self, forKey: .start)
            atLabel = try c.decodeIfPresent(String.self, forKey: .startLabel)
        }
    }

    struct Undo: Decodable, Equatable {
        let entries: [Entry]
        let until: String?

        struct Entry: Decodable, Equatable {
            let kind: String?
            let label: String?
        }
    }

    struct Program: Decodable, Equatable {
        let plan: Plan?
        let startDate: String?
        let replaces: Replaces?
        let rationale: String?

        private enum CodingKeys: String, CodingKey {
            case plan, replaces, rationale
            case startDate = "start_date"
        }

        struct Plan: Decodable, Equatable {
            let name: String?
            let periods: [Period]?
        }

        struct Period: Decodable, Equatable {
            let name: String?
            let blocks: [Block]?
        }

        struct Block: Decodable, Equatable {
            let name: String?
            let kind: String?
            let weeks: Int?
            let days: [Day]?
        }

        struct Day: Decodable, Equatable {
            let day: String
            let sessions: [Session]?
        }

        struct Session: Decodable, Equatable {
            let title: String?
            let kind: String?
            let line: String?
        }

        struct Replaces: Decodable, Equatable {
            let name: String?
        }

        var weeks: Int {
            (plan?.periods ?? []).flatMap { $0.blocks ?? [] }.compactMap(\.weeks).reduce(0, +)
        }

        var sessionsPerWeek: Int {
            plan?.periods?.first?.blocks?.first?.days?.reduce(0) { $0 + ($1.sessions?.count ?? 0) } ?? 0
        }
    }

    struct CheckIn: Decodable, Equatable {
        let title: String?
        let topicText: String?
        let schedule: Schedule?
        let nextRunText: String?
        let review: String?

        private enum CodingKeys: String, CodingKey {
            case title, schedule, review
            case topicText = "topic_text"
            case nextRunText = "next_run_text"
        }

        struct Schedule: Decodable, Equatable {
            let text: String?
        }
    }

    struct Document: Decodable, Equatable {
        let labName: String?
        let collectedAt: String?
        let summary: String?
        let markers: [Marker]
        let omitted: Int?

        private enum CodingKeys: String, CodingKey {
            case summary, markers, omitted
            case labName = "lab_name"
            case collectedAt = "collected_at"
        }

        struct Marker: Decodable, Equatable {
            let name: String
            let rawValue: String?
            let value: Double?
            let unit: String?
            let referenceText: String?
            let status: String?

            private enum CodingKeys: String, CodingKey {
                case name, value, unit, status
                case rawValue = "raw_value"
                case referenceText = "reference_text"
            }
        }
    }

    // WP1a's waypoint; read leniently until its card is served.
    // WP1a's create_waypoint card (`Draft.body()` plus its texts).
    struct Waypoint: Decodable, Equatable {
        let title: String?
        let metricLabel: String?
        let direction: String?
        let baseline: Amount?
        let target: Amount?
        let startDate: String?
        let targetDate: String?
        let targetDateText: String?
        // daily or weekly; `frequencyText` says when ("Every Monday at 8:00 am").
        let frequency: String?
        let frequencyText: String?
        // A target the server finds implausible, when it says so.
        let plausibility: Plausibility?

        var warning: String? { plausibility?.text }

        private enum CodingKeys: String, CodingKey {
            case title, direction, baseline, target, frequency, plausibility
            case metricLabel = "metric_label"
            case startDate = "start_date"
            case targetDate = "target_date"
            case targetDateText = "target_date_text"
            case frequencyText = "frequency_text"
        }

        struct Amount: Decodable, Equatable {
            let value: Double?
            let unit: String?
        }

        struct Plausibility: Decodable, Equatable {
            let text: String?
        }
    }

    // WP1b's adjustment card: a waypoint_target change (with an action) or a suggestion (without).
    struct Adjustment: Decodable, Equatable {
        let title: String?
        let waypointTitle: String?
        let current: JSONValue?
        let proposed: JSONValue?
        let unit: String?
        let change: String?
        let reason: String?
        let note: String?
        let state: String?
        let evidence: [LighthouseV2Adjustment.Evidence]?

        private enum CodingKeys: String, CodingKey {
            case title, current, proposed, unit, change, reason, note, state, evidence
            case waypointTitle = "waypoint_title"
        }
    }

    struct Memory: Decodable, Equatable {
        let text: String?
        let dismissLabel: String?

        private enum CodingKeys: String, CodingKey {
            case text, summary, content, title
            case dismissLabel = "dismiss_label"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            text = try c.decodeIfPresent(String.self, forKey: .text)
                ?? c.decodeIfPresent(String.self, forKey: .summary)
                ?? c.decodeIfPresent(String.self, forKey: .content)
                ?? c.decodeIfPresent(String.self, forKey: .title)
            dismissLabel = try c.decodeIfPresent(String.self, forKey: .dismissLabel)
        }
    }
}

extension LighthouseV2CardBody {
    // The server's own word for turning a card down ("Dismiss" on a memory), when it sends one.
    var cancelLabel: String? {
        if case let .memory(memory) = self { memory.dismissLabel } else { nil }
    }
}

// Where a card's action stands. Kept per card, so a reopened thread shows what was decided.
enum LighthouseV2CardState: Equatable {
    case pending
    case working
    // The server's confirmation message.
    case done(String)
    case cancelled(String)
    case failed(String)
    // The server's reason, such as an undo past its 24 hours or a file that has gone.
    case expired(String?)

    var isDecided: Bool {
        switch self {
        case .done, .cancelled, .expired: true
        default: false
        }
    }
}

// A `card` block: its fields in the existing card style, then its action.
struct LighthouseV2CardView: View {
    let card: LighthouseV2Block.Card
    let state: LighthouseV2CardState
    let onDecide: (LighthouseV2Block.Card.Action, LighthouseV2Decision) -> Void

    var body: some View {
        let body = LighthouseV2CardBody(card)
        if case .unknown = body {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: .spacing2x) {
                content(body)

                if let action = card.actions?.first {
                    BrightDividerV5()
                    actionRow(action, cancellable: card.cardType != "undo", cancelLabel: body.cancelLabel ?? Constants.cancel)
                }
            }
            .padding(.spacing3x)
            .modifier(BrightCardModifierV5())
            // `.contain` keeps the buttons' and status's own identifiers under the card's.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("lighthouse.v2.card.\(card.cardType)")
        }
    }

    @ViewBuilder
    private func content(_ body: LighthouseV2CardBody) -> some View {
        switch body {
        case let .food(food): LighthouseV2FoodCard(food: food)
        case let .water(water):
            LighthouseV2CardHeader(symbol: "drop.fill", tint: .defaultSkyBlue, title: Constants.water)
            LighthouseV2CardRow(label: Constants.amount, value: Self.ml(water.ml) + (water.estimated == true ? " · \(Constants.estimate)" : ""))
            LighthouseV2CardRow(label: Constants.time, value: Self.when(water.atLabel, water.at), isLast: true)
        case let .weight(weight):
            LighthouseV2CardHeader(symbol: "scalemass.fill", tint: .defaultGreen, title: Constants.weight)
            LighthouseV2CardRow(label: Constants.weight, value: Self.entered(weight))
            LighthouseV2CardRow(label: Constants.time, value: Self.when(weight.atLabel, weight.at), isLast: weight.existing != true)
            if weight.existing == true {
                BrightText(Constants.existingWeight, size: .body4, color: .lightTextColor)
            }
        case let .activity(activity):
            LighthouseV2CardHeader(symbol: "figure.run", tint: .defaultOrange, title: activity.title?.capitalizedFirstLetter() ?? Constants.activity)
            if let minutes = activity.minutes {
                LighthouseV2CardRow(label: Constants.duration, value: "\(Int(minutes.rounded())) min")
            }
            if let intensity = activity.intensity {
                LighthouseV2CardRow(label: Constants.intensity, value: intensity.capitalizedFirstLetter() + (activity.intensityAssumed == true ? " · \(Constants.assumed)" : ""))
            }
            if let kcal = activity.energyKcal {
                LighthouseV2CardRow(label: Constants.energy, value: "\(Int(kcal.rounded())) kcal")
            }
            LighthouseV2CardRow(label: Constants.time, value: Self.when(activity.atLabel, activity.at), isLast: true)
            if let note = activity.kcalNote {
                BrightText(note, size: .body4, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case let .undo(undo):
            LighthouseV2CardHeader(symbol: "arrow.uturn.backward", tint: .lightTextColor, title: Constants.undo)
            BrightText(undo.entries.compactMap(\.label).joined(separator: ", ").capitalizedFirstLetter(), size: .body2, color: .semiLightTextColor)
            if let until = undo.until.flatMap({ Date(lighthouseISO: $0) }) {
                BrightText("\(Constants.undoUntil) \(until.formatted(.brightTimestamp))", size: .body4, color: .lightTextColor)
            }
        case let .program(program): LighthouseV2ProgramCard(program: program)
        case let .checkIn(checkIn):
            LighthouseV2CardHeader(symbol: "person.badge.clock.fill", tint: .defaultSkyBlue, title: checkIn.title ?? Constants.checkIn)
            if let schedule = checkIn.schedule?.text {
                LighthouseV2CardRow(label: Constants.schedule, value: schedule)
            }
            if let topic = checkIn.topicText {
                LighthouseV2CardRow(label: Constants.topic, value: topic.capitalizedFirstLetter())
            }
            if let next = checkIn.nextRunText {
                LighthouseV2CardRow(label: Constants.nextRun, value: next, isLast: true)
            }
            if let review = checkIn.review {
                BrightText(review, size: .body4, color: .lightTextColor)
            }
        case let .document(document): LighthouseV2DocumentCard(document: document)
        case let .waypoint(waypoint):
            LighthouseV2CardHeader(symbol: "location.north.circle.fill", tint: .defaultGreen, title: waypoint.title ?? Constants.waypoint)
            if let baseline = waypoint.baseline?.value {
                LighthouseV2CardRow(label: Constants.now, value: Self.amount(baseline, waypoint.baseline?.unit))
            }
            if let target = waypoint.target?.value {
                LighthouseV2CardRow(label: Constants.target, value: Self.amount(target, waypoint.target?.unit))
            }
            if let metric = waypoint.metricLabel {
                LighthouseV2CardRow(label: Constants.metric, value: metric.capitalizedFirstLetter())
            }
            if let start = waypoint.startDate.flatMap({ Date(brightDayKey: $0) }) {
                LighthouseV2CardRow(label: Constants.starts, value: start.formatted(.brightDate))
            }
            if let date = waypoint.targetDateText ?? waypoint.targetDate.flatMap({ Date(brightDayKey: $0) })?.formatted(.brightDate) {
                LighthouseV2CardRow(label: Constants.by, value: date)
            }
            if let checkIn = waypoint.frequencyText ?? waypoint.frequency.map({ $0.capitalizedFirstLetter() }) {
                LighthouseV2CardRow(label: Constants.checkIn, value: checkIn, isLast: true)
            }
            if let warning = waypoint.warning {
                LighthouseV2CardStatus(symbol: "exclamationmark.triangle", tint: .defaultOrange, text: warning)
            }
        case let .adjustment(adjustment):
            LighthouseV2CardHeader(symbol: "slider.horizontal.3", tint: .defaultYellow, title: adjustment.title ?? Constants.adjustment)
            if let waypoint = adjustment.waypointTitle {
                LighthouseV2CardRow(label: Constants.waypoint, value: waypoint)
            }
            if let current = adjustment.current?.displayText, let proposed = adjustment.proposed?.displayText {
                LighthouseV2CardRow(label: Constants.change, value: "\(current) → \(proposed)\(adjustment.unit.map { " \($0)" } ?? "")")
            } else if let note = adjustment.note {
                BrightText(note, size: .body3, color: .semiLightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let reason = adjustment.reason {
                BrightText(reason, size: .body3, color: .semiLightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Array((adjustment.evidence?.first?.rows ?? []).prefix(4).enumerated()), id: \.offset) { _, row in
                LighthouseV2EvidenceRow(row: row)
            }
        case let .memory(memory):
            LighthouseV2CardHeader(symbol: "brain", tint: .lightTextColor, title: Constants.memory)
            if let text = memory.text {
                BrightText(text, size: .body2, color: .semiLightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .unknown:
            EmptyView()
        }
    }

    @ViewBuilder
    private func actionRow(_ action: LighthouseV2Block.Card.Action, cancellable: Bool, cancelLabel: String) -> some View {
        switch state {
        case .pending, .failed:
            VStack(alignment: .leading, spacing: .spacing1x) {
                HStack(spacing: .spacing1x) {
                    BrightPillButton(action.label, buttonSize: .small) { onDecide(action, .confirm) }
                        .accessibilityIdentifier("lighthouse.v2.card.confirm")
                    if cancellable {
                        BrightPillButton(cancelLabel, textColor: .lightTextColor, buttonSize: .small) { onDecide(action, .cancel) }
                            .accessibilityIdentifier("lighthouse.v2.card.cancel")
                    }
                    Spacer(minLength: .spacing0x)
                }
                if case let .failed(reason) = state {
                    LighthouseV2CardStatus(symbol: "exclamationmark.triangle", tint: .defaultOrange, text: reason)
                }
            }
        case .working:
            HStack(spacing: .spacing1x) {
                ProgressView()
                BrightText(Constants.working, size: .body3, color: .lightTextColor)
            }
        case let .done(message):
            LighthouseV2CardStatus(symbol: "checkmark.circle.fill", tint: .defaultGreen, text: message)
        case let .cancelled(message):
            LighthouseV2CardStatus(symbol: "xmark.circle", tint: .lightTextColor, text: message)
        case let .expired(message):
            LighthouseV2CardStatus(symbol: "clock.badge.xmark", tint: .lightTextColor, text: message ?? Constants.expired)
        }
    }

    static func ml(_ value: Double) -> String {
        value >= 1000 ? "\((value / 1000).formatted(.number.precision(.fractionLength(0 ... 2)))) L" : "\(Int(value.rounded())) ml"
    }

    static func amount(_ value: Double, _ unit: String?) -> String {
        [value.formatted(.number.precision(.fractionLength(0 ... 1))), unit].compactMap { $0 }.joined(separator: " ")
    }

    static func entered(_ weight: LighthouseV2CardBody.Weight) -> String {
        let kg = amount(weight.kg, "kg")
        guard let value = weight.entered?.value, let unit = weight.entered?.unit, unit != "kg" else { return kg }
        return "\(amount(value, unit)) (\(kg))"
    }

    // The server's own words for when ("breakfast at 8 am Sun 11 Oct"), else the timestamp; "now" for a log at the time of asking.
    static func when(_ label: String?, _ at: String?) -> String {
        if let label, !label.isEmpty { return ["now", "just now"].contains(label) ? Constants.nowLabel : label.capitalizedFirstLetter() }
        return at.flatMap { Date(lighthouseISO: $0) }?.formatted(.brightTimestamp) ?? Constants.nowLabel
    }

    private enum Constants {
        static let water = "Water"
        static let weight = "Weight"
        static let activity = "Activity"
        static let undo = "Undo"
        static let checkIn = "Check-in"
        static let waypoint = "Waypoint"
        static let adjustment = "Adjustment"
        static let memory = "Memory"
        static let amount = "Amount"
        static let time = "Time"
        static let duration = "Duration"
        static let energy = "Energy"
        static let intensity = "Intensity"
        static let assumed = "assumed"
        static let schedule = "Schedule"
        static let topic = "Topic"
        static let nextRun = "First check-in"
        static let now = "Now"
        static let target = "Target"
        static let by = "By"
        static let change = "Change"
        static let metric = "Goal"
        static let starts = "Starts"
        static let estimate = "estimated"
        static let nowLabel = "Now"
        static let undoUntil = "Can be undone until"
        static let existingWeight = "There's already a weight at that time, so confirming keeps that one."
        static let cancel = "Cancel"
        static let working = "Working on it…"
        static let expired = "This card has expired. Ask again for a fresh one."
    }
}

struct LighthouseV2CardHeader: View {
    let symbol: String
    let tint: Color
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing105x) {
            Image(systemName: symbol)
                .font(.standard(size: .body1, weight: .regular))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: .spacing025x) {
                BrightText(title, size: .body1, weight: .regular)
                if let subtitle {
                    BrightText(subtitle, size: .body4, color: .lightTextColor)
                }
            }
            Spacer(minLength: .spacing0x)
        }
    }
}

struct LighthouseV2CardRow: View {
    let label: String
    let value: String
    var isLast = false

    var body: some View {
        VStack(spacing: .spacing1x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing2x) {
                BrightText(label, size: .body3, color: .lightTextColor)
                Spacer(minLength: .spacing1x)
                BrightText(value, size: .body3)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
            }
            if !isLast {
                BrightDividerV5()
            }
        }
    }
}

struct LighthouseV2CardStatus: View {
    let symbol: String
    let tint: Color
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
            Image(systemName: symbol)
                .font(.standard(size: .body3, weight: .regular))
                .foregroundStyle(tint)
            BrightText(text, size: .body3, color: .semiLightTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("lighthouse.v2.card.status")
    }
}

// MARK: - Food

struct LighthouseV2FoodCard: View {
    let food: LighthouseV2CardBody.Food

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            LighthouseV2CardHeader(
                symbol: "fork.knife",
                tint: .defaultOrange,
                title: food.mealType?.capitalizedFirstLetter() ?? Constants.meal,
                subtitle: LighthouseV2CardView.when(food.eatenAtLabel, food.eatenAt)
            )

            VStack(spacing: .spacing1x) {
                ForEach(Array(food.items.enumerated()), id: \.offset) { index, item in
                    row(item, isLast: index == food.items.count - 1)
                }
            }

            if let totals = food.totals {
                HStack(spacing: .spacing2x) {
                    BrightText(Constants.total, size: .body3, weight: .regular)
                    Spacer(minLength: .spacing1x)
                    BrightText(Self.macros(totals), size: .body3)
                        .monospacedDigit()
                }
                if totals.includesEstimates == true {
                    BrightText(Constants.includesEstimates, size: .body4, color: .lightTextColor)
                }
            }
        }
    }

    private func row(_ item: LighthouseV2CardBody.Food.Item, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing2x) {
                BrightText(item.name.capitalizedFirstLetter(), size: .body2, color: item.needsChecking == nil ? .textColor : .lightTextColor)
                if item.needsChecking != nil {
                    BrightText(Constants.needsChecking, size: .body5, color: .defaultOrange)
                } else if item.isEstimate {
                    BrightText(Constants.estimate, size: .body5, color: .defaultYellow)
                }
                Spacer(minLength: .spacing1x)
                if let kcal = item.nutrition?.energyKcal {
                    BrightText("\(Int(kcal.rounded())) kcal", size: .body3, color: item.needsChecking == nil ? .textColor : .lightTextColor)
                        .monospacedDigit()
                        .strikethrough(item.needsChecking != nil)
                }
            }
            BrightText(Self.portion(item), size: .body4, color: .lightTextColor)
            if let check = item.needsChecking {
                LighthouseV2CardStatus(
                    symbol: "exclamationmark.triangle",
                    tint: .defaultOrange,
                    text: [check.reason?.capitalizedFirstLetter(), Constants.notLogged].compactMap { $0 }.joined(separator: ". ")
                )
            }
            if !isLast {
                BrightDividerV5()
                    .padding(.top, .spacing05x)
            }
        }
    }

    static func portion(_ item: LighthouseV2CardBody.Food.Item) -> String {
        let grams = item.grams.map { "\(Int($0.rounded())) g" }
        return [item.description ?? item.match?.title, grams].compactMap { $0 }.joined(separator: " · ")
    }

    static func macros(_ n: LighthouseV2CardBody.Nutrition) -> String {
        let kcal = n.energyKcal.map { "\(Int($0.rounded())) kcal" }
        let parts = [("P", n.proteinG), ("C", n.carbsG), ("F", n.fatG)].compactMap { name, value in
            value.map { "\(name) \(Int($0.rounded()))g" }
        }
        return ([kcal].compactMap { $0 } + parts).joined(separator: " · ")
    }

    private enum Constants {
        static let meal = "Meal"
        static let total = "Total"
        static let estimate = "Estimate"
        static let needsChecking = "Needs checking"
        static let notLogged = "Won't be logged"
        static let includesEstimates = "Includes estimated portions."
    }
}

// MARK: - Program

struct LighthouseV2ProgramCard: View {
    let program: LighthouseV2CardBody.Program

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            LighthouseV2CardHeader(
                symbol: "figure.strengthtraining.traditional",
                tint: .defaultGreen,
                title: program.plan?.name ?? Constants.program,
                subtitle: summary
            )

            if let start = program.startDate.flatMap({ Date(brightDayKey: $0) }) {
                LighthouseV2CardRow(label: Constants.starts, value: start.formatted(.brightDate), isLast: program.replaces?.name == nil)
            }
            if let replaced = program.replaces?.name {
                LighthouseV2CardRow(label: Constants.replaces, value: replaced, isLast: true)
                    .accessibilityIdentifier("lighthouse.v2.card.program.replaces")
            }
        }
    }

    private var summary: String? {
        let parts = [program.weeks > 0 ? "\(program.weeks) weeks" : nil,
                     program.sessionsPerWeek > 0 ? "\(program.sessionsPerWeek) sessions a week" : nil]
        let text = parts.compactMap { $0 }.joined(separator: " · ")
        return text.isEmpty ? nil : text
    }

    private enum Constants {
        static let program = "Program"
        static let starts = "Starts"
        static let replaces = "Replaces"
    }
}

// MARK: - Document

struct LighthouseV2DocumentCard: View {
    let document: LighthouseV2CardBody.Document

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            LighthouseV2CardHeader(
                symbol: "doc.text.magnifyingglass",
                tint: .defaultSkyBlue,
                title: document.labName ?? Constants.labReport,
                subtitle: document.collectedAt.flatMap { Date(brightDayKey: $0) }?.formatted(.brightDate)
            )

            if let summary = document.summary {
                BrightText(summary, size: .body3, color: .semiLightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: .spacing1x) {
                ForEach(Array(document.markers.enumerated()), id: \.offset) { index, marker in
                    markerRow(marker, isLast: index == document.markers.count - 1)
                }
            }

            if let omitted = document.omitted, omitted > 0 {
                BrightText("\(omitted) \(omitted == 1 ? "value" : "values") couldn't be read.", size: .body4, color: .lightTextColor)
            }
        }
    }

    private func markerRow(_ marker: LighthouseV2CardBody.Document.Marker, isLast: Bool) -> some View {
        VStack(spacing: .spacing1x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                Image(systemName: "circle.fill")
                    .font(.standard(size: .body6, weight: .regular))
                    .foregroundStyle(LighthouseV2Status(marker.status).tint)
                VStack(alignment: .leading, spacing: .spacing025x) {
                    BrightText(marker.name, size: .body3)
                    if let range = marker.referenceText {
                        BrightText(range, size: .body5, color: .lightTextColor)
                    }
                }
                Spacer(minLength: .spacing1x)
                BrightText([marker.rawValue ?? marker.value.map { "\($0)" }, marker.unit].compactMap { $0 }.joined(separator: " "), size: .body3)
                    .monospacedDigit()
            }
            if !isLast {
                BrightDividerV5()
            }
        }
    }

    private enum Constants {
        static let labReport = "Lab report"
    }
}

// on_track / watch / attention, the server's three statuses.
struct LighthouseV2Status {
    let raw: String?

    init(_ raw: String?) {
        self.raw = raw
    }

    var tint: Color {
        switch raw {
        case "on_track": .defaultGreen
        case "watch": .defaultYellow
        case "attention": .defaultOrange
        default: .lightTextColor
        }
    }

    var symbol: String {
        switch raw {
        case "on_track": "checkmark.circle.fill"
        case "watch": "exclamationmark.circle.fill"
        case "attention": "exclamationmark.triangle.fill"
        default: "circle"
        }
    }
}

extension JSONValue {
    var displayText: String? {
        switch self {
        case let .int(value): String(value)
        case let .double(value): value.formatted(.number.precision(.fractionLength(0 ... 1)))
        case let .string(value): value
        case let .bool(value): value ? "On" : "Off"
        default: nil
        }
    }
}

// One evidence row on an adjustment card: what was measured, its value, and a status dot.
struct LighthouseV2EvidenceRow: View {
    let row: LighthouseV2Adjustment.Evidence.Row

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
            Circle()
                .fill(color)
                .frame(width: .spacing1x, height: .spacing1x)
            BrightText(row.marker ?? "", size: .body3, color: .lightTextColor)
            Spacer(minLength: .spacing1x)
            BrightText([row.value, row.tag].compactMap { $0 }.joined(separator: " "), size: .body3)
                .monospacedDigit()
        }
    }

    private var color: Color {
        switch row.status {
        case "on_track": .defaultGreen
        case "watch": .defaultOrange
        case "attention": .defaultRed
        default: .lightTextColor
        }
    }
}
