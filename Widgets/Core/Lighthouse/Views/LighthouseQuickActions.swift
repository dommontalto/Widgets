//
//  LighthouseQuickActions.swift
//  Widgets
//

import SwiftUI

enum LighthouseQuickAction: String, CaseIterable, Identifiable {
    case voice
    case exercise
    case food
    case water
    case weight
    case barcode
    case searchMeal
    case describeMeal
    case activity
    case cycle
    case document

    var id: String { rawValue }

    static let defaults: [LighthouseQuickAction] = [.voice, .exercise, .food, .water, .weight, .searchMeal]

    var title: String {
        switch self {
        case .voice: "Voice"
        case .exercise: "Exercise"
        case .food: "Food"
        case .water: "Water"
        case .weight: "Weight"
        case .barcode: "Barcode"
        case .searchMeal: "Search"
        case .describeMeal: "Describe"
        case .activity: "Activity"
        case .cycle: "Cycle"
        case .document: "Document"
        }
    }

    var systemImage: String {
        switch self {
        case .voice: "waveform"
        case .exercise: HealthWidgetKindV5.exercise.systemImage
        case .food: HealthWidgetKindV5.nutrition.systemImage
        case .water: HealthWidgetKindV5.water.systemImage
        case .weight: HealthWidgetKindV5.weight.systemImage
        case .barcode: "barcode.viewfinder"
        case .searchMeal: "magnifyingglass"
        case .describeMeal: "text.bubble"
        case .activity: HealthWidgetKindV5.activity.systemImage
        case .cycle: HealthWidgetKindV5.menstrual.systemImage
        case .document: "doc"
        }
    }
}

// A titled row of log shortcuts along the top of the dock's Lighthouse, ending
// in Customise, scrolling sideways when they run past the screen. Customise opens
// it out into a jiggling grid: shown tiles carry a minus to take them off and
// drag to reorder; the rest wait in a grid below a divider with a plus to put
// them on; Done at the bottom closes it back to the row.
struct LighthouseQuickActions: View {
    @Binding var actions: [LighthouseQuickAction]
    var onSelect: (LighthouseQuickAction) -> Void = { _ in }

    @State private var isEditing = false
    @State private var jigglePhase = false
    @State private var dragging: Drag?
    @State private var slotFrames: [LighthouseQuickAction: CGRect] = [:]
    @Namespace private var tiles

    private let columns = Array(repeating: GridItem(spacing: .spacing2x), count: Constants.columnCount)

    private struct Drag {
        let action: LighthouseQuickAction
        var start: CGPoint
        var translation: CGSize = .zero
        var isLifted = true

        var location: CGPoint {
            CGPoint(x: start.x + translation.width, y: start.y + translation.height)
        }
    }

    private var hiddenActions: [LighthouseQuickAction] {
        LighthouseQuickAction.allCases.filter { !actions.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            header

            if isEditing {
                editingGrid
            } else {
                row
            }
        }
        .task(id: isEditing) {
            guard isEditing else {
                dragging = nil
                withAnimation(.brightEaseInOut) { jigglePhase = false }
                return
            }
            // Flips faster than the swing animation lasts, so each swing is cut off
            // mid-arc, like the home screen's jiggle.
            while !Task.isCancelled {
                try? await Task.sleep(for: Constants.jiggleInterval)
                jigglePhase.toggle()
            }
        }
    }

    private var header: some View {
        HStack {
            BrightText("Quick Actions", size: .subheading, weight: .medium)

            Spacer(minLength: .spacing2x)
        }
        .padding(.horizontal, .spacing3x)
    }

