//
//  LighthouseHistoryGuidedTesting.swift
//  Widgets
//

import SwiftUI

// Past chats, searchable, with a filter for pinned ones and a sort; pinned chats lead.
struct LighthouseHistoryGuidedTesting: View {
    var onOpen: (LighthouseHistoryEntry) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var entries = LighthouseDemo.history
    @State private var searchText = ""
    @State private var filter = Filter.all
    @State private var sort = Sort.newest

    var body: some View {
        BrightPageSheetViewV5(title: Constants.title) {
            ToolbarItem(placement: .topBarTrailing) {
                filterMenu
            }
        } content: {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing3x) {
                    if shown.isEmpty {
                        BrightText(Constants.empty, size: .body1, color: .lightTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.top, .spacing6x)
                    }
                    if !pinned.isEmpty {
                        section(Constants.pinnedTitle, pinned)
                    }
                    if !others.isEmpty {
                        section(pinned.isEmpty ? nil : Constants.recentTitle, others)
                    }
                }
                .padding(.vertical, .spacing2x)
            }
            .searchable(text: $searchText, prompt: Constants.searchPrompt)
        }
        .animation(.brightSnappy, value: filter)
        .animation(.brightSnappy, value: sort)
        .animation(.brightSnappy, value: searchText)
    }

    // MARK: - List

    // One card per section, rows joined like Personal Details.
    private func section(_ title: String?, _ items: [LighthouseHistoryEntry]) -> some View {
        BrightRowGroupV5(header: title, color: .defaultSheetModalCards) {
            ForEach(items) { entry in
                row(entry)
            }
        }
    }

    private func row(_ entry: LighthouseHistoryEntry) -> some View {
        BrightRowV5(
            entry.title,
            subtitle: entry.when,
            icon: .symbol(entry.isPinned ? "pin.fill" : "bubble.left.and.text.bubble.right", tint: .semiLightTextColor),
            trailing: .chevron
        ) {
            onOpen(entry)
            dismiss()
        }
        .contextMenu {
            Button(entry.isPinned ? "Unpin" : "Pin", systemImage: entry.isPinned ? "pin.slash" : "pin") {
                togglePin(entry)
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                entries.removeAll { $0.id == entry.id }
            }
            .tint(.defaultRed)
        }
    }

    private var shown: [LighthouseHistoryEntry] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let matching = entries.filter { entry in
            (filter == .all || entry.isPinned) && (query.isEmpty || entry.title.localizedCaseInsensitiveContains(query))
        }
        switch sort {
        case .newest:
            return matching
        case .oldest:
            return matching.reversed()
        case .alphabetical:
            return matching.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    private var pinned: [LighthouseHistoryEntry] {
        shown.filter(\.isPinned)
    }

    private var others: [LighthouseHistoryEntry] {
        shown.filter { !$0.isPinned }
    }

    private func togglePin(_ entry: LighthouseHistoryEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index].isPinned.toggle()
    }

    // MARK: - Filter

    private var filterMenu: some View {
        Menu {
            Section("Show") {
                ForEach(Filter.allCases) { option in
                    Button {
                        filter = option
                    } label: {
                        Label {
                            Text(option.title)
                        } icon: {
                            if option == filter {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: option.symbol)
                            }
                        }
                    }
                }
            }
            Section("Sort") {
                ForEach(Sort.allCases) { option in
                    Button {
                        sort = option
                    } label: {
                        Label {
                            Text(option.title)
                        } icon: {
                            if option == sort {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: option.symbol)
                            }
                        }
                    }
                }
            }
        } label: {
            Label("Filter", systemImage: filter == .all ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                .labelStyle(.iconOnly)
        }
    }

    private enum Filter: CaseIterable, Identifiable {
        case all
        case pinned

        var id: Self { self }

        var title: String {
            switch self {
            case .all: "All Chats"
            case .pinned: "Pinned"
            }
        }

        var symbol: String {
            switch self {
            case .all: "bubble.left.and.bubble.right"
            case .pinned: "pin"
            }
        }
    }

    private enum Sort: CaseIterable, Identifiable {
        case newest
        case oldest
        case alphabetical

        var id: Self { self }

        var title: String {
            switch self {
            case .newest: "Newest First"
            case .oldest: "Oldest First"
            case .alphabetical: "A to Z"
            }
        }

        var symbol: String {
            switch self {
            case .newest: "arrow.down"
            case .oldest: "arrow.up"
            case .alphabetical: "textformat"
            }
        }
    }

    private enum Constants {
        static let title = "History"
        static let searchPrompt = "Search chats"
        static let pinnedTitle = "Pinned"
        static let recentTitle = "Recent"
        static let empty = "No chats"
    }
}
