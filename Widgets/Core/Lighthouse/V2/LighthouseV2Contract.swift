//
//  LighthouseV2Contract.swift
//  Widgets
//
//

import Foundation

// The Lighthouse v2 contract (`docs/lighthouse/contract.md` and `contract.schema.json` in
// health). Keys are spelled out rather than converted from snake case, because the
// conversion would also rewrite dictionary keys such as claim ids and data categories.
// The server adds types and fields without bumping the contract, so anything unknown
// decodes to `.unknown` and is skipped, and every field the schema doesn't require is
// optional.

enum LighthouseV2Coding {
    static func decoder() -> JSONDecoder {
        JSONDecoder()
    }

    static func encoder() -> JSONEncoder {
        JSONEncoder()
    }
}

// MARK: - Events

enum LighthouseV2Event: Equatable, Sendable {
    case turnStarted(LighthouseV2TurnStarted)
    case stepStarted(LighthouseV2Step)
    case stepFinished(LighthouseV2Step)
    case blockDelta(LighthouseV2BlockDelta)
    case block(LighthouseV2Block)
    // A text block's whole text so far, replacing what its deltas built (FX3).
    case blockReplace(LighthouseV2BlockDelta)
    case turnCompleted(LighthouseV2TurnCompleted)
    case turnError(LighthouseV2TurnError)
    case unknown(String)

    var isTerminal: Bool {
        switch self {
        case .turnCompleted, .turnError: true
        default: false
        }
    }

    // `event` is the SSE event name; the payload's own `type` repeats it.
    static func make(event: String, data: Data) throws -> Self {
        let decoder = LighthouseV2Coding.decoder()
        let name = event == "message" ? (try? decoder.decode(TypeOnly.self, from: data).type) ?? event : event
        switch name {
        case "turn.started": return try .turnStarted(decoder.decode(LighthouseV2TurnStarted.self, from: data))
        case "step.started": return try .stepStarted(decoder.decode(LighthouseV2Step.self, from: data))
        case "step.finished": return try .stepFinished(decoder.decode(LighthouseV2Step.self, from: data))
        case "block.delta": return try .blockDelta(decoder.decode(LighthouseV2BlockDelta.self, from: data))
        case "block": return try .block(decoder.decode(BlockEnvelope.self, from: data).block)
        case "block.replace": return try .blockReplace(decoder.decode(LighthouseV2BlockDelta.self, from: data))
        case "turn.completed": return try .turnCompleted(decoder.decode(LighthouseV2TurnCompleted.self, from: data))
        case "turn.error": return try .turnError(decoder.decode(LighthouseV2TurnError.self, from: data))
        default: return .unknown(name)
        }
    }

    private struct TypeOnly: Decodable {
        let type: String
    }

    private struct BlockEnvelope: Decodable {
        let block: LighthouseV2Block
    }
}

struct LighthouseV2TurnStarted: Decodable, Equatable, Sendable {
    let contract: Int?
    let turnID: String
    let threadID: String?
    let model: String?

    private enum CodingKeys: String, CodingKey {
        case contract
        case turnID = "turn_id"
        case threadID = "thread_id"
        case model
    }
}

struct LighthouseV2Step: Decodable, Equatable, Sendable {
    let stepID: String
    // gate, context, tool, compose or validate; kept open for kinds added later.
    let kind: String
    let label: String
    let tool: String?
    let ms: Int?
    // A plain summary of a tool's result, never a health value. `sources[]` is always
    // empty until a retrieval source exists, so it isn't read.
    let detail: String?

    private enum CodingKeys: String, CodingKey {
        case stepID = "step_id"
        case kind, label, tool, ms, detail
    }
}

struct LighthouseV2BlockDelta: Decodable, Equatable, Sendable {
    let blockID: String
    let text: String

    private enum CodingKeys: String, CodingKey {
        case blockID = "block_id"
        case text
    }
}

struct LighthouseV2Usage: Decodable, Equatable, Sendable {
    let inputTokens: Int?
    let outputTokens: Int?
    let cacheReadTokens: Int?
    let cacheWriteTokens: Int?
    let costUnits: Double?

    private enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheReadTokens = "cache_read_tokens"
        case cacheWriteTokens = "cache_write_tokens"
        case costUnits = "cost_units"
    }
}

