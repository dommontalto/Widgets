//
//  ExerciseFormViewer.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import RealityKit
import SwiftUI

struct ExerciseFormViewer: View {
    var tint: Color = .defaultPurple

    @State private var controller: AnimationPlaybackController?
    @State private var duration: TimeInterval = 1
    @State private var progress: Double = 0
    @State private var isScrubbing = false

    var body: some View {
        VStack(spacing: .spacing2x) {
            RealityView { content in
                content.camera = .virtual
                if let entity = try? await Entity(named: Constants.modelName) {
                    fit(entity)
                    content.add(entity)
                    content.add(makeCamera())
                    if let animation = entity.availableAnimations.first {
                        duration = animation.definition.duration
                        controller = entity.playAnimation(animation.repeat())
                        controller?.time = 0
                    }
                }
            }
            .realityViewCameraControls(.orbit)
            .frame(height: Constants.viewerHeight)

            Slider(value: $progress) { editing in
                isScrubbing = editing
                if editing {
                    controller?.pause()
                } else {
                    controller?.resume()
                }
            }
            .tint(tint)
            .onChange(of: progress) {
                if isScrubbing {
                    controller?.time = min(progress * duration, duration - 0.01)
                }
            }
            .padding(.horizontal, .spacing2x)
            .padding(.bottom, .spacing1x)
        }
        .task {
            while !Task.isCancelled {
                if let controller, !isScrubbing {
                    if controller.time >= duration - 0.15 {
                        controller.pause()
                        controller.time = duration - 0.01
                        progress = 1
                    } else {
                        progress = controller.time / duration
                    }
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func makeCamera() -> PerspectiveCamera {
        let camera = PerspectiveCamera()
        camera.position = [0, 0, 0.75]
        return camera
    }

    private func fit(_ entity: Entity) {
        let scale = Constants.targetHeight / Constants.standingHeight
        entity.scale *= SIMD3<Float>(repeating: scale)
        entity.position = [0, -Constants.targetHeight / 2, 0]
    }

    private enum Constants {
        static let modelName = "14_Squat_Looping_color"
        static let viewerHeight: CGFloat = 260
        static let standingHeight: Float = 1.5
        static let targetHeight: Float = 0.5
    }
}

#Preview {
    ExerciseFormViewer()
        .padding(.spacing4x)
}
