//
//  ExerciseDiscClick.swift
//  Widgets
//
//  Created by Dom Montalto on 18/8/2026.
//

import AVFoundation

// The click the record notches over with: the same tock the system's picker
// wheels use, but played through an engine of ours rather than as a system sound,
// so it has a volume we set and still sounds with the mute switch on. Falls back
// to a synthesised tick if the file can't be read.
@MainActor
enum ExerciseDiscClick {
    private static let voice = Voice()
    private static var engine: AVAudioEngine?
    private static var player: AVAudioPlayerNode?
    private static var tock: AVAudioPCMBuffer?
    private static var stopTask: Task<Void, Never>?

    static func play() {
        start()

        if let player, let tock {
            // Interrupts rather than queues: a fast turn should click over the
            // last one, not stack up a run of them to play out afterwards.
            player.scheduleBuffer(tock, at: nil, options: .interrupts)
            if !player.isPlaying { player.play() }
        } else {
            voice.strike()
        }
    }

    private static func start() {
        stopTask?.cancel()
        stopTask = Task {
            try? await Task.sleep(for: .seconds(Constants.idleStop))
            guard !Task.isCancelled else { return }
            Self.engine?.stop()
            Self.engine = nil
            Self.player = nil
        }

        if let engine {
            if !engine.isRunning { try? engine.start() }
            return
        }

        // Playback rather than ambient, so a click still sounds with the ringer
        // off, and mixed so it sits over whatever the user is training to.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        let engine = AVAudioEngine()
        engine.mainMixerNode.outputVolume = Constants.volume

        if let tock = Self.tock ?? loadTock() {
            Self.tock = tock

            // Played faster than it was recorded, which lifts the tock's pitch
            // and shortens it — the system's own is too low and too blunt for
            // two dozen of them a turn.
            let speed = AVAudioUnitVarispeed()
            speed.rate = Constants.clickRate

            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.attach(speed)
            engine.connect(player, to: speed, format: tock.format)
            engine.connect(speed, to: engine.mainMixerNode, format: tock.format)
            Self.player = player
        } else {
            attachVoice(to: engine)
        }

        guard (try? engine.start()) != nil else { return }
        Self.engine = engine
    }

    private static func loadTock() -> AVAudioPCMBuffer? {
        guard let file = try? AVAudioFile(forReading: Constants.tockPath),
              let buffer = AVAudioPCMBuffer(
                  pcmFormat: file.processingFormat,
                  frameCapacity: AVAudioFrameCount(file.length)
              ),
              (try? file.read(into: buffer)) != nil else { return nil }
        return buffer
    }

    // MARK: - Fallback

    private static func attachVoice(to engine: AVAudioEngine) {
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

        voice.sampleRate = sampleRate

        let source = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let sample = voice.nextSample()
                for buffer in buffers {
                    UnsafeMutableBufferPointer<Float>(buffer)[frame] = sample
                }
            }
            return noErr
        }

        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
    }

    // Struck from the main actor and read on the audio thread. All that crosses
    // is the restart flag, and the worst a torn read can do is start the click
    // one sample late.
    private final class Voice: @unchecked Sendable {
        var sampleRate: Double = 48_000

        private var restart = false
        // Past the click's length, so nothing sounds until the first strike.
        private var sample: Int = .max

        func strike() {
            restart = true
        }

        func nextSample() -> Float {
            if restart {
                restart = false
                sample = 0
            }

            let length = Int(sampleRate * Constants.clickSeconds)
            guard sample < length else { return 0 }

            let progress = Double(sample) / Double(length)
            let decay = pow(1 - progress, Constants.decayCurve)
            let tone = sin(2 * .pi * Constants.pitch * Double(sample) / sampleRate)

            sample += 1
            return Float(tone * decay * Constants.amplitude)
        }
    }

    private enum Constants {
        static let tockPath = URL(fileURLWithPath: "/System/Library/Audio/UISounds/Tock.caf")
        static let clickRate: Float = 3
        static let volume: Float = 1
        static let idleStop: TimeInterval = 2
        static let clickSeconds: Double = 0.008
        static let pitch: Double = 3_200
        static let decayCurve: Double = 4
        static let amplitude: Double = 0.9
    }
}