struct LighthouseV2TurnCompleted: Decodable, Equatable, Sendable {
    let messageID: String?
    let title: String?
    let usage: LighthouseV2Usage?
    // Not sent yet; the model that actually answered, once a fallback can differ.
    let model: String?

    private enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case title, usage, model
    }
}

struct LighthouseV2TurnError: Decodable, Equatable, Sendable {
    let code: String
    let message: String
    let retryable: Bool
}

// MARK: - Blocks

enum LighthouseV2Block: Decodable, Equatable, Identifiable, Sendable {
    case text(Text)
    case choices(Choices)
    case suggestions(Suggestions)
    case chart(Chart)
    case card(Card)
    case notice(Notice)
    case unknown(id: String, type: String)

    var id: String {
        switch self {
        case let .text(block): block.id
        case let .choices(block): block.id
        case let .suggestions(block): block.id
        case let .chart(block): block.id
        case let .card(block): block.id
        case let .notice(block): block.id
        case let .unknown(id, _): id
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type, id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        // A block this version can't read, known type or not, becomes a placeholder; it never fails the reply.
        do {
            switch type {
            case "text": self = try .text(Text(from: decoder))
            case "choices": self = try .choices(Choices(from: decoder))
            case "suggestions": self = try .suggestions(Suggestions(from: decoder))
            case "chart": self = try .chart(Chart(from: decoder))
            case "card": self = try .card(Card(from: decoder))
            case "notice": self = try .notice(Notice(from: decoder))
            default: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "unknown block")
            }
        } catch {
            let id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
            self = .unknown(id: id, type: type)
        }
    }

    struct Text: Decodable, Equatable, Sendable {
        let id: String
        var text: String
        var claims: [String]?
        // "general" for the knowledge tool's text, which isn't the user's data.
        let source: String?

        var isGeneralKnowledge: Bool { source == "general" }
    }

    struct Choices: Decodable, Equatable, Sendable {
        let id: String
        let prompt: String
        let options: [String]
        let mode: String?
        let submitLabel: String?

        var allowsMultiple: Bool { mode == "multi" }

        private enum CodingKeys: String, CodingKey {
            case id, prompt, options, mode
            case submitLabel = "submit_label"
        }
    }

    struct Suggestions: Decodable, Equatable, Sendable {
        let id: String
        let items: [String]
    }

    // CH1's chart: one of the Health tab's V5 widgets, drawn from the server's own figures and range.
    struct Chart: Decodable, Equatable, Sendable {
        let id: String
        let chart: Int
        let kind: String
        var tileKind: String?
        let style: String
        let size: String
        let range: Range
        let unit: String?
        let headline: Figure?
        let data: ChartData
        let claims: [String]
        let source: Source
        let tap: Tap
        let a11y: String

        private enum CodingKeys: String, CodingKey {
            case id, chart, kind, style, size, range, unit, headline, data, claims, source, tap, a11y
            case tileKind = "tile_kind"
        }

        struct Range: Decodable, Equatable, Sendable {
            let type: String
            let start: String
            let end: String
            let tz: String
            let label: String
            let inProgress: Bool

            private enum CodingKeys: String, CodingKey {
                case type, start, end, tz, label
                case inProgress = "in_progress"
            }
        }

        struct Figure: Decodable, Equatable, Sendable {
            let value: Double
            let unit: String?
            let claim: String?
        }

        struct Source: Decodable, Equatable, Sendable {
            let metric: String
            let asOf: String

            private enum CodingKeys: String, CodingKey {
                case metric
                case asOf = "as_of"
            }
        }

        struct Tap: Decodable, Equatable, Sendable {
            let kind: String
        }
    }

    enum ChartData: Decodable, Equatable, Sendable {
        case bar(Bars)
        case line(Line)
        case dottedLine(DottedLine)
        case sleep(Sleep)
        case dottedRange(DottedRange)
        case ring(Rings)
        case water(Water)
        case menstrual(Menstrual)
        case comparison(Comparison)

        private enum CodingKeys: String, CodingKey {
            case family
        }

