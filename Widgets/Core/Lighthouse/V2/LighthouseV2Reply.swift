//
//  LighthouseV2Reply.swift
//  Widgets
//
//

import Foundation

// One assistant turn, filled in as its events arrive. A reference type so the reply's
// view follows it directly; the chat shell only diffs its messages by id.
@MainActor @Observable
final class LighthouseV2Reply: Identifiable {

    enum Status: Equatable {
        case streaming
        case completed
        // Stop was tapped, or the thread holds a question with no stored answer.
        case stopped
        case failed(LighthouseV2Error)
    }

    struct Step: Identifiable, Equatable {
        // Stable across redraws, so the timeline keeps each row's state.
        let rowID = UUID()
        let id: String
        let kind: String
        let label: String
        let tool: String?
        var ms: Int?
        var detail: String?
    }

    let id = UUID()
    private(set) var messageID: String?
    private(set) var steps: [Step] = []
    private(set) var blocks: [LighthouseV2Block] = []
    private(set) var claims: [String: LighthouseV2Claim] = [:]
    private(set) var status: Status
    private(set) var thoughtSeconds: Int?
    private(set) var createdAt: Date
    // Choices blocks already answered, so their box locks.
    var answeredChoices: Set<String> = []
    // The person's thumb, shown before the server confirms it.
    var rating: LighthouseV2Rating?
    // Attachments going up before the turn starts, 0-1; nil once they're sent.
    var uploadProgress: Double?

    private let startedAt = Date()

    init() {
        status = .streaming
        createdAt = .now
    }

    // A reply read back from the thread.
    init(message: LighthouseV2Message) {
        messageID = message.id
        blocks = message.blocks
        claims = message.claims ?? [:]
        rating = message.feedback?.value
        status = .completed
        createdAt = message.createdAt.flatMap { Date(lighthouseISO: $0) } ?? .now
    }

    // Blocks with no stored message: a whisper card's confirmation.
    init(blocks: [LighthouseV2Block]) {
        self.blocks = blocks
        status = .completed
        createdAt = .now
    }

    static func stopped() -> LighthouseV2Reply {
        let reply = LighthouseV2Reply()
        reply.status = .stopped
        return reply
    }

    var isStreaming: Bool { status == .streaming }

    var hasThinking: Bool { !steps.isEmpty || isStreaming }

    var text: String {
        blocks.compactMap { block in
            if case let .text(text) = block { text.text } else { nil }
        }
        .joined(separator: "\n\n")
    }

    func apply(_ event: LighthouseV2Event) {
        switch event {
        case .turnStarted, .unknown:
            break
        case let .stepStarted(step):
            guard !steps.contains(where: { $0.id == step.stepID }) else { return }
            steps.append(Step(id: step.stepID, kind: step.kind, label: step.label, tool: step.tool, ms: nil, detail: step.detail))
        case let .stepFinished(step):
            if let index = steps.firstIndex(where: { $0.id == step.stepID }) {
                steps[index].ms = step.ms
                steps[index].detail = step.detail
            } else {
                steps.append(Step(id: step.stepID, kind: step.kind, label: step.label, tool: step.tool, ms: step.ms, detail: step.detail))
            }
        case let .blockDelta(delta):
            finishThinking()
            if let index = blocks.firstIndex(where: { $0.id == delta.blockID }),
               case var .text(text) = blocks[index] {
                text.text += delta.text
                blocks[index] = .text(text)
            } else {
                blocks.append(.text(.init(id: delta.blockID, text: delta.text, claims: nil, source: nil)))
            }
        case let .blockReplace(replace):
            finishThinking()
            if let index = blocks.firstIndex(where: { $0.id == replace.blockID }),
               case var .text(text) = blocks[index] {
                text.text = replace.text
                blocks[index] = .text(text)
            } else {
                blocks.append(.text(.init(id: replace.blockID, text: replace.text, claims: nil, source: nil)))
            }
        case let .block(block):
            finishThinking()
            if let index = blocks.firstIndex(where: { $0.id == block.id }) {
                blocks[index] = block
            } else {
                blocks.append(block)
            }
        case let .turnCompleted(completed):
            messageID = completed.messageID
            finishThinking()
            status = .completed
        case let .turnError(error):
            // Text streamed before the error isn't a reply.
            blocks.removeAll()
            finishThinking()
            status = .failed(.turn(error))
        }
    }

    func fail(_ error: LighthouseV2Error) {
        guard isStreaming else { return }
        finishThinking()
        status = .failed(error)
    }

    // A file the size check or the server turned down: the reason as a notice, in place of a reply.
    func refuse(_ error: LighthouseV2Error) {
        guard isStreaming else { return }
        finishThinking()
        uploadProgress = nil
        blocks = [.notice(.init(id: "upload", kind: "error", text: error.userMessage))]
        status = .completed
    }

    func stop() {
        guard isStreaming else { return }
        finishThinking()
        status = .stopped
    }

    // The stream carries no claims; the stored message has them.
    func adopt(_ message: LighthouseV2Message) {
        claims = message.claims ?? [:]
        if blocks.isEmpty { blocks = message.blocks }
        if rating == nil { rating = message.feedback?.value }
        if let created = message.createdAt.flatMap({ Date(lighthouseISO: $0) }) { createdAt = created }
    }

    var claimsByID: [String: LighthouseV2Claim] { claims }

    func claims(for ids: [String]?) -> [LighthouseV2Claim] {
        (ids ?? []).compactMap { claims[$0] }
    }

    private func finishThinking() {
        guard thoughtSeconds == nil, isStreaming else { return }
        thoughtSeconds = max(1, Int(Date().timeIntervalSince(startedAt).rounded()))
    }
}

extension LighthouseV2Reply: Equatable {
    nonisolated static func == (lhs: LighthouseV2Reply, rhs: LighthouseV2Reply) -> Bool {
        lhs === rhs
    }
}
