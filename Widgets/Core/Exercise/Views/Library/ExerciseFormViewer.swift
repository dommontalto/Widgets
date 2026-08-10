//
//  ExerciseFormViewer.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import RealityKit
import SwiftUI

struct ExerciseFormViewer: View {
    var cardColor: Color = .defaultSheetModalCards

    // The pushed page gets orbit controls and larger playback buttons.
    var isFullScreen = false

    // Set on the card to show the open button; nil on the pushed page.
    var onOpen: (() -> Void)?

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
            .realityViewCameraControls(isFullScreen ? .orbit : .none)

            VStack(spacing: .spacing2x) {
                Spacer()

                controls

                scrubber
            }
        }
        .frame(maxWidth: .infinity, maxHeight: isFullScreen ? .infinity : nil)
        .frame(height: isFullScreen ? nil : Constants.cardHeight)
        .background(cardColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: isFullScreen ? .spacing0x : .cardCornerRadius,
                style: .continuous
            )
        )
        .ignoresSafeArea(.container, edges: isFullScreen ? .bottom : [])
        .overlay(alignment: .topTrailing) {
            if let onOpen {
                BrightRoundButton(
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    size: .medium,
                    onTapCallback: onOpen
                )
                .padding(.spacing4x)
            }
        }
        .task {
            while !Task.isCancelled {
                if let controller, !isScrubbing, duration > 0 {
                    progress = min(1, controller.time.truncatingRemainder(dividingBy: duration) / duration)
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    // MARK: - Controls

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

    private var scrubber: some View {
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
        .padding(.bottom, isFullScreen ? .spacing6x : .spacing3x)
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

    private var controlSize: BrightButtonSizes {
        isFullScreen ? .large : .medium
    }

    // MARK: - Model

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
        static let cardHeight: CGFloat = 440
        static let standingHeight: Float = 1.5
        static let targetHeight: Float = 0.5
        static let cameraDistance: Float = 0.9
        static let figureLift: Float = 0.06
    }
}

#Preview {
    ExerciseFormViewer {}
        .padding(.spacing4x)
}

#Preview("Full screen") {
    ExerciseFormViewer(isFullScreen: true)
}
