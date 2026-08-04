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
    @Binding var isExpanded: Bool
    let expandedHeight: CGFloat

    @State private var controller: AnimationPlaybackController?
    @State private var duration: TimeInterval = 1
    @State private var progress: Double = 0
    @State private var isScrubbing = false
    @State private var playbackSpeed: Double = 1
    @State private var isPaused = false

    var body: some View {
        ZStack {
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
            .realityViewCameraControls(isExpanded ? .orbit : .none)

            VStack(spacing: .spacing2x) {
                Spacer()

                controls

                Slider(value: $progress) { editing in
                    isScrubbing = editing
                    if editing {
                        controller?.pause()
                    } else if !isPaused {
                        controller?.resume()
                    }
                }
                .tint(Color.defaultSkyBlue)
                .onChange(of: progress) {
                    if isScrubbing {
                        controller?.time = min(progress * duration, duration - 0.01)
                    }
                }
                .padding(.horizontal, .spacing4x)
                .padding(.bottom, .spacing3x)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: isExpanded ? expandedHeight : Constants.viewerHeight)
        .background(Color.defaultSheetModalCards)
        .clipShape(
            RoundedRectangle(
                cornerRadius: isExpanded ? .spacing0x : .cardCornerRadius,
                style: .continuous
            )
        )
        .overlay(alignment: .topTrailing) {
            BrightRoundButton(
                systemImage: isExpanded
                    ? "arrow.down.right.and.arrow.up.left"
                    : "arrow.up.left.and.arrow.down.right",
                size: isExpanded ? .large : .medium,
                onTapCallback: toggleExpansion
            )
            .padding(.top, isExpanded ? .spacing3x : .spacing4x)
            .padding(.trailing, isExpanded ? .spacing3x : .spacing4x)
        }
        .padding(.horizontal, isExpanded ? -CGFloat.spacing3x : .spacing0x)
        .ignoresSafeArea(.container, edges: isExpanded ? Edge.Set.bottom : [])
        .contentShape(.rect)
        .onTapGesture { if !isExpanded { toggleExpansion() } }
        .task {
            while !Task.isCancelled {
                if let controller, !isScrubbing, duration > 0 {
                    progress = min(1, controller.time.truncatingRemainder(dividingBy: duration) / duration)
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func toggleExpansion() {
        BrightHaptic.medium.play()

        withAnimation(.brightEaseInOut) {
            isExpanded.toggle()
        }
    }

    private var controls: some View {
        HStack(spacing: .spacing1x) {
            ForEach(Constants.speeds, id: \.self) { speed in
                speedButton(speed)
            }

            Spacer()

            BrightRoundButton(systemImage: isPaused ? "play" : "pause", size: controlSize) {
                isPaused.toggle()
                if isPaused {
                    controller?.pause()
                } else {
                    controller?.resume()
                }
            }
        }
        .padding(.horizontal, .spacing4x)
        .brightHaptic(.light, trigger: playbackSpeed)
        .brightHaptic(.light, trigger: isPaused)
    }

    private var controlSize: BrightButtonSizes {
        isExpanded ? .large : .medium
    }

    private func speedButton(_ speed: Double) -> some View {
        BrightRoundButton(
            title: speedLabel(speed),
            size: controlSize,
            color: playbackSpeed == speed ? .defaultBrightGreen : nil
        ) {
            playbackSpeed = speed
            controller?.speed = Float(speed)
        }
    }

    private func speedLabel(_ speed: Double) -> String {
        speed == 1 ? "1" : String(String(speed).dropFirst())
    }

    private func makeCamera() -> PerspectiveCamera {
        let camera = PerspectiveCamera()
        camera.position = [0, 0, Constants.cameraDistance]
        return camera
    }

    private func fit(_ entity: Entity) {
        let scale = Constants.targetHeight / Constants.standingHeight
        entity.scale *= SIMD3<Float>(repeating: scale)
        entity.position = [0, -Constants.targetHeight / 2 + Constants.figureLift, 0]
    }

    private enum Constants {
        static let speeds: [Double] = [1, 0.5, 0.25]
        static let modelName = "14_Squat_Looping_color"
        static let viewerHeight: CGFloat = 440
        static let standingHeight: Float = 1.5
        static let targetHeight: Float = 0.5
        static let cameraDistance: Float = 0.9
        static let figureLift: Float = 0.06
    }
}

#Preview {
    ExerciseFormViewer(isExpanded: .constant(false), expandedHeight: 800)
        .padding(.spacing4x)
}