        init(from decoder: Decoder) throws {
            let family = try decoder.container(keyedBy: CodingKeys.self).decode(String.self, forKey: .family)
            switch family {
            case "bar": self = try .bar(Bars(from: decoder))
            case "line": self = try .line(Line(from: decoder))
            case "dottedLine": self = try .dottedLine(DottedLine(from: decoder))
            case "sleep": self = try .sleep(Sleep(from: decoder))
            case "dottedRange": self = try .dottedRange(DottedRange(from: decoder))
            case "ring": self = try .ring(Rings(from: decoder))
            case "water": self = try .water(Water(from: decoder))
            case "menstrual": self = try .menstrual(Menstrual(from: decoder))
            case "comparison": self = try .comparison(Comparison(from: decoder))
            default: throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "unknown chart family \(family)"))
            }
        }

        struct Bars: Decodable, Equatable, Sendable {
            let slot: String
            let slotCount: Int
            let bars: [Bar]
            let headline: String
            let split: [Split]

            struct Bar: Decodable, Equatable, Sendable {
                let index: Int
                let start: String
                let value: Double?
                let segments: [Segment]
            }

            struct Segment: Decodable, Equatable, Sendable {
                let key: String
                let value: Double
            }

            struct Split: Decodable, Equatable, Sendable {
                let key: String
                let figure: Chart.Figure
            }

            private enum CodingKeys: String, CodingKey {
                case slot, bars, headline, split
                case slotCount = "slot_count"
            }
        }

        struct Line: Decodable, Equatable, Sendable {
            let bucketS: Int
            let samples: [Sample]
            let stats: Stats

            struct Sample: Decodable, Equatable, Sendable {
                let t: String
                let v: Double
            }

            struct Stats: Decodable, Equatable, Sendable {
                let min: Chart.Figure
                let max: Chart.Figure
                let mean: Chart.Figure
            }

            private enum CodingKeys: String, CodingKey {
                case samples, stats
                case bucketS = "bucket_s"
            }
        }

        struct DottedLine: Decodable, Equatable, Sendable {
            let points: [Point]
            let latest: Chart.Figure
            let change: Change?
            let perWeek: Change?
            let showTrendLine: Bool

            struct Point: Decodable, Equatable, Sendable {
                let date: String
                let value: Double
            }

            struct Change: Decodable, Equatable, Sendable {
                let direction: String
                let figure: Chart.Figure
            }

            private enum CodingKeys: String, CodingKey {
                case points, latest, change
                case perWeek = "per_week"
                case showTrendLine = "show_trend_line"
            }
        }

        struct Sleep: Decodable, Equatable, Sendable {
            let segments: [Segment]
            let asleep: Chart.Figure
            let inBed: Chart.Figure?
            let score: Chart.Figure?
            let restingHR: Chart.Figure?
            let hrv: Chart.Figure?

            struct Segment: Decodable, Equatable, Sendable {
                let stage: String
                let start: String
                let end: String
            }

            private enum CodingKeys: String, CodingKey {
                case segments, asleep, score, hrv
                case inBed = "in_bed"
                case restingHR = "resting_hr"
            }
        }

        // CH2: each night vital against its normal band; wrist temperature is a signed deviation.
        struct DottedRange: Decodable, Equatable, Sendable {
            let measures: [Measure]

            struct Measure: Decodable, Equatable, Sendable {
                let key: String
                let value: Chart.Figure
                let band: Band
                let low: Double?
                let high: Double?
                let signed: Bool
            }

            struct Band: Decodable, Equatable, Sendable {
                let low: Double
                let high: Double
            }
        }

        // CH2: each ring's value against its goal.
        struct Rings: Decodable, Equatable, Sendable {
            let rings: [Ring]
            let goalSource: String?

            struct Ring: Decodable, Equatable, Sendable {
                let key: String
                let value: Chart.Figure
                let goal: Chart.Figure
            }

            private enum CodingKeys: String, CodingKey {
                case rings
                case goalSource = "goal_source"
            }
        }

        // CH2: the day's drinks, oldest first, with the server's total.
        struct Water: Decodable, Equatable, Sendable {
            let drinks: [Drink]
            let total: Chart.Figure
            let goal: Chart.Figure?

            struct Drink: Decodable, Equatable, Sendable {
                let t: String
                let ml: Double
            }
        }

        // CH2: where today falls in the projected cycle.
        struct Menstrual: Decodable, Equatable, Sendable {
            let cycleStart: String
            let length: Chart.Figure
            let periodLength: Int
            let fertileWindow: [Int]
            let ovulationDay: Int
            let lutealStart: Int
            let today: Chart.Figure
            let nextPeriod: String
            let daysUntil: Chart.Figure

            private enum CodingKeys: String, CodingKey {
                case length, today
                case cycleStart = "cycle_start"
                case periodLength = "period_length"
                case fertileWindow = "fertile_window"
                case ovulationDay = "ovulation_day"
                case lutealStart = "luteal_start"
                case nextPeriod = "next_period"
                case daysUntil = "days_until"
            }
        }

        // CH2: the person against a population (Atlas or Bright's ranking); any figure may be missing.
        struct Comparison: Decodable, Equatable, Sendable {
            let metric: String
            let cohort: String?
            let people: Chart.Figure?
            let median: Chart.Figure?
            let middleLow: Chart.Figure?
            let middleHigh: Chart.Figure?
            let lowest: Chart.Figure?
            let highest: Chart.Figure?
            let you: Chart.Figure?
            let percentile: Chart.Figure?
            let source: String
            let sourceText: String

            private enum CodingKeys: String, CodingKey {
                case metric, cohort, people, median, lowest, highest, you, percentile, source
                case middleLow = "middle_low"
                case middleHigh = "middle_high"
                case sourceText = "source_text"
            }
        }
    }

    struct Card: Decodable, Equatable, Sendable {
        let id: String
        let cardType: String
        let body: JSONValue
        let actions: [Action]?
        let claims: [String]?

        private enum CodingKeys: String, CodingKey {
            case id
            case cardType = "card_type"
            case body, actions, claims
        }

        struct Action: Decodable, Equatable, Sendable {
            let id: String
            let label: String
            let style: String?
        }
    }

    struct Notice: Decodable, Equatable, Sendable {
        let id: String
        // refusal, disclosure, reframe, data_access, fallback, error or usage_limit.
        let kind: String
        let text: String
        let nextStep: NextStep?
        let nextSteps: [NextStep]?
        // usage_limit: when the weekly allowance starts again.
        let resetsAt: String?

        private enum CodingKeys: String, CodingKey {
            case id, kind, text
            case nextStep = "next_step"
            case nextSteps = "next_steps"
            case resetsAt = "resets_at"
        }

        init(id: String, kind: String, text: String, nextStep: NextStep? = nil, nextSteps: [NextStep]? = nil, resetsAt: String? = nil) {
            self.id = id
            self.kind = kind
            self.text = text
            self.nextStep = nextStep
            self.nextSteps = nextSteps
            self.resetsAt = resetsAt
        }

        var isUsageLimit: Bool { kind == "usage_limit" }

        // Every step, for an "ask first" notice's Allow once / Always allow pair.
        var steps: [NextStep] {
            allSteps.filter { !$0.opensGenomeSettings }
        }

        // There's no genome opt-in screen yet, so a notice that only points at it is dropped.
        var onlyOpensGenomeSettings: Bool {
            !allSteps.isEmpty && steps.isEmpty
        }

        private var allSteps: [NextStep] {
            if let nextSteps, !nextSteps.isEmpty { return nextSteps }
            return nextStep.map { [$0] } ?? []
        }
    }

    struct NextStep: Decodable, Equatable, Sendable {
        let label: String
        let prompt: String?
        let url: String?
        // allow_once or always_allow, with the data category they apply to.
        let action: String?
        let category: String?

        init(label: String, prompt: String? = nil, url: String? = nil, action: String? = nil, category: String? = nil) {
            self.label = label
            self.prompt = prompt
            self.url = url
            self.action = action
            self.category = category
        }

        var opensSettings: Bool { url?.lowercased().hasSuffix("lighthouse/settings") == true }
        var opensGenomeSettings: Bool { url?.lowercased().hasSuffix("genome/settings") == true }
    }
}

