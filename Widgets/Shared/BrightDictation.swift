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
// each partial result landing in the field as it's recognised.
@Observable
final class BrightDictation {
    private(set) var isListening = false

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
        input.installTap(onBus: 0, bufferSize: Constants.bufferSize, format: input.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
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
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        // Finishing rather than cancelling lets the last words come through.
        task?.finish()
        request = nil
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func requestAuthorisation() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speech == .authorized else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    private enum Constants {
        static let bufferSize: AVAudioFrameCount = 1024
    }
}
