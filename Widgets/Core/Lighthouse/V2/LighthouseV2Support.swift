//
//  LighthouseV2Support.swift
//  Widgets
//

import Foundation

enum JSONValue: Codable, Equatable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case let .bool(value): try container.encode(value)
        case let .int(value): try container.encode(value)
        case let .double(value): try container.encode(value)
        case let .string(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case let .object(value): try container.encode(value)
        }
    }

    // Re-decode this JSON value into a concrete `Decodable` type.
    func decode<T: Decodable>(_ type: T.Type) -> T? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

enum LighthouseV2Error: Error, Equatable {
    case badURL
    case unauthorized
    case notFound(String?)
    case conflict(code: String?, message: String?)
    case tooLarge(String?)
    case unsupportedType(String?)
    case invalid(String?)
    case storageUnavailable(String?)
    case forbidden(String?)
    case expired(String?)
    // A 429 that eases with time: a waypoint check-in run twice in a day, or PRIV1's daily uploads or turns at once.
    // The weekly limit arrives as a notice, never an error.
    case tooSoon(String?)
    case writeFailed(String?)
    case http(status: Int, message: String?)
    case turn(LighthouseV2TurnError)
    // The stream closed without `turn.completed` or `turn.error`.
    case interrupted
    case idleTimeout
    case transport
    case decoding

    static func from(status: Int, body: Data) -> Self {
        let parsed = try? LighthouseV2Coding.decoder().decode(LighthouseV2ErrorBody.self, from: body)
        let message = parsed?.text
        switch status {
        case 401: return .unauthorized
        // Only an action's confirm answers 403: its data category is switched off.
        case 403: return message == nil ? .unauthorized : .forbidden(message)
        case 404: return .notFound(message)
        case 410: return .expired(message)
        case 429: return .tooSoon(message)
        case 502: return .writeFailed(message)
        case 409: return .conflict(code: parsed?.name, message: message)
        case 413: return .tooLarge(message)
        case 415: return .unsupportedType(message)
        case 422: return .invalid(message)
        case 503 where parsed?.name == "storage_unavailable": return .storageUnavailable(message)
        case 503: return .storageUnavailable(message)
        default: return .http(status: status, message: message)
        }
    }

    var isRetryable: Bool {
        switch self {
        case let .turn(error): error.retryable
        case .unauthorized, .notFound, .tooLarge, .unsupportedType, .invalid, .badURL, .decoding, .forbidden, .expired, .tooSoon: false
        case let .conflict(code, _): code == "turn_in_progress"
        default: true
        }
    }

    // An upload turned down for what the file is, which no Retry changes.
    var refusesUpload: Bool {
        switch self {
        // PRIV1: 20 uploads a day (429) and 50 MB stored (409 attachment_storage_full) refuse the file too.
        case .tooLarge, .unsupportedType, .invalid, .tooSoon: true
        case let .conflict(code, _): code == "attachment_storage_full"
        default: false
        }
    }

    // Server messages are written to be shown; the rest are ours.
    var userMessage: String {
        switch self {
        case .unauthorized: "Your session has expired. Sign in again to keep using Lighthouse."
        case let .notFound(message): message ?? "That conversation no longer exists."
        case let .conflict(code, message):
            code == "turn_in_progress"
                ? "Lighthouse is still answering your last message."
                : message ?? "That couldn't be done right now."
        case let .tooLarge(message): message ?? "Files can be up to 10 MB."
        case let .unsupportedType(message): message ?? "Attach a PDF, JPEG, PNG or HEIC file."
        case let .invalid(message): message ?? "Lighthouse couldn't read that request."
        case .storageUnavailable: "Lighthouse can't reach its storage right now. Try again in a moment."
        case let .forbidden(message): message ?? "That data is switched off in Lighthouse settings."
        case let .expired(message): message ?? "This card has expired. Ask again for a fresh one."
        case let .tooSoon(message): message ?? "That can't run again yet. Try again later."
        case let .writeFailed(message): message ?? "That didn't work just now. Try again."
        case let .http(_, message): message ?? "Lighthouse didn't answer. Try again."
        case let .turn(error): error.message
        case .interrupted: "The answer was cut off. Try again."
        case .idleTimeout: "Lighthouse stopped responding. Try again."
        case .transport: "Lighthouse can't be reached. Check your connection and try again."
        case .badURL, .decoding: "Lighthouse sent something this version can't read."
        }
    }
}

// Only the evidence a card cites; the adjustment itself is the server's.
enum LighthouseV2Adjustment {
    struct Evidence: Decodable, Equatable, Sendable {
        struct Row: Decodable, Equatable, Sendable {
            let marker: String?
            let value: String?
            let tag: String?
            let status: String?

            private enum CodingKeys: String, CodingKey {
                case marker, value, tag, status
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                marker = try container.decodeLenientString(forKey: .marker)
                value = try container.decodeLenientString(forKey: .value)
                tag = try container.decodeLenientString(forKey: .tag)
                status = try container.decodeIfPresent(String.self, forKey: .status)
            }
        }

        let title: String?
        let period: String?
        let source: String?
        let rows: [Row]
        let note: String?

        private enum CodingKeys: String, CodingKey {
            case title, period, source, rows, note
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decodeIfPresent(String.self, forKey: .title)
            period = try container.decodeIfPresent(String.self, forKey: .period)
            source = try container.decodeIfPresent(String.self, forKey: .source)
            rows = try container.decodeIfPresent([Row].self, forKey: .rows) ?? []
            note = try container.decodeIfPresent(String.self, forKey: .note)
        }
    }
}

extension KeyedDecodingContainer {
    // A number or a string, as text ("7,689" stays as sent; 7689.0 becomes "7689").
    func decodeLenientString(forKey key: Key) throws -> String? {
        if let text = try? decodeIfPresent(String.self, forKey: key) { return text }
        guard let number = try? decodeIfPresent(Double.self, forKey: key) else { return nil }
        return number.rounded() == number ? String(Int(number)) : String(number)
    }
}
