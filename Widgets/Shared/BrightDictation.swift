//
//  BrightDictation.swift
//  Widgets
//
//  Created by Dom Montalto on 14/9/2026.
//

import AVFoundation
import Speech
import SwiftUI

// Speech-to-text for a prompt field: start on one tap, stop on the next, with
// each partial result landing in the field as it's recognised. `audioLevel`
// is the mic's loudness, 0…1, for anything that wants to react to the voice.
@Observable
final class BrightDictation {
    private(set) var isListening = false
    private(set) var audioLevel: Double = 0

    private let recognizer = SFSpeechRecognizer()
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    // What the field held before the mic went on, so each partial result
    // replaces only what's been spoken since.
    private var prefix = ""

    func toggle(_ text: Binding<String>) {
        if isListening {
            stop()
        } else {
            Task { await start(text) }
        }
    }

    func start(_ text: Binding<String>) async {
        guard !isListening, let recognizer, recognizer.isAvailable else { return }
        guard await requestAuthorisation() else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let existing = text.wrappedValue
        prefix = existing.isEmpty || existing.hasSuffix(" ") ? existing : existing + " "

        let input = engine.inputNode
        input.installTap(onBus: 0, bufferSize: Constants.bufferSize, format: input.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            request.append(buffer)
            let level = Self.level(of: buffer)
            Task { @MainActor in
                self?.audioLevel = level
            }
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            return
        }

        isListening = true
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let transcript = result?.bestTranscription.formattedString
            let isDone = error != nil || result?.isFinal == true
            Task { @MainActor in
                guard let self else { return }
                if let transcript {
                    text.wrappedValue = self.prefix + transcript
                }
                if isDone {
                    self.stop()
                }
            }
        }
    }

    func stop() {
        guard isListening else { return }
        isListening = false
        audioLevel = 0
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        // Finishing rather than cancelling lets the last words come through.
        task?.finish()
        request = nil
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // RMS of the buffer in decibels, mapped onto 0…1 from just above the
    // room's noise floor to a quiet speaking voice, then eased so a murmur
    // already moves the orb and anything louder pins it near full.
    private nonisolated static func level(of buffer: AVAudioPCMBuffer) -> Double {
        guard let channel = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let frames = Int(buffer.frameLength)
        var sum: Float = 0
        for index in 0..<frames {
            sum += channel[index] * channel[index]
        }
        let rms = sqrt(sum / Float(frames))
        let decibels = 20 * log10(max(rms, Constants.silenceFloor))
        let linear = min(1, max(0, (decibels - Constants.quietDecibels) / (Constants.loudDecibels - Constants.quietDecibels)))
        return pow(Double(linear), Constants.responseCurve)
    }

    private func requestAuthorisation() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speech == .authorized else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    private nonisolated enum Constants {
        static let bufferSize: AVAudioFrameCount = 1024
        static let silenceFloor: Float = 1e-6
        static let quietDecibels: Float = -60
        static let loudDecibels: Float = -30
        static let responseCurve: Double = 0.5
    }
}
