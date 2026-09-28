//
//  GraphWorkbenchLabels.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI

// Entity and community names, drawn in SwiftUI over the scene at each
// point's projected position. It reads the camera, so it redraws every frame
// the view moves. Far labels draw first, so near ones sit on top.
struct GraphWorkbenchLabels: View {
    let model: GraphWorkbenchModel
    let camera: GraphWorkbenchCamera

    private struct Caption: Identifiable {
        let id: String
        let title: String
        let subtitle: String?
        let color: Color
        let point: CGPoint
        let depth: Float
        let isCommunity: Bool
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(captions) { caption in
                VStack(spacing: .spacing0x) {
                    BrightText(
                        caption.title,
                        size: caption.isCommunity ? .body4 : .body5,
                        color: caption.color,
                        weight: caption.isCommunity ? .medium : .regular
                    )
                    .lineLimit(1)

                    if let subtitle = caption.subtitle {
                        BrightText(subtitle, size: .body6, color: .lightTextColor, weight: .regular)
                            .monospacedDigit()
                    }
                }
                .fixedSize()
                .shadow(color: caption.color.opacity(.lowOpacity), radius: Constants.glowRadius)
                .position(caption.point)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var captions: [Caption] {
        (nodeCaptions + communityCaptions).sorted { $0.depth > $1.depth }
    }

    private var nodeCaptions: [Caption] {
        let matches = model.matchingIDs
        let isolated = model.isolatedEntityIDs
        let selectedID = model.selectedID
        let neighbours: Set<String> = selectedID.map { id in
            Set(model.links(of: id).map { $0.other(than: id) })
        } ?? []

        return model.layout.nodes.compactMap { node in
            guard matches?.contains(node.id) ?? true,
                  isolated?.contains(node.id) ?? true,
                  let projected = camera.project(node.position) else { return nil }

            let isSelected = node.id == selectedID
            let isEmphasised = isSelected || neighbours.contains(node.id) || matches != nil
            let grow = isSelected ? GraphWorkbenchScene.selectedScale : 1
            let radius = camera.scale(atDepth: projected.depth) * CGFloat(node.radius * GraphWorkbenchScene.nodeScale * grow)
            // Distant, unremarkable entities stay unlabelled until zoomed in on.
            guard isEmphasised || radius >= Constants.labelRadius else { return nil }

            let title = node.entity.title
            return Caption(
                id: node.id,
                title: title.count > Constants.maxTitleLength ? "\(title.prefix(Constants.maxTitleLength))…" : title,
                subtitle: nil,
                color: isEmphasised ? .textColor : .semiLightTextColor,
                point: CGPoint(x: projected.point.x, y: projected.point.y - radius - Constants.labelGap),
                depth: projected.depth,
                isCommunity: false
            )
        }
    }

    private var communityCaptions: [Caption] {
        model.isolatedCommunities.compactMap { community in
            guard let bounds = model.layout.communityBounds[community.id] else { return nil }
            let top = bounds.center + SIMD3(0, bounds.size.y / 2 + Constants.communityLift, 0)
            guard let projected = camera.project(top) else { return nil }
            return Caption(
                id: "community-\(community.id)",
                title: "\(community.levelTitle): \(community.title)",
                subtitle: "\(community.size) entities",
                color: model.role(of: community).color,
                point: projected.point,
                depth: projected.depth,
                isCommunity: true
            )
        }
    }

    private enum Constants {
        static let labelRadius: CGFloat = 3
        static let labelGap: CGFloat = 6
        static let glowRadius: CGFloat = 4
        static let maxTitleLength = 25
        static let communityLift: Float = 8
    }
}
