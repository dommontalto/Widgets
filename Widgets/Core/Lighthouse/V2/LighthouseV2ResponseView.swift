//
//  LighthouseV2ResponseView.swift
//  Widgets
//
//

import SwiftUI

// A v2 reply in the thread: the real thinking steps, then its blocks in the order the
// engine sent them. Block types this version doesn't know are skipped.
struct LighthouseV2ResponseView: View {
    let reply: LighthouseV2Reply
    let onSend: (String) -> Void
    let onAnswer: (LighthouseV2Block.Choices, String) -> Void
    let onNextStep: (LighthouseV2Block.NextStep) -> Void
    var onRate: (LighthouseV2Rating) -> Void = { _ in }
    var cardState: (LighthouseV2Block.Card) -> LighthouseV2CardState = { _ in .pending }
    var onDecide: (LighthouseV2Block.Card, LighthouseV2Block.Card.Action, LighthouseV2Decision) -> Void = { _, _, _ in }
    var onChartTap: (HealthWidgetKindV5) -> Void = { _ in }

    @State private var isCopied = false
    @State private var tappedRating: LighthouseV2Rating?
    @State private var shareTaps = 0

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            if let progress = reply.uploadProgress {
                uploadRow(progress)
            }

            if reply.hasThinking {
                LighthouseThinkingInline(steps: thoughtSteps, thoughtSeconds: reply.thoughtSeconds, isLive: true)
            }

            ForEach(reply.blocks) { block in
                blockView(block)
            }

            if reply.status == .stopped {
                stoppedRow
            } else if reply.status == .completed, !reply.text.isEmpty {
                actions
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // `.contain` keeps the thumbs' and actions' own identifiers under the reply's.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("lighthouse.v2.reply")
    }

    @ViewBuilder
    private func blockView(_ block: LighthouseV2Block) -> some View {
        switch block {
        case let .text(text):
            LighthouseV2TextBlockView(block: text, claims: reply.claims(for: text.claims), allClaims: Array(reply.claimsByID.values))
        case let .choices(choices):
            LighthouseChoiceBox(
                options: choices.options,
                prompt: choices.prompt,
                allowsMultiple: choices.allowsMultiple,
                submitTitle: choices.submitLabel,
                isAnswered: reply.answeredChoices.contains(choices.id)
            ) { onAnswer(choices, $0) }
        case let .suggestions(suggestions):
            if reply.status == .completed {
                LighthouseChoiceBox(options: suggestions.items, onSubmit: onSend)
            }
        case let .chart(chart):
            LighthouseV2ChartView(chart: chart, onTap: onChartTap)
        case let .notice(notice) where notice.onlyOpensGenomeSettings:
            EmptyView()
        case let .notice(notice):
            LighthouseV2NoticeView(notice: notice, onNextStep: onNextStep)
        case let .card(card):
            LighthouseV2CardView(card: card, state: cardState(card)) { onDecide(card, $0, $1) }
        case .unknown:
            EmptyView()
        }
    }

    private var thoughtSteps: [LighthouseThoughtStep] {
        reply.steps.map { step in
            LighthouseThoughtStep(
                id: step.rowID,
                symbol: Self.symbol(kind: step.kind, tool: step.tool),
                title: step.label,
                detail: step.detail ?? "",
                isExpandable: !(step.detail ?? "").isEmpty,
                timing: step.ms.map(Self.timing)
            )
        }
    }

