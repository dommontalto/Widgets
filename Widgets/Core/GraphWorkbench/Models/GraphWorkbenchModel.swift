//
//  GraphWorkbenchModel.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI

@Observable
final class GraphWorkbenchModel {
    enum CommunityRole {
        case selected
        case parent
        case child
        case related
    }

    let data: GraphWorkbenchData
    let layout: GraphLayout
    var selectedID: String?
    var searchText = ""
    // The Workbench's "Isolate community" toggle.
    var isIsolating = true

    @ObservationIgnored let nodesByID: [String: GraphNode]
    @ObservationIgnored private let communitiesByID: [String: GraphCommunity]
    @ObservationIgnored private let linksByNode: [String: [GraphLink]]

    init(data: GraphWorkbenchData) {
        self.data = data
        layout = GraphForceLayout.make(from: data)
        nodesByID = Dictionary(uniqueKeysWithValues: layout.nodes.map { ($0.id, $0) })
        communitiesByID = Dictionary(uniqueKeysWithValues: data.communities.map { ($0.id, $0) })

        var linksByNode: [String: [GraphLink]] = [:]
        for link in layout.links {
            linksByNode[link.sourceID, default: []].append(link)
            linksByNode[link.targetID, default: []].append(link)
        }
        self.linksByNode = linksByNode.mapValues { $0.sorted { $0.relationship.weight > $1.relationship.weight } }
    }

    var selectedNode: GraphNode? {
        selectedID.flatMap { nodesByID[$0] }
    }

    var selectedCommunity: GraphCommunity? {
        selectedNode.flatMap(community(of:))
    }

    // nil while the search is empty; otherwise the entities whose title or
    // description contains it.
    var matchingIDs: Set<String>? {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        return Set(
            layout.nodes
                .filter { $0.entity.title.localizedStandardContains(query) || $0.entity.description.localizedStandardContains(query) }
                .map(\.id)
        )
    }

    // Selecting an entity isolates the whole tree under its top-level
    // community, as the Workbench's "auto" community mode does.
    var isolatedCommunities: [GraphCommunity] {
        guard isIsolating, var root = selectedCommunity else { return [] }
        var hops = 0
        while let parentID = root.parentID, let parent = communitiesByID[parentID], hops < Constants.maxDepth {
            root = parent
            hops += 1
        }

        var tree: [GraphCommunity] = []
        var queue = [root]
        while !queue.isEmpty {
            let community = queue.removeFirst()
            tree.append(community)
            queue += data.communities.filter { $0.parentID == community.id }
        }
        return tree.sorted { $0.level < $1.level }
    }

    var isolatedEntityIDs: Set<String>? {
        guard isIsolating, selectedID != nil else { return nil }
        return Set(isolatedCommunities.flatMap(\.entityIDs))
    }

    func community(of node: GraphNode) -> GraphCommunity? {
        node.communityID.flatMap { communitiesByID[$0] }
    }

    func parent(of community: GraphCommunity) -> GraphCommunity? {
        community.parentID.flatMap { communitiesByID[$0] }
    }

    func children(of community: GraphCommunity) -> [GraphCommunity] {
        data.communities.filter { $0.parentID == community.id }
    }

    func role(of community: GraphCommunity) -> CommunityRole {
        guard let selectedCommunity else { return .related }
        if community.id == selectedCommunity.id { return .selected }
        if community.id == selectedCommunity.parentID { return .parent }
        if community.parentID == selectedCommunity.id { return .child }
        return .related
    }

    func links(of id: String) -> [GraphLink] {
        linksByNode[id] ?? []
    }

    func node(_ id: String) -> GraphNode? {
        nodesByID[id]
    }

    private enum Constants {
        static let maxDepth = 10
    }
}

extension GraphWorkbenchModel.CommunityRole {
    var color: Color {
        switch self {
        case .selected: .defaultAmber
        case .parent: .defaultElectricBlue
        case .child: .defaultBrightGreen
        case .related: .defaultCyan
        }
    }
}