    private var row: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: .spacing2x) {
                ForEach(Array(actions.enumerated()), id: \.element) { index, action in
                    tile(action, seed: index, isShown: true)
                        .frame(width: Constants.tileWidth)
                        .matchedGeometryEffect(id: action, in: tiles)
                }

                LighthouseQuickActionTile(title: "Customise") {
                    BrightHaptic.medium.play()
                    withAnimation(.brightSpring) { isEditing = true }
                } icon: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.standard(size: .heading, weight: .regular))
                }
                .frame(width: Constants.tileWidth)
                .transition(.scale.combined(with: .opacity))
            }
            .padding(.horizontal, .spacing3x)
            // Room for a pressed tile to swell without being clipped.
            .padding(.vertical, .spacing1x)
        }
        .scrollIndicators(.hidden)
    }

    // Opened out into a grid rather than a row, so nothing needs scrolling while
    // the tiles jiggle and drag: what's on above, what's left to add below.
    private var editingGrid: some View {
        VStack(spacing: .spacing3x) {
            LazyVGrid(columns: columns, spacing: .spacing2x) {
                ForEach(Array(actions.enumerated()), id: \.element) { index, action in
                    tile(action, seed: index, isShown: true)
                        .matchedGeometryEffect(id: action, in: tiles)
                        // The slot stays put but empty; the lifted copy above follows the finger.
                        .opacity(dragging?.action == action ? .zero : .opaque)
                        .onGeometryChange(for: CGRect.self) {
                            $0.frame(in: .named(Constants.space))
                        } action: {
                            slotFrames[action] = $0
                        }
                        .highPriorityGesture(reorderGesture(for: action))
                }
            }
            .coordinateSpace(.named(Constants.space))
            .overlay(alignment: .topLeading) {
                if let dragging, let frame = slotFrames[dragging.action] {
                    liftedTile(dragging, size: frame.size)
                }
            }

            if !hiddenActions.isEmpty {
                BrightDividerV5()
                    .transition(.opacity)

                LazyVGrid(columns: columns, spacing: .spacing2x) {
                    ForEach(Array(hiddenActions.enumerated()), id: \.element) { index, action in
                        tile(action, seed: actions.count + index, isShown: false)
                            .matchedGeometryEffect(id: action, in: tiles)
                    }
                }
                .transition(.opacity)
            }

            BrightPillButton("Done") {
                BrightHaptic.light.play()
                withAnimation(.brightSpring) { isEditing = false }
            }
        }
        .padding(.horizontal, .spacing3x)
        .padding(.vertical, .spacing1x)
        .transition(.opacity)
    }

    private func tile(_ action: LighthouseQuickAction, seed: Int, isShown: Bool) -> some View {
        LighthouseQuickActionTile(title: action.title) {
            if isEditing {
                toggle(action)
            } else {
                onSelect(action)
            }
        } icon: {
            Image(systemName: action.systemImage)
                .font(.standard(size: .heading, weight: .regular))
        }
        .overlay(alignment: .topTrailing) {
            if isEditing {
                BrightRoundButton(
                    systemImage: isShown ? "minus" : "plus",
                    size: .extraSmall,
                    haptic: nil
                ) {
                    toggle(action)
                }
                .offset(x: .spacing05x, y: -.spacing05x)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .modifier(BrightJiggleV5(isEnabled: isEditing, phase: jigglePhase, seed: seed))
        .animation(.brightJigglePhase, value: jigglePhase)
    }

    private func liftedTile(_ drag: Drag, size: CGSize) -> some View {
        tile(drag.action, seed: actions.firstIndex(of: drag.action) ?? .zero, isShown: true)
            .frame(width: size.width, height: size.height)
            .scaleEffect(drag.isLifted ? Constants.liftedScale : 1)
            .shadow(color: .black.opacity(drag.isLifted ? .veryLowOpacity : .zero), radius: Constants.liftedShadowRadius)
            .position(drag.location)
            .allowsHitTesting(false)
    }

    // Nothing scrolls in the grid, so a drag lifts the tile straight away, as on
    // the home grid; a tap still adds or removes it.
    private func reorderGesture(for action: LighthouseQuickAction) -> some Gesture {
        DragGesture(minimumDistance: Constants.dragMinimumDistance, coordinateSpace: .named(Constants.space))
            .onChanged { value in
                dragChanged(value.translation, action: action)
            }
            .onEnded { _ in
                dragEnded(action: action)
            }
    }

    private func dragChanged(_ translation: CGSize, action: LighthouseQuickAction) {
        if dragging?.action != action {
            guard let frame = slotFrames[action] else { return }
            BrightHaptic.medium.play()
            withAnimation(.brightSpring) {
                dragging = Drag(action: action, start: CGPoint(x: frame.midX, y: frame.midY))
            }
        }
        dragging?.translation = translation

        guard let location = dragging?.location,
              let target = actions.first(where: { $0 != action && slotFrames[$0]?.contains(location) == true }),
              let from = actions.firstIndex(of: action),
              let to = actions.firstIndex(of: target) else { return }
        BrightHaptic.light.play()
        withAnimation(.brightSpring) {
            actions.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    // Springs the lifted copy into its slot, then hands back to the real tile.
    private func dragEnded(action: LighthouseQuickAction) {
        guard let drag = dragging, drag.action == action, let landing = slotFrames[action] else {
            dragging = nil
            return
        }
        let current = drag.location
        var landed = Drag(action: action, start: CGPoint(x: landing.midX, y: landing.midY))
        landed.translation = CGSize(width: current.x - landed.start.x, height: current.y - landed.start.y)
        dragging = landed

        withAnimation(.brightSpring) {
            dragging?.translation = .zero
            dragging?.isLifted = false
        } completion: {
            guard dragging?.action == action, dragging?.isLifted == false else { return }
            dragging = nil
        }
    }

    private func toggle(_ action: LighthouseQuickAction) {
        BrightHaptic.light.play()
        withAnimation(.brightSpring) {
            if let index = actions.firstIndex(of: action) {
                actions.remove(at: index)
            } else {
                actions.append(action)
            }
        }
    }

    private enum Constants {
        static let tileWidth: CGFloat = .spacing12x
        static let columnCount = 4
        static let jiggleInterval: Duration = .milliseconds(130)
        static let space = "lighthouseQuickActions"
        static let dragMinimumDistance: CGFloat = 5
        static let liftedScale: CGFloat = 1.05
        static let liftedShadowRadius: CGFloat = 10
    }
}

private struct LighthouseQuickActionTile<Icon: View>: View {
    let title: String
    let action: () -> Void
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        VStack(spacing: .spacing1x) {
            Button(action: action) {
                icon()
                    .foregroundStyle(Color.textColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: LighthouseQuickActionTileStyle.tileHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(LighthouseQuickActionTileStyle())

            BrightText(title, size: .body5)
                .lineLimit(1)
        }
    }
}

private struct LighthouseQuickActionTileStyle: ButtonStyle {
    static let tileHeight: CGFloat = .spacing8x
    private static let pressedScale: CGFloat = 1.12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                ZStack {
                    Color.textColor.opacity(.finalBossLowOpacity)

                    RadialGradient(
                        colors: [Color.textColor.opacity(.veryLowOpacity), .clear],
                        center: .center,
                        startRadius: .zero,
                        endRadius: Self.tileHeight
                    )
                    .opacity(configuration.isPressed ? .opaque : .zero)
                    .animation(.brightEaseInOut, value: configuration.isPressed)
                }
                .clipShape(.rect(cornerRadius: .squareCornerRadius))
            }
            .scaleEffect(configuration.isPressed ? Self.pressedScale : 1)
            .animation(.brightLiquid, value: configuration.isPressed)
            .brightHapticV5(.light, trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

#Preview {
    @Previewable @State var actions = LighthouseQuickAction.defaults
    LighthouseQuickActions(actions: $actions)
}