// MARK: - Claims

struct LighthouseV2Claim: Decodable, Equatable, Identifiable, Sendable {
    let id: String
    let value: Value
    let unit: String?
    let label: String
    // user, cohort, population or general.
    let population: String
    let category: String?
    let window: String?
    let windowRange: WindowRange?
    let nDays: Int?
    let source: String

    private enum CodingKeys: String, CodingKey {
        case id, value, unit, label, population, category, window, source
        case windowRange = "window_range"
        case nDays = "n_days"
    }

    enum Value: Decodable, Equatable, Sendable {
        case number(Double)
        case text(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let number = try? container.decode(Double.self) {
                self = .number(number)
            } else {
                self = try .text(container.decode(String.self))
            }
        }

        var display: String {
            switch self {
            case let .number(number):
                number.formatted(.number.precision(.fractionLength(0 ... 1)))
            case let .text(text):
                text
            }
        }
    }

    struct WindowRange: Decodable, Equatable, Sendable {
        let start: String
        let end: String
        let tz: String
    }

    var displayValue: String {
        guard let unit, !unit.isEmpty else { return value.display }
        return "\(value.display) \(unit)"
    }
}

// MARK: - REST

struct LighthouseV2Thread: Decodable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String?
    let createdAt: String?
    let lastActiveAt: String?
    let pinned: Bool?
    let whisper: Bool?
    let expiresAt: String?
    let model: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, pinned, whisper, model
        case createdAt = "created_at"
        case lastActiveAt = "last_active_at"
        case expiresAt = "expires_at"
    }
}

