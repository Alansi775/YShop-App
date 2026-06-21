import Foundation
import AVFoundation
import CryptoKit

@MainActor
final class TTSService: NSObject, ObservableObject {
    static let shared = TTSService()
    private override init() { super.init() }

    @Published private(set) var isPlaying = false
    @Published private(set) var isLoading = false
    @Published private(set) var currentVoiceName = AIConfig.voices[0].name

    private var player: AVAudioPlayer?
    private var cache: [String: Data] = [:]
    private var activeVoice = AIConfig.voices[0]
    private var failedVoiceIDs: Set<String> = []
    private var playbackContinuation: CheckedContinuation<Void, Never>?

    // MARK: - Public

    func selectRandomVoice() {
        let pool = AIConfig.voices.filter { !failedVoiceIDs.contains($0.id) }
        activeVoice = (pool.isEmpty ? AIConfig.voices : pool).randomElement()!
        currentVoiceName = activeVoice.name
        cache.removeAll()
    }

    /// Speaks text and awaits full playback completion before returning.
    /// Callers can safely start STT after this without interrupting audio.
    func speak(_ rawText: String, mood: String = "neutral", energy: Double = 0.65) async {
        let text = prepare(rawText, mood: mood)
        guard !text.isEmpty, !AIConfig.ttsKey.isEmpty else { return }

        let truncated = String(text.prefix(AIConfig.ttsMaxChars))
        let key = cacheKey(truncated, mood: mood, energy: energy)
        stop()
        isLoading = true

        let audio: Data?
        if let cached = cache[key] {
            audio = cached
        } else {
            audio = await fetchAudio(text: truncated, mood: mood, energy: energy)
            if let a = audio, a.count > 1000 { cache[key] = a }
        }
        isLoading = false

        guard let data = audio else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            player?.play()
            isPlaying = true

            // Suspend caller until delegate fires (or stop() is called)
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                self.playbackContinuation = cont
            }
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        // Resume any pending speak() await
        let cont = playbackContinuation
        playbackContinuation = nil
        cont?.resume()
    }

    // MARK: - Private

    private func fetchAudio(text: String, mood: String, energy: Double) async -> Data? {
        let profile = voiceProfile(mood: mood, energy: energy)
        guard let url = URL(string: "\(AIConfig.ttsBaseURL)/text-to-speech/\(activeVoice.id)") else { return nil }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(AIConfig.ttsKey,    forHTTPHeaderField: "xi-api-key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("audio/mpeg",       forHTTPHeaderField: "Accept")
        req.timeoutInterval = 15
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "text": text,
            "model_id": AIConfig.ttsModelID,
            "voice_settings": [
                "stability":        profile.stability,
                "similarity_boost": profile.similarityBoost,
                "style":            profile.style,
                "use_speaker_boost": true
            ]
        ])

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if status == 402, activeVoice.id != AIConfig.fallbackVoiceID {
                failedVoiceIDs.insert(activeVoice.id)
                activeVoice = AIConfig.voices.first { $0.id == AIConfig.fallbackVoiceID } ?? AIConfig.voices[0]
                currentVoiceName = activeVoice.name
                return await fetchAudio(text: text, mood: mood, energy: energy)
            }
            return status == 200 ? data : nil
        } catch { return nil }
    }

    private func voiceProfile(mood: String, energy: Double) -> (stability: Double, similarityBoost: Double, style: Double) {
        let t = min(max(energy, 0), 1)
        func b(_ lo: Double, _ hi: Double) -> Double { lo + (hi - lo) * t }
        switch mood {
        case "excited":                 return (b(0.28, 0.06), 0.88, b(0.75, 1.0))
        case "playful":                 return (b(0.38, 0.10), 0.85, b(0.58, 0.96))
        case "warm", "caring":          return (b(0.48, 0.28), 0.84, b(0.28, 0.62))
        case "curious":                 return (b(0.48, 0.22), 0.82, b(0.32, 0.68))
        case "whisper":                 return (b(0.94, 0.80), 0.70, b(0.01, 0.06))
        case "disappointed", "sad":     return (b(0.75, 0.52), 0.76, b(0.14, 0.32))
        default:                        return (b(0.55, 0.35), 0.78, b(0.15, 0.35))
        }
    }

    private func prepare(_ text: String, mood: String) -> String {
        var t = text
        let subs: [(String, String)] = [
            ("(hmm)", "Hmm..."), ("(hm)", "Hm..."), ("(sighs)", "—"),
            ("(laughs)", "Ha!"), ("(chuckles)", "Heh,"), ("(ha!)", "Ha!"),
            ("(whispering)", ""), ("(exhales)", "—")
        ]
        for (from, to) in subs { t = t.replacingOccurrences(of: from, with: to, options: .caseInsensitive) }
        if (mood == "excited" || mood == "playful"), !t.hasSuffix("!"), !t.hasSuffix("?") { t += "!" }
        return t.trimmingCharacters(in: .whitespaces)
    }

    private func cacheKey(_ text: String, mood: String, energy: Double) -> String {
        let input = "\(mood)|\(String(format: "%.2f", energy))|\(text)"
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.prefix(12).map { String(format: "%02x", $0) }.joined()
    }
}

extension TTSService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully _: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            let cont = self.playbackContinuation
            self.playbackContinuation = nil
            cont?.resume()
        }
    }
}