    private func uploadRow(_ progress: Double) -> some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            BrightText("\(Constants.uploading) \(Int((progress * 100).rounded()))%", size: .body3, color: .lightTextColor)
            ProgressView(value: progress)
                .tint(.textColor)
        }
        .accessibilityIdentifier("lighthouse.v2.upload")
    }

    private var stoppedRow: some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: "stop.circle")
                .font(.standard(size: .body1, weight: .light))
            BrightText(Constants.stopped, size: .body1, color: .lightTextColor)
        }
        .foregroundStyle(Color.lightTextColor)
        .accessibilityIdentifier("lighthouse.v2.stopped")
    }

    private var actions: some View {
        HStack(spacing: .spacing3x) {
            if reply.messageID != nil {
                ratingButton(.up)
                ratingButton(.down)
            }

            Button {
                UIPasteboard.general.string = reply.text
                isCopied = true
            } label: {
                actionIcon(isCopied ? "checkmark.circle" : "doc.on.doc")
                    .contentTransition(.symbolEffect(.replace))
            }
            .brightHapticV5(.success, trigger: isCopied) { _, copied in copied }
            .task(id: isCopied) {
                guard isCopied else { return }
                try? await Task.sleep(for: .seconds(Constants.copiedDuration))
                isCopied = false
            }

            ShareLink(item: reply.text) {
                actionIcon("square.and.arrow.up")
            }
            .simultaneousGesture(TapGesture().onEnded { shareTaps += 1 })
            .brightHapticV5(.light, trigger: shareTaps)

            Spacer(minLength: .spacing0x)

            BrightText(reply.createdAt.formatted(.brightTime), size: .body1, color: .lightTextColor)
        }
        .buttonStyle(.plain)
        .brightHapticV5(.light, trigger: reply.rating)
    }

    private func ratingButton(_ value: LighthouseV2Rating) -> some View {
        let symbol = value == .up ? "hand.thumbsup" : "hand.thumbsdown"
        return Button {
            tappedRating = value
            onRate(value)
        } label: {
            actionIcon(reply.rating == value ? "\(symbol).fill" : symbol)
                .contentTransition(tappedRating == value ? .symbolEffect(.replace) : .identity)
        }
        .accessibilityLabel(value == .up ? "Good reply" : "Bad reply")
        .accessibilityAddTraits(reply.rating == value ? .isSelected : [])
        .accessibilityIdentifier("lighthouse.v2.rate.\(value.rawValue)")
    }

    private func actionIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.standardSFPro(size: .body1, weight: .light))
            .foregroundStyle(Color.lightTextColor)
            .frame(width: Constants.iconSize, height: Constants.iconSize)
            .contentShape(Rectangle())
    }

    static func timing(_ ms: Int) -> String {
        "\((Double(ms) / 1000).formatted(.number.precision(.fractionLength(1)))) s"
    }

    static func symbol(kind: String, tool: String?) -> String {
        switch kind {
        case "gate": return "checkmark.shield"
        case "context": return "text.bubble"
        case "compose": return "pencil.line"
        case "validate": return "checkmark.seal"
        default: break
        }
        switch tool {
        case "personal_data": return "heart.text.square"
        case "knowledge": return "books.vertical"
        case "atlas_query": return "person.3"
        case "food_log": return "fork.knife"
        case "program_builder": return "figure.strengthtraining.traditional"
        case "parse_document": return "doc.text.magnifyingglass"
        case "create_checkin": return "person.badge.clock"
        case "log_water": return "drop"
        case "log_weight": return "scalemass"
        case "log_activity": return "figure.run"
        case "undo_log": return "arrow.uturn.backward"
        case "create_waypoint": return "location.north.circle"
        default: return "gearshape"
        }
    }

    private enum Constants {
        static let stopped = "Stopped"
        static let uploading = "Uploading"
        static let copiedDuration: Double = 2
        static let iconSize: CGFloat = .spacing4x
    }
}

// MARK: - Text

struct LighthouseV2TextBlockView: View {
    let block: LighthouseV2Block.Text
    let claims: [LighthouseV2Claim]
    // Every claim in the reply, for the Atlas group size an Atlas figure is shown with.
    var allClaims: [LighthouseV2Claim] = []

    @State private var showsClaims = false

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            if block.isGeneralKnowledge {
                Label(Constants.generalKnowledge, systemImage: "books.vertical")
                    .font(.standard(size: .body4, weight: .regular))
                    .foregroundStyle(Color.lightTextColor)
            }

            LighthouseV2Markdown(text: block.text)

            // A general-knowledge block isn't the person's data, so it has no figures line.
            if !claims.isEmpty, !block.isGeneralKnowledge {
                claimsDisclosure
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var claimsDisclosure: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            Button {
                withAnimation(.brightSnappy) { showsClaims.toggle() }
            } label: {
                HStack(spacing: .spacing1x) {
                    Image(systemName: "number")
                    BrightText(claims.count == 1 ? Constants.oneFigure : "Based on \(claims.count) figures", size: .body4, color: .lightTextColor)
                    Image(systemName: "chevron.forward")
                        .rotationEffect(.degrees(showsClaims ? 90 : 0))
                    Spacer(minLength: .spacing0x)
                }
                .font(.standard(size: .body4, weight: .regular))
                .foregroundStyle(Color.lightTextColor)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .brightHapticV5(.light, trigger: showsClaims)

            if showsClaims {
                VStack(alignment: .leading, spacing: .spacing105x) {
                    ForEach(claims) { claim in
                        claimRow(claim)
                    }
                }
                .padding(.leading, .spacing2x)
                .transition(.opacity)
            }
        }
    }