struct LighthouseV2ThreadList: Decodable, Equatable, Sendable {
    let threads: [LighthouseV2Thread]
    let nextCursor: String?

    private enum CodingKeys: String, CodingKey {
        case threads
        case nextCursor = "next_cursor"
    }
}

// A stored message as `GET /threads/{id}` returns it. Not the schema's `Message`, which
// names its id `message_id` and has none of the REST fields.
struct LighthouseV2Message: Decodable, Equatable, Identifiable, Sendable {
    let id: String
    let role: String
    let blocks: [LighthouseV2Block]
    let claims: [String: LighthouseV2Claim]?
    let replyTo: String?
    let attachments: [String]?
    let createdAt: String?
    let expiresAt: String?
    let feedback: LighthouseV2Feedback?
    // "stopped" for a turn that was stopped; a confirmation message is "complete".
    let status: String?

    private enum CodingKeys: String, CodingKey {
        case id, role, blocks, claims, attachments, feedback, status
        case replyTo = "reply_to"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }

    var isUser: Bool { role == "user" }

    var plainText: String {
        blocks.compactMap { block in
            if case let .text(text) = block { text.text } else { nil }
        }
        .joined(separator: "\n\n")
    }
}

struct LighthouseV2ThreadDetail: Decodable, Equatable, Sendable {
    let id: String
    let title: String?
    let whisper: Bool?
    let model: String?
    let messages: [LighthouseV2Message]
}

struct LighthouseV2ModelCatalogue: Decodable, Equatable, Sendable {
    let version: Int?
    let defaultModel: String?
    let providers: [Provider]

    private enum CodingKeys: String, CodingKey {
        case version, providers
        case defaultModel = "default_model"
    }

    struct Provider: Decodable, Equatable, Sendable {
        let id: String
        let label: String?
        let models: [Model]
    }

    struct Model: Decodable, Equatable, Sendable {
        let id: String
        let tier: String?
        let name: String
        let label: String?
        let offeredForChat: Bool?

        private enum CodingKeys: String, CodingKey {
            case id, tier, name, label
            case offeredForChat = "offered_for_chat"
        }
    }

    func models(forProvider id: String) -> [Model] {
        providers.first { $0.id == id }?.models.filter { $0.offeredForChat ?? true } ?? []
    }

    func contains(modelID: String) -> Bool {
        providers.contains { $0.models.contains { $0.id == modelID } }
    }

    var defaultProvider: String? {
        providers.first { $0.models.contains { $0.id == defaultModel } }?.id
    }
}

struct LighthouseV2TurnRequest: Encodable, Equatable, Sendable {
    let message: String
    var attachments: [String] = []
    var model: String?
    var replyTo: String?
    var allowOnce: [String]?
    // The block types this app draws beyond the core ones; the server sends a chart only to a client listing it.
    var client = Client()

    struct Client: Encodable, Equatable, Sendable {
        var blocks = ["chart"]
    }

    private enum CodingKeys: String, CodingKey {
        case message, attachments, model, client
        case replyTo = "reply_to"
        case allowOnce = "allow_once"
    }
}

struct LighthouseV2CreateThread: Encodable, Equatable, Sendable {
    var whisper: Bool?
    var model: String?
}

struct LighthouseV2ThreadChange: Encodable, Equatable, Sendable {
    var title: String?
    var pinned: Bool?
}

// The delete and reset routes answer with counts the app doesn't show.
struct LighthouseV2Done: Decodable, Equatable, Sendable {
    init(from decoder: Decoder) throws {}
}

// MARK: - Actions

