//
//  BrightToastV5.swift
//  Widgets
//
//  Created by Dom Montalto on 2/10/2026.
//

import SwiftUI

enum BrightSyncPhase: Equatable {
    case syncing
    case synced
}

extension View {
    // Drops a pill out of the Dynamic Island while `phase` is set. Setting
    // `.synced` turns it green with a tick; it then clears `phase` itself
    // and melts back into the island.
    func brightToastV5(_ phase: Binding<BrightSyncPhase?>) -> some View {
        overlay(alignment: .top) {
            BrightToastV5(phase: phase)
        }
    }
}

private struct BrightToastV5: View {
    @Binding var phase: BrightSyncPhase?

    @Environment(\.scenePhase) private var scenePhase
    // Lags `phase` on the way out so the pill keeps its look while it retracts.
    @State private var shown: BrightSyncPhase?
    @State private var progress: CGFloat = 0
    // The threshold shader is only needed while the pill is joined to the
    // island; once it has dropped clear, it would just alias the edges.
    @State private var isSettled = false
    @State private var isExpanded = false
    @State private var labelWidth: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if shown != nil {
                    island(safeArea: proxy.safeAreaInsets)
                }
            }
            .ignoresSafeArea()
        }
        // A sliver at the top so the reader picks up the top safe area
        // without taking any space from the screen beneath.
        .frame(height: 1)
        .allowsHitTesting(false)
        .onChange(of: phase) { _, new in
            update(to: new)
        }
    }

    private func island(safeArea: EdgeInsets) -> some View {
        let hasIsland = safeArea.top >= Constants.islandSafeAreaMin
        // Without an island the pill drops from just above the screen edge.
        let drop = hasIsland ? Constants.dropDistance : safeArea.top + Constants.dropDistance
        let offset = drop * progress

        return Rectangle()
            .fill(.clear)
            .frame(height: hasIsland ? safeArea.top : 0)
            .overlay(alignment: hasIsland ? .center : .top) {
                Capsule()
                    .fill(Color.defaultBlack)
                    // Slightly smaller than the real island, so it never bleeds past it.
                    .frame(width: Constants.islandWidth, height: Constants.islandHeight)
                    .opacity(scenePhase == .active ? 1 : 0)
                    .mask {
                        Capsule()
                            .padding(.top, Constants.islandInset)
                    }
                    .overlay(alignment: .bottom) {
                        pill
                            .scaleEffect(pillScale, anchor: .bottom)
                            .offset(y: offset)
                    }
                    .compositingGroup()
                    .blur(radius: Constants.blurRadius * (1 - progress))
                    .visualEffect { [isSettled] content, proxy in
                        content.layerEffect(
                            ShaderLibrary.brightAlphaThreshold(.float(Constants.alphaThreshold)),
                            maxSampleOffset: proxy.size,
                            isEnabled: !isSettled
                        )
                    }
                    .overlay(alignment: .bottom) {
                        pillLabel
                            .scaleEffect(pillScale, anchor: .bottom)
                            .offset(y: offset)
                    }
                    .offset(y: hasIsland ? 0 : -Constants.islandHeight)
            }
    }

    // The gooey drip, sized from the label laid over it so the two always
    // match. Glass can't go through the threshold shader, so the glass ball
    // rides on top and this only draws the neck, thinning away as it drops.
    private var pill: some View {
        Capsule()
            .fill(Color.defaultBlack)
            .frame(width: pillWidth, height: Constants.pillHeight)
            .opacity(isSettled ? 0 : 1 - progress)
    }

    // Starts about island height, so the ball doesn't poke out above it.
    private var pillScale: CGFloat {
        Constants.pillStartScale + (1 - Constants.pillStartScale) * progress
    }

    private var pillLabel: some View {
        pillContent
            // Measured after layout, outside the text's own transaction, so the
            // spring has to be applied here for the pill to bounce to its new width.
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
                withAnimation(.brightBouncy) { labelWidth = width }
            }
            .frame(width: pillWidth, height: Constants.pillHeight)
            .clipShape(.capsule)
            .opacity(isExpanded ? 1 : 0)
            // Behind the island until it drops, so the ball is glass the whole way down.
            .background {
                Capsule()
                    .fill(.clear)
                    .modifier(BrightGlassEffectV5(shape: .capsule, tint: .toastGlassTint, interactive: false))
            }
    }

    private var pillContent: some View {
        HStack(spacing: .spacing1x) {
            // The tick stays mounted under the orb so flipping it plays its
            // own symbol replace and success haptic.
            ZStack {
                BrightTickV5(isTicked: isSynced)
                    .opacity(isSynced ? .opaque : .zero)
                BrightSolvingOrbV5(size: Constants.orbSize)
                    .scaleEffect(isSynced ? Constants.orbExitScale : 1)
                    .opacity(isSynced ? .zero : .opaque)
            }

            BrightText(isSynced ? "Synced" : "Syncing…", size: .subheading, color: isSynced ? .defaultGreen : .defaultWhite, weight: .regular)
                .contentTransition(.numericText())
                .brightShimmerV5(isActive: shown == .syncing)
        }
        .fixedSize()
        .padding(.leading, .spacing105x)
        .padding(.trailing, .spacing2x)
    }

    private var isSynced: Bool {
        shown == .synced
    }

    private var pillWidth: CGFloat {
        isExpanded ? labelWidth : Constants.pillHeight
    }

    private func update(to new: BrightSyncPhase?) {
        switch new {
        case let new?:
            if shown == nil {
                shown = new
                dropOut()
            } else {
                withAnimation(.brightBouncy) { shown = new }
            }
            if new == .synced {
                Task {
                    try? await Task.sleep(for: Constants.syncedHold)
                    if phase == .synced { phase = nil }
                }
            }
        case nil:
            withAnimation(.brightSnappy) {
                isExpanded = false
            } completion: {
                isSettled = false
                withAnimation(Constants.retract) {
                    progress = 0
                } completion: {
                    if phase == nil { shown = nil }
                }
            }
        }
    }

    private func dropOut() {
        isSettled = false
        withAnimation(Constants.drop) {
            progress = 1
        } completion: {
            guard phase != nil else { return }
            isSettled = true
            withAnimation(.brightBouncy) { isExpanded = true }
        }
    }
}

private enum Constants {
    // iPhone Air tops out at 68, and every island phone is at least 59.
    static let islandSafeAreaMin: CGFloat = 59
    static let islandWidth: CGFloat = 100
    static let islandHeight: CGFloat = 33
    static let islandInset: CGFloat = 5
    static let pillHeight: CGFloat = 48
    static let orbSize: CGFloat = 28
    static let orbExitScale: CGFloat = 0.6
    static let pillStartScale: CGFloat = 0.7
    static let dropDistance: CGFloat = 60
    static let blurRadius: CGFloat = 25
    static let alphaThreshold: Float = 0.5
    static let syncedHold: Duration = .seconds(1.4)
    static let drop: Animation = .smooth(duration: 0.45)
    static let retract: Animation = .smooth(duration: 0.4)
}

#Preview {
    @Previewable @State var phase: BrightSyncPhase?

    Color.defaultBackground
        .ignoresSafeArea()
        .brightToastV5($phase)
        .onTapGesture {
            phase = .syncing
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                phase = .synced
            }
        }
}
