//
//  BrightReorderableStackV5.swift
//  Widgets
//

import SwiftUI

enum BrightReorderKey: String {
    case activitySummary
    case cycleData
    case cycleSummary
    case exerciseImpact
    case exerciseProgress
    case exerciseSummary
    case fatigueContributors
    case heartContributors
    case heartHrv
    case heartSummary
    case hydrationSummary
    case intakeSummary
    case macrosSummary
    case readinessContributors
    case recoveryContributors
    case sleepScore
    case sleepSummary
    case vaultImpact
    case weightSummary
}

@MainActor @Observable
final class BrightReorderStore {
    static let shared = BrightReorderStore()

    private(set) var generation = 0

    private init() {}

    func resetAll() {
        LocalStorage.brightReorderOrders = [:]
        generation += 1
    }
}

extension BrightReorderKey {
    var storedOrder: [String] {
        get { LocalStorage.brightReorderOrders[rawValue] ?? [] }
        nonmutating set { LocalStorage.brightReorderOrders[rawValue] = newValue }
    }
}

protocol BrightReorderableSection: Identifiable, CaseIterable, Hashable, RawRepresentable where RawValue == String, ID == String {}

extension BrightReorderableSection {
    var id: String { rawValue }
}

struct BrightReorderableStackV5<Section: BrightReorderableSection, Content: View>: View {
    private let key: BrightReorderKey
    private let alignment: HorizontalAlignment
    private let spacing: CGFloat
    private let showsDividers: Bool
    private let isVisible: (Section) -> Bool
    private let content: (Section) -> Content

    @State private var order: [Section]

    private let store = BrightReorderStore.shared

    init(
        _ key: BrightReorderKey,
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat = .spacing3x,
        showsDividers: Bool = false,
        isVisible: @escaping (Section) -> Bool = { _ in true },
        @ViewBuilder content: @escaping (Section) -> Content
    ) {
        self.key = key
        self.alignment = alignment
        self.spacing = spacing
        self.showsDividers = showsDividers
        self.isVisible = isVisible
        self.content = content
        _order = State(initialValue: Self.storedOrder(for: key))
    }

    private var visibleSections: [Section] {
        order.filter(isVisible)
    }

    var body: some View {
        Group {
            if #available(iOS 27, *) {
                reorderableStack
            } else {
                plainStack
            }
        }
        .onChange(of: store.generation) { _, _ in
            withAnimation(.brightSpring) {
                order = Self.storedOrder(for: key)
            }
        }
    }

    private var plainStack: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(visibleSections) { section in
                row(section)
            }
        }
    }

    @ViewBuilder
    private func row(_ section: Section) -> some View {
        VStack(alignment: alignment, spacing: spacing) {
            content(section)
            if showsDividers, section != visibleSections.last {
                BrightDividerV5()
            }
        }
    }

    @available(iOS 27, *)
    private var reorderableStack: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(visibleSections) { section in
                row(section)
                    .contentShape(.dragPreview, .rect(cornerRadius: .cardCornerRadius))
            }
            .reorderable()
        }
        .reorderContainer(for: Section.self) { difference in
            apply(difference)
        }
    }

    @available(iOS 27, *)
    private func apply(_ difference: ReorderDifference<String, ReorderableSingleCollectionIdentifier>) {
        let moving = Set(difference.sources)
        var updated = order
        let moved = updated.filter { moving.contains($0.id) }
        guard !moved.isEmpty else { return }
        updated.removeAll { moving.contains($0.id) }

        let insertionIndex: Int = switch difference.destination.position {
        case .end:
            updated.endIndex
        case let .before(id):
            updated.firstIndex { $0.id == id } ?? updated.endIndex
        }
        updated.insert(contentsOf: moved, at: insertionIndex)

        withAnimation(.brightSpring) {
            order = updated
        }
        key.storedOrder = updated.map(\.rawValue)
    }

    private static func storedOrder(for key: BrightReorderKey) -> [Section] {
        let saved = key.storedOrder.compactMap(Section.init(rawValue:))
        let missing = Section.allCases.filter { !saved.contains($0) }
        return saved + missing
    }
}
