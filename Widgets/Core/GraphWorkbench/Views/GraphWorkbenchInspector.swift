//
//  GraphWorkbenchInspector.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI

// The selected entity's evidence: its stats, description, where it sits in the
// community tree, and its strongest relationships, each of which jumps to the
// entity on the other end.
struct GraphWorkbenchInspector: View {
    let model: GraphWorkbenchModel
    let node: GraphNode
    let onSelect: (String) -> Void

    private var community: GraphCommunity? {
        model.community(of: node)
    }

    private var links: [GraphLink] {
        model.links(of: node.id)
    }

    var body: some View {
        BrightPageSheetView(title: "Inspector", horizontalPadding: .spacing0x, backgroundColor: .defaultBlack) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing0x) {
                    BrightDivider()
                    header
                    BrightDivider()
                    stats
                    BrightDivider()

                    GraphWorkbenchSectionLabel(title: "Description", systemImage: "doc.text")
                    BrightText(node.entity.description, size: .body4, color: .semiLightTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, .spacing3x)
                        .padding(.vertical, .spacing2x)

                    if let community {
                        GraphWorkbenchSectionLabel(title: "Community", systemImage: "arrow.triangle.branch")
                        communityTree(current: community)
                    }

                    if !links.isEmpty {
                        GraphWorkbenchSectionLabel(title: "Strongest relationships · \(links.count)", systemImage: "link")
                        relationships
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            GraphWorkbenchCaps(model.data.name)

            HStack(spacing: .spacing1x) {
                Image(systemName: node.entity.type.systemImage)
                    .font(.standard(size: .body4, weight: .medium))
                    .foregroundStyle(node.entity.color)

                BrightText(node.entity.title, size: .body1, weight: .medium)
                    .lineLimit(1)
            }

            GraphWorkbenchCaps("\(node.entity.type.title) · ID \(node.entity.humanReadableID)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .spacing3x)
        .padding(.vertical, .spacing2x)
        .background(Color.defaultWhite.opacity(.finalBossUltraLowOpacity))
    }

    private var stats: some View {
        HStack(spacing: .spacing0x) {
            stat("Links", value: "\(node.entity.degree)")
            BrightVerticalDivider()
            stat("Frequency", value: "\(node.entity.frequency)")
            BrightVerticalDivider()
            stat("Level", value: community.map { "\($0.level)" } ?? "—")
            BrightVerticalDivider()
            stat("Entities", value: community.map { "\($0.size)" } ?? "—")
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            GraphWorkbenchCaps(title)
            BrightText(value, size: .body2, weight: .regular)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .spacing2x)
        .padding(.vertical, .spacing105x)
    }

    private func communityTree(current: GraphCommunity) -> some View {
        var rows: [CommunityRow] = []
        if let parent = model.parent(of: current) {
            rows.append(CommunityRow(role: "Parent", community: parent))
        }
        rows.append(CommunityRow(role: "Current", community: current))
        rows += model.children(of: current).map { CommunityRow(role: "Child", community: $0) }

        return VStack(spacing: .spacing0x) {
            ForEach(rows) { row in
                communityRow(row, isCurrent: row.community.id == current.id)
            }
        }
    }

    private func communityRow(_ row: CommunityRow, isCurrent: Bool) -> some View {
        VStack(spacing: .spacing0x) {
            HStack(spacing: .spacing105x) {
                GraphWorkbenchCaps(row.role, color: isCurrent ? .textColor : .lightTextColor)
                    .frame(width: Constants.roleWidth, alignment: .leading)

                BrightText(row.community.title, size: .body5, weight: isCurrent ? .medium : .regular)
                    .lineLimit(1)

                Spacer(minLength: .spacing1x)

                GraphWorkbenchCaps("L\(row.community.level)")
            }
            .padding(.horizontal, .spacing3x)
            .padding(.vertical, .spacing105x)
            .background(isCurrent ? Color.defaultWhite.opacity(.finalBossLowOpacity) : .clear)

            BrightDivider()
        }
    }

    private var relationships: some View {
        let shown = Array(links.prefix(Constants.maxRelationships))
        return VStack(spacing: .spacing0x) {
            ForEach(shown) { link in
                relationshipRow(link, isLast: link.id == shown.last?.id)
            }
        }
    }

    @ViewBuilder
    private func relationshipRow(_ link: GraphLink, isLast: Bool) -> some View {
        if let other = model.node(link.other(than: node.id)) {
            Button {
                onSelect(other.id)
            } label: {
                VStack(spacing: .spacing0x) {
                    HStack(alignment: .top, spacing: .spacing2x) {
                        VStack(alignment: .leading, spacing: .spacing05x) {
                            HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                                BrightText(other.entity.title, size: .body4, color: other.entity.color, weight: .medium)
                                    .lineLimit(1)
                                GraphWorkbenchCaps(other.entity.type.title)
                            }

                            BrightText(link.relationship.description, size: .body5, color: .lightTextColor)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: .spacing1x)

                        GraphWorkbenchCaps("\(link.relationship.weight)")
                            .monospacedDigit()
                    }
                    .padding(.horizontal, .spacing3x)
                    .padding(.vertical, .spacing105x)

                    if !isLast {
                        BrightDivider()
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private struct CommunityRow: Identifiable {
        let role: String
        let community: GraphCommunity

        var id: String {
            community.id
        }
    }

    private enum Constants {
        static let maxRelationships = 8
        static let roleWidth: CGFloat = 52
    }
}