// `POST /actions/{id}`: what a confirmed or cancelled card did. A repeat confirm returns the first result.
struct LighthouseV2ActionResult: Decodable, Equatable, Sendable {
    let actionID: String
    let status: String
    let tool: String?
    let result: JSONValue?
    // The confirmation message appended to the thread, replying to the card.
    let messageID: String?
    let expiresAt: String?
    // A whisper card's confirmation (and Undo card), which no thread holds.
    let blocks: [LighthouseV2Block]?

    private enum CodingKeys: String, CodingKey {
        case actionID = "action_id"
        case status, tool, result, blocks
        case messageID = "message_id"
        case expiresAt = "expires_at"
    }

    var isCancelled: Bool { status == "cancelled" }
}

enum LighthouseV2Decision: String, Encodable, Sendable {
    case confirm
    case cancel
}

struct LighthouseV2DecisionBody: Encodable, Equatable, Sendable {
    let decision: String
}

// MARK: - Attachments

struct LighthouseV2Attachment: Decodable, Equatable, Sendable {
    let attachmentID: String
    let contentType: String?
    let size: Int?
    let pages: Int?

    private enum CodingKeys: String, CodingKey {
        case attachmentID = "attachment_id"
        case contentType = "content_type"
        case size, pages
    }
}

// MARK: - Check-ins

struct LighthouseV2CheckIn: Decodable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let topic: Topic?
    let schedule: Schedule
    let enabled: Bool
    let nextRunAt: String?
    let lastRunAt: String?
    let lastThreadID: String?
    let lastStatus: String?
    let failures: Int?
    let disabledReason: String?
    // A waypoint's check-in: when it ends (its target date), its waypoint, and daily or weekly.
    let endsAt: String?
    let waypointID: String?
    let frequency: String?

    private enum CodingKeys: String, CodingKey {
        case id = "checkin_id"
        case title, topic, schedule, enabled, failures
        case nextRunAt = "next_run_at"
        case lastRunAt = "last_run_at"
        case lastThreadID = "last_thread_id"
        case lastStatus = "last_status"
        case disabledReason = "disabled_reason"
        case endsAt = "ends_at"
        case waypointID = "waypoint_id"
        case frequency
    }

    struct Topic: Codable, Equatable, Sendable {
        let categories: [String]?
        let focus: String?
    }

    struct Schedule: Decodable, Equatable, Sendable {
        // daily, weekly (weekday 0 = Monday) or monthly (day 1-31).
        let kind: String
        let weekday: Int?
        let day: Int?
        let time: String
        let timezone: String?
        let text: String?
    }
}

struct LighthouseV2CheckInList: Decodable, Equatable, Sendable {
    let checkins: [LighthouseV2CheckIn]
}

// The create body, and the edit body with only what changed; nils are left out.
struct LighthouseV2CheckInChange: Encodable, Equatable, Sendable {
    var title: String?
    var categories: [String]?
    var focus: String?
    var kind: String?
    var weekday: Int?
    var day: Int?
    var time: String?
    var timezone: String?
    var enabled: Bool?
    var endsAt: String?
    // Sends `"ends_at": null`, which the engine reads as "runs until switched off"; a missing key keeps the old date.
    var clearsEndsAt = false

    private enum CodingKeys: String, CodingKey {
        case title, categories, focus, kind, weekday, day, time, timezone, enabled
        case endsAt = "ends_at"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(categories, forKey: .categories)
        try container.encodeIfPresent(focus, forKey: .focus)
        try container.encodeIfPresent(kind, forKey: .kind)
        try container.encodeIfPresent(weekday, forKey: .weekday)
        try container.encodeIfPresent(day, forKey: .day)
        try container.encodeIfPresent(time, forKey: .time)
        try container.encodeIfPresent(timezone, forKey: .timezone)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        if clearsEndsAt {
            try container.encodeNil(forKey: .endsAt)
        } else {
            try container.encodeIfPresent(endsAt, forKey: .endsAt)
        }
    }
}

// `POST /turns` (WH1): a whisper turn has no thread; it carries the chat so far and the server keeps none of it.
struct LighthouseV2WhisperTurnRequest: Encodable, Equatable, Sendable {
    let whisper = true
    let message: String
    let history: [Entry]
    var model: String?
    var allowOnce: [String]?
    var client = LighthouseV2TurnRequest.Client()

    struct Entry: Encodable, Equatable, Sendable {
        let role: String
        let text: String
    }

    static let maxHistory = 20
    static let maxHistoryCharacters = 12_000

