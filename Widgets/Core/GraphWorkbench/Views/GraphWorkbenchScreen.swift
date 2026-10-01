//
//  GraphWorkbenchScreen.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import RealityKit
import SwiftUI

// A native take on GraphRAG Workbench's constellation: drag to orbit, pinch to
// zoom, tap an entity to isolate its community tree and inspect it.
struct GraphWorkbenchScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model: GraphWorkbenchModel
    @State private var camera: GraphWorkbenchCamera
    @State private var scene: GraphWorkbenchScene
    @State private var lastDrag: CGSize = .zero
    @State private var showsLabels = false
    // Outlives the selection, so the sheet keeps its content while it slides away.
    @State private var inspectedID: String?

    init(data: GraphWorkbenchData = GraphWorkbenchDemo.data) {
        let model = GraphWorkbenchModel(data: data)
        let camera = GraphWorkbenchCamera(layout: model.layout)
        _model = State(initialValue: model)
        _camera = State(initialValue: camera)
        _scene = State(initialValue: GraphWorkbenchScene(layout: model.layout, fieldOfView: camera.fieldOfView))
    }

    var body: some View {
        ZStack {
            RealityView { content in
                content.add(scene.root)
                scene.apply(model)
                scene.subscription = content.subscribe(to: SceneEvents.Update.self) { [scene, camera] event in
                    scene.step(deltaTime: Float(event.deltaTime), camera: camera)
                }
            }

            GraphWorkbenchLabels(model: model, camera: camera)
                .opacity(showsLabels ? 1 : 0)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            camera.viewSize = size
        }
        .contentShape(Rectangle())
        .gesture(orbitGesture)
        .simultaneousGesture(zoomGesture)
        .onTapGesture { location in
            select(at: location)
        }
        .overlay(alignment: .top) {
            header
        }
        .overlay(alignment: .bottom) {
            status
        }
        .background(Color.defaultBlack.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onChange(of: model.selectedID) {
            scene.apply(model)
        }
        .onChange(of: model.searchText) {
            scene.apply(model)
        }
        .onChange(of: model.isIsolating) {
            scene.apply(model)
        }
        .brightHapticV5(.light, trigger: model.selectedID)
        .sheet(isPresented: isInspecting) {
            if let node = inspectedID.flatMap(model.node) {
                GraphWorkbenchInspector(model: model, node: node, onSelect: select)
                    .presentationDetents([.fraction(Constants.inspectorFraction), .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(Constants.inspectorFraction)))
                    .preferredColorScheme(.dark)
            }
        }
        .task {
            try? await Task.sleep(for: Constants.labelDelay)
            withAnimation(.brightEaseInOut) { showsLabels = true }
        }
    }

    private var header: some View {
        HStack(spacing: .spacing1x) {
            GraphWorkbenchButton(systemImage: "xmark") {
                dismiss()
            }

            HStack(spacing: .spacing1x) {
                Image(systemName: "magnifyingglass")
                    .font(.standard(size: .body5, weight: .medium))
                    .foregroundStyle(Color.lightTextColor)

                TextField("Search entities…", text: $model.searchText)
                    .font(.standard(size: .body5, weight: .regular))
                    .foregroundStyle(Color.textColor)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)

                if !model.searchText.isEmpty {
                    Button {
                        model.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.standard(size: .body5, weight: .medium))
                            .foregroundStyle(Color.lightTextColor)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, .spacing105x)
            .frame(maxWidth: .infinity, minHeight: Constants.controlHeight)
            .modifier(GraphWorkbenchPanel())

            GraphWorkbenchButton("Isolate", systemImage: "eye", isActive: model.isIsolating) {
                model.isIsolating.toggle()
            }

            GraphWorkbenchButton(systemImage: "scope") {
                deselect()
            }
        }
        .padding(.horizontal, .spacing2x)
    }

    // The Workbench's bottom status chip: the build-up, then the graph's size
    // or the search's hit count.
    private var status: some View {
        HStack(spacing: .spacing1x) {
            if showsLabels {
                GraphWorkbenchCaps(statusText)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            } else {
                ProgressView()
                    .controlSize(.mini)
                    .tint(Color.defaultAmber)
                GraphWorkbenchCaps("Building graph · \(model.data.entities.count) entities")
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, .spacing2x)
        .padding(.vertical, .spacing1x)
        .modifier(GraphWorkbenchPanel())
        .padding(.bottom, .spacing1x)
        .allowsHitTesting(false)
        .animation(.brightSnappy, value: statusText)
    }

    private var statusText: String {
        if let matches = model.matchingIDs {
            return matches.count == 1 ? "1 match" : "\(matches.count) matches"
        }
        return "\(model.data.name) · \(model.data.entities.count) entities · \(model.data.relationships.count) links"
    }

    private var isInspecting: Binding<Bool> {
        Binding {
            model.selectedID != nil
        } set: { isPresented in
            if !isPresented { deselect() }
        }
    }

    private var orbitGesture: some Gesture {
        DragGesture(minimumDistance: Constants.dragThreshold)
            .onChanged { value in
                camera.orbit(by: CGSize(
                    width: value.translation.width - lastDrag.width,
                    height: value.translation.height - lastDrag.height
                ))
                lastDrag = value.translation
            }
            .onEnded { _ in
                lastDrag = .zero
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                camera.zoom(by: value.magnification)
            }
            .onEnded { _ in
                camera.endZoom()
            }
    }

    // Picks the nearest-to-camera entity under the finger, with a minimum
    // target so small, distant nodes are still easy to hit.
    private func select(at location: CGPoint) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let matches = model.matchingIDs
        let hit = model.layout.nodes
            .filter { matches?.contains($0.id) ?? true }
            .compactMap { node -> (id: String, depth: Float)? in
                guard let projected = camera.project(node.position) else { return nil }
                let radius = camera.scale(atDepth: projected.depth) * CGFloat(node.radius * GraphWorkbenchScene.nodeScale)
                let distance = hypot(projected.point.x - location.x, projected.point.y - location.y)
                return distance <= max(radius, Constants.minimumTapRadius) ? (node.id, projected.depth) : nil
            }
            .min { $0.depth < $1.depth }

        if let hit {
            select(hit.id)
        } else {
            deselect()
        }
    }

    private func select(_ id: String) {
        guard let node = model.node(id) else { return }
        model.selectedID = id
        inspectedID = id
        camera.focus(on: node.position)
    }

    private func deselect() {
        model.selectedID = nil
        camera.recenter()
    }

    private enum Constants {
        static let inspectorFraction: CGFloat = 0.4
        static let dragThreshold: CGFloat = 6
        static let minimumTapRadius: CGFloat = 22
        static let controlHeight: CGFloat = 36
        static let labelDelay: Duration = .seconds(1.2)
    }
}

#Preview {
    GraphWorkbenchScreen()
}
