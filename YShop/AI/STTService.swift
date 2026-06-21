import Foundation
import Speech
import AVFoundation

@MainActor
final class STTService: NSObject, ObservableObject {
    static let shared = STTService()
    private override init() { super.init() }

    @Published private(set) var isListening = false
    @Published private(set) var transcript  = ""

    var onFinalResult: ((String) -> Void)?

    private let recognizer      = SFSpeechRecognizer(locale: .current)
    private var recognitionTask: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private let audioEngine     = AVAudioEngine()
    private var silenceTimer: Timer?

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
        guard speech else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    // MARK: - Listen

    func startListening() async {
        guard let recognizer, recognizer.isAvailable else { return }
        if isListening { await stopListening() }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true)
        } catch { return }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        self.request = req

        recognitionTask = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    let text = result.bestTranscription.formattedString
                    self.transcript = text

                    // Reset silence timer on every new word
                    self.silenceTimer?.invalidate()
                    if !text.isEmpty {
                        self.silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                            guard let self else { return }
                            Task { @MainActor in
                                guard self.isListening, !self.transcript.isEmpty else { return }
                                let final = self.transcript
                                await self.stopListening()
                                self.onFinalResult?(final)
                            }
                        }
                    }

                    if result.isFinal {
                        self.silenceTimer?.invalidate()
                        let final = self.transcript
                        await self.stopListening()
                        self.onFinalResult?(final)
                    }
                }
                if error != nil {
                    self.silenceTimer?.invalidate()
                    await self.stopListening()
                }
            }
        }

        let node = audioEngine.inputNode
        let fmt  = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            self?.request?.append(buf)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
            transcript  = ""
        } catch {
            cleanup()
        }
    }

    func stopListening() async {
        silenceTimer?.invalidate()
        silenceTimer = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        cleanup()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Private

    private func cleanup() {
        request         = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening     = false
    }
}