    init(_ turn: LighthouseV2TurnRequest, history: [Entry]) {
        message = turn.message
        model = turn.model
        allowOnce = turn.allowOnce
        client = turn.client
        self.history = Self.trimmed(history)
    }

    // The newest messages that fit: at most 20, at most 12,000 characters in all.
    static func trimmed(_ history: [Entry]) -> [Entry] {
        var kept: [Entry] = []
        var characters = 0
        for entry in history.reversed().prefix(maxHistory) {
            characters += entry.text.count
            guard characters <= maxHistoryCharacters else { break }
            kept.insert(entry, at: 0)
        }
        return kept
    }

    private enum CodingKeys: String, CodingKey {
        case whisper, message, history, model, client
        case allowOnce = "allow_once"
    }
}

// MARK: - Settings

struct LighthouseV2Settings: Decodable, Equatable, Sendable {
    var defaultWhisper: Bool
    var dataAccess: [String: Access]
    var model: String?
    // MO1: fast | adaptive | thinking, the app's speed menu.
    var mode: String?
    // Bright's key answers when the person's own key fails.
    var byokFallback: Bool
    let usage: Usage?
    // Sent once, by the read that moved a model no longer offered back to the default.
    let notice: Notice?

    struct Notice: Decodable, Equatable, Sendable {
        let kind: String?
        let text: String
    }

    private enum CodingKeys: String, CodingKey {
        case model, mode, usage, notice
        case defaultWhisper = "default_whisper"
        case dataAccess = "data_access"
        case byokFallback = "byok_fallback"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultWhisper = try container.decodeIfPresent(Bool.self, forKey: .defaultWhisper) ?? false
        byokFallback = (try? container.decodeIfPresent(Bool.self, forKey: .byokFallback)) ?? false
        dataAccess = try container.decodeIfPresent([String: Access].self, forKey: .dataAccess) ?? [:]
        model = try container.decodeIfPresent(String.self, forKey: .model)
        mode = try? container.decodeIfPresent(String.self, forKey: .mode)
        usage = try? container.decodeIfPresent(Usage.self, forKey: .usage)
        notice = try? container.decodeIfPresent(Notice.self, forKey: .notice)
    }

    struct Access: Codable, Equatable, Sendable {
        var enabled: Bool
        var needsPrompt: Bool

        private enum CodingKeys: String, CodingKey {
            case enabled
            case needsPrompt = "needs_prompt"
        }

        init(enabled: Bool, needsPrompt: Bool) {
            self.enabled = enabled
            self.needsPrompt = needsPrompt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
            needsPrompt = try container.decodeIfPresent(Bool.self, forKey: .needsPrompt) ?? false
        }

        static let off = Access(enabled: false, needsPrompt: false)
        static let on = Access(enabled: true, needsPrompt: false)
        static let ask = Access(enabled: true, needsPrompt: true)
    }

    struct Usage: Decodable, Equatable, Sendable {
        let used: Double
        let limit: Double?
        let resetsAt: String?
        let plan: String?
        // This week's estimated cost on the person's own keys; never counts toward `limit`.
        let byokUsed: Double?

        private enum CodingKeys: String, CodingKey {
            case used, limit, plan
            case byokUsed = "byok_used"
            case resetsAt = "resets_at"
            case resetAt = "reset_at"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            used = try container.decodeIfPresent(Double.self, forKey: .used) ?? 0
            limit = try container.decodeIfPresent(Double.self, forKey: .limit)
            resetsAt = try container.decodeIfPresent(String.self, forKey: .resetsAt)
                ?? container.decodeIfPresent(String.self, forKey: .resetAt)
            plan = try container.decodeIfPresent(String.self, forKey: .plan)
            byokUsed = try container.decodeIfPresent(Double.self, forKey: .byokUsed)
        }

        var fraction: Double? {
            guard let limit, limit > 0 else { return nil }
            return min(max(used / limit, 0), 1)
        }
    }
}

// Only the fields being changed are sent; a nil is left out, not cleared.
struct LighthouseV2SettingsChange: Encodable, Equatable, Sendable {
    var defaultWhisper: Bool?
    var dataAccess: [String: LighthouseV2Settings.Access]?
    // `.some(nil)` sends null: back to the Lighthouse default.
    var model: String??
    var mode: String?
    var byokFallback: Bool?