    private func claimRow(_ claim: LighthouseV2Claim) -> some View {
        VStack(alignment: .leading, spacing: .spacing025x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                BrightText(claim.label.capitalizedFirst, size: .body4, color: .semiLightTextColor)
                Spacer(minLength: .spacing1x)
                BrightText(claim.displayValue, size: .body4)
                    .monospacedDigit()
            }
            BrightText(Self.provenance(of: claim, among: allClaims), size: .body5, color: .lightTextColor)
        }
    }

    static func provenance(of claim: LighthouseV2Claim, among all: [LighthouseV2Claim] = []) -> String {
        let who = switch (claim.source, claim.population) {
        case ("atlas", _): atlasPeople(all).map { "From Atlas · \($0) people" } ?? "From Atlas"
        case (_, "cohort"): "People like you"
        case (_, "population"): "Everyone on Bright"
        case (_, "general"): "General knowledge"
        default: "Your data"
        }
        return [who, claim.window?.replacingOccurrences(of: "..", with: " – ")].compactMap { $0 }.joined(separator: " · ")
    }

    // The group an Atlas comparison read: its "people analysed" count, else any Atlas count of people.
    static func atlasPeople(_ claims: [LighthouseV2Claim]) -> String? {
        let counts = claims.filter { $0.source == "atlas" && $0.unit == "people" }
        let picked = counts.first { $0.label.localizedCaseInsensitiveContains("analysed") } ?? counts.first
        guard case let .number(value)? = picked?.value else { return nil }
        return Int(value).formatted(.number)
    }

    private enum Constants {
        static let generalKnowledge = "General knowledge · not your data"
        static let oneFigure = "Based on 1 figure"
    }
}

// Markdown as the engine writes it: paragraphs, bullet and numbered lists, and headings,
// with inline emphasis. Anything else reads as plain text.
struct LighthouseV2Markdown: View {
    let text: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    var body: some View {
        LighthouseV2SelectableText(
            text: Self.attributed(Self.lines(text), colorScheme: colorScheme),
            onLink: { openURL($0) }
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    enum Line: Equatable {
        case heading(String)
        case bullet(marker: String, text: String)
        case paragraph(String)
    }

    static func inline(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }

    // One string, so a selection can run across paragraphs and list items.
    static func attributed(_ lines: [Line], colorScheme: ColorScheme) -> NSAttributedString {
        let traits = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        let textColor = UIColor(Color.textColor).resolvedColor(with: traits)
        let markerColor = UIColor(Color.semiLightTextColor).resolvedColor(with: traits)
        let result = NSMutableAttributedString()
        for (index, line) in lines.enumerated() {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = .lineSpacingMedium
            style.paragraphSpacing = .spacing2x
            let piece = NSMutableAttributedString()
            switch line {
            case let .heading(text):
                piece.append(styled(inline(text), weight: .medium, color: textColor))
            case let .bullet(marker, text):
                let markerFont = font(weight: .light)
                let indent = (marker as NSString).size(withAttributes: [.font: markerFont]).width + .spacing1x
                style.tabStops = [NSTextTab(textAlignment: .left, location: indent)]
                style.headIndent = indent
                piece.append(NSAttributedString(string: "\(marker)\t", attributes: [.font: markerFont, .foregroundColor: markerColor]))
                piece.append(styled(inline(text), weight: .light, color: textColor))
            case let .paragraph(text):
                piece.append(styled(inline(text), weight: .light, color: textColor))
            }
            if index < lines.count - 1 {
                piece.append(NSAttributedString(string: "\n"))
            }
            piece.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: piece.length))
            result.append(piece)
        }
        return result
    }

    private static func styled(_ text: AttributedString, weight: UIFont.Weight, color: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for run in text.runs {
            let intent = run.inlinePresentationIntent ?? []
            var attributes: [NSAttributedString.Key: Any] = [
                .font: font(
                    weight: intent.contains(.stronglyEmphasized) ? .semibold : weight,
                    italic: intent.contains(.emphasized),
                    code: intent.contains(.code)
                ),
                .foregroundColor: color,
            ]
            if let link = run.link {
                attributes[.link] = link
            }
            result.append(NSAttributedString(string: String(text[run.range].characters), attributes: attributes))
        }
        return result
    }