    private enum CodingKeys: String, CodingKey {
        case model, mode
        case defaultWhisper = "default_whisper"
        case dataAccess = "data_access"
        case byokFallback = "byok_fallback"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(defaultWhisper, forKey: .defaultWhisper)
        try container.encodeIfPresent(byokFallback, forKey: .byokFallback)
        try container.encodeIfPresent(dataAccess, forKey: .dataAccess)
        if let model { try container.encode(model, forKey: .model) }
        try container.encodeIfPresent(mode, forKey: .mode)
    }
}

// MARK: - Summary

struct LighthouseV2Summary: Decodable, Equatable, Sendable {
    let day: String?
    // The text with each claim token replaced by its value.
    let rendered: String
    let suggestions: [String]
    let generatedAt: String?
    // usage_limit: the last summary (or none) comes back with this.
    let notice: Notice?

    struct Notice: Decodable, Equatable, Sendable {
        let kind: String?
        let text: String
    }

    private enum CodingKeys: String, CodingKey {
        case day, rendered, text, suggestions, notice
        case generatedAt = "generated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decodeIfPresent(String.self, forKey: .day)
        rendered = try container.decodeIfPresent(String.self, forKey: .rendered)
            ?? container.decodeIfPresent(String.self, forKey: .text) ?? ""
        suggestions = try container.decodeIfPresent([String].self, forKey: .suggestions) ?? []
        generatedAt = try container.decodeIfPresent(String.self, forKey: .generatedAt)
        notice = try? container.decodeIfPresent(Notice.self, forKey: .notice)
    }
}

// MARK: - Series

// `GET /health/v5/series`: a Health tile's chart, or the notice saying why there's none.
struct LighthouseV2Series: Decodable, Equatable, Sendable {
    let chart: LighthouseV2Block.Chart?
    let notice: String?
    // A chart this version can't read, which shows the placeholder rather than an error.
    let isUnreadable: Bool

    init(chart: LighthouseV2Block.Chart?, notice: String?, isUnreadable: Bool = false) {
        self.chart = chart
        self.notice = notice
        self.isUnreadable = isUnreadable
    }

    private enum CodingKeys: String, CodingKey {
        case chart, notice
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notice = try container.decodeIfPresent(String.self, forKey: .notice)
        let isPresent = try container.contains(.chart) && !container.decodeNil(forKey: .chart)
        chart = isPresent ? try? container.decode(LighthouseV2Block.Chart.self, forKey: .chart) : nil
        isUnreadable = isPresent && chart == nil
    }

    struct Envelope: Decodable {
        let data: LighthouseV2Series
    }
}

// MARK: - Impact

enum LighthouseV2Rating: String, Sendable {
    case up
    case down
}

// A thumb on a reply (BX7): the body of `POST /messages/{id}/feedback`, and what a
// stored message carries. The rating stays a string so a new one doesn't fail the message.
struct LighthouseV2Feedback: Codable, Equatable, Sendable {
    let rating: String
    var reason: String?

    init(_ rating: LighthouseV2Rating) {
        self.rating = rating.rawValue
    }

    var value: LighthouseV2Rating? { LighthouseV2Rating(rawValue: rating) }
}

struct LighthouseV2Deleted: Decodable, Equatable, Sendable {
    let deleted: Int?
}

// The Bright error envelope, `{status: "failure", message, code, data}`; a bare
// FastAPI `{detail}` is read too in case a route skips the handler.
struct LighthouseV2ErrorBody: Decodable, Equatable, Sendable {
    let message: String?
    let detail: String?
    let code: Code?

    private enum CodingKeys: String, CodingKey {
        case message, detail, code
    }

    // A validation `detail` arrives as a list, so each field is read on its own.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try? container.decodeIfPresent(String.self, forKey: .message)
        detail = try? container.decodeIfPresent(String.self, forKey: .detail)
        code = try? container.decodeIfPresent(Code.self, forKey: .code)
    }

    // `code` is the HTTP status in the envelope, but a named code such as
    // `storage_unavailable` in newer routes.
    enum Code: Decodable, Equatable, Sendable {
        case status(Int)
        case name(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let status = try? container.decode(Int.self) {
                self = .status(status)
            } else {
                self = try .name(container.decode(String.self))
            }
        }
    }

    var name: String? {
        if case let .name(name) = code { name } else { nil }
    }

    var text: String? {
        [message, detail].compactMap { $0 }.first { !$0.isEmpty }
    }
}