    private static func font(weight: UIFont.Weight, italic: Bool = false, code: Bool = false) -> UIFont {
        let size = FontSizes.body1.rawValue
        if code {
            return .monospacedSystemFont(ofSize: size, weight: weight)
        }
        var descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
        descriptor = descriptor.withDesign(.rounded) ?? descriptor
        if italic {
            descriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitItalic)) ?? descriptor
        }
        return UIFont(descriptor: descriptor, size: size)
    }

    static func lines(_ text: String) -> [Line] {
        var result: [Line] = []
        var paragraph: [String] = []
        func flush() {
            guard !paragraph.isEmpty else { return }
            result.append(.paragraph(paragraph.joined(separator: " ")))
            paragraph = []
        }
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flush()
            } else if let heading = line.headingText {
                flush()
                result.append(.heading(heading))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("• ") {
                flush()
                result.append(.bullet(marker: "•", text: String(line.dropFirst(2))))
            } else if let (number, rest) = line.numbered {
                flush()
                result.append(.bullet(marker: "\(number).", text: rest))
            } else {
                paragraph.append(line)
            }
        }
        flush()
        return result
    }
}

private extension String {
    var headingText: String? {
        guard hasPrefix("#") else { return nil }
        let text = drop { $0 == "#" }
        guard text.hasPrefix(" ") else { return nil }
        return text.trimmingCharacters(in: .whitespaces)
    }

    var numbered: (Int, String)? {
        guard let dot = firstIndex(of: "."), let number = Int(self[startIndex ..< dot]),
              self[index(after: dot)...].hasPrefix(" ") else { return nil }
        return (number, self[index(after: dot)...].trimmingCharacters(in: .whitespaces))
    }

    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}

// SwiftUI Text on iOS only copies a whole run; a part of an answer needs UITextView.
struct LighthouseV2SelectableText: UIViewRepresentable {
    let text: NSAttributedString
    let onLink: (URL) -> Void

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.delegate = context.coordinator
        view.accessibilityIdentifier = "lighthouse.v2.text"
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.onLink = onLink
        if view.attributedText != text {
            view.attributedText = text
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? .greatestFiniteMagnitude
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width == .greatestFiniteMagnitude ? size.width : width, height: size.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLink: onLink)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var onLink: (URL) -> Void

        init(onLink: @escaping (URL) -> Void) {
            self.onLink = onLink
        }

        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
            guard case let .link(url) = textItem.content else { return defaultAction }
            return UIAction { [onLink] _ in onLink(url) }
        }
    }
}

// MARK: - Notices

struct LighthouseV2NoticeView: View {
    let notice: LighthouseV2Block.Notice
    let onNextStep: (LighthouseV2Block.NextStep) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .top, spacing: .spacing105x) {
                Image(systemName: symbol)
                    .font(.standard(size: .body1, weight: .regular))
                    .foregroundStyle(tint)

                BrightText(notice.text, size: .body2, color: .semiLightTextColor)
                    .lineSpacing(.lineSpacingMedium)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let resets = notice.resetsAt.flatMap({ Date(lighthouseISO: $0) }) {
                BrightText("\(Constants.resets) \(resets.formatted(.brightTimestamp))", size: .body4, color: .lightTextColor)
                    .accessibilityIdentifier("lighthouse.v2.notice.resets")
            }

            if !notice.steps.isEmpty {
                HStack(spacing: .spacing1x) {
                    ForEach(Array(notice.steps.enumerated()), id: \.offset) { _, step in
                        BrightPillButton(step.label, buttonSize: .small) { onNextStep(step) }
                    }
                }
            }
        }
        .padding(.spacing2x)
        .modifier(BrightCardModifierV5())
        .accessibilityIdentifier("lighthouse.v2.notice.\(notice.kind)")
    }

    private enum Constants {
        static let resets = "Resets"
    }

    private var symbol: String {
        switch notice.kind {
        case "usage_limit": "gauge.with.dots.needle.100percent"
        case "refusal": "hand.raised"
        case "data_access": "lock"
        case "fallback": "arrow.triangle.branch"
        case "reframe": "arrow.uturn.right"
        case "error", "own_key": "exclamationmark.triangle"
        default: "info.circle"
        }
    }

    private var tint: Color {
        switch notice.kind {
        case "refusal", "error", "usage_limit", "own_key": .defaultOrange
        case "data_access": .defaultYellow
        default: .lightTextColor
        }
    }
}
