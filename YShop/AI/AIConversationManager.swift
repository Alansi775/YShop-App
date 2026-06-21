import Foundation
import Combine

// MARK: - Phase

enum AIPhase: Equatable {
    case welcome
    case listening
    case thinking
    case results(message: String)

    static func == (lhs: AIPhase, rhs: AIPhase) -> Bool {
        switch (lhs, rhs) {
        case (.welcome, .welcome), (.listening, .listening), (.thinking, .thinking): return true
        case (.results(let a), .results(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - Manager

@MainActor
final class AIConversationManager: ObservableObject {
    static let shared = AIConversationManager()

    @Published private(set) var phase: AIPhase            = .welcome
    @Published private(set) var products: [[String: Any]] = []
    @Published private(set) var lastAIMessage: String?    = nil
    @Published private(set) var isListening               = false
    @Published private(set) var transcript                = ""

    private(set) var lastQuery: String?

    let tts = TTSService.shared
    private let stt = STTService.shared
    private var isProcessing = false   // guard against double-fire from STT

    private init() {
        stt.$isListening.assign(to: &$isListening)
        stt.$transcript .assign(to: &$transcript)
        stt.onFinalResult = { [weak self] text in
            Task { @MainActor [weak self] in await self?.handleVoiceResult(text) }
        }
    }

    // MARK: - Voice

    func toggleVoice() async {
        if isListening {
            // Stop listening → go back to last state
            await stt.stopListening()
            phase = lastAIMessage != nil ? .results(message: lastAIMessage!) : .welcome
        } else {
            tts.stop()
            let granted = await stt.requestPermissions()
            guard granted else { return }

            // First time (welcome) → greet then listen. Follow-up → just listen.
            if case .welcome = phase {
                guard !isProcessing else { return }
                tts.selectRandomVoice()
                let name = tts.currentVoiceName
                let greeting = "Hey! I'm \(name), your YShop assistant. What can I help you find today?"
                lastAIMessage = greeting
                phase = .results(message: greeting)
                await tts.speak(greeting, mood: "warm", energy: 0.72)
            }
            await beginListening()
        }
    }

    private func beginListening() async {
        phase = .listening
        await stt.startListening()
    }

    private func handleVoiceResult(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isProcessing else { return }
        // Send in voice mode → AI speaks response → stay in results, user taps mic to continue
        await sendInternal(text: trimmed, speakResponse: true)
    }

    // MARK: - Text

    func sendText(_ message: String, userId: String = "guest") async {
        tts.stop()
        await stt.stopListening()
        await sendInternal(text: message, speakResponse: false)
    }

    func replayResponse() async {
        guard let msg = lastAIMessage else { return }
        await tts.speak(msg, mood: products.isEmpty ? "warm" : "excited", energy: 0.72)
    }

    // MARK: - Core Send

    private func sendInternal(text: String, speakResponse: Bool) async {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isProcessing = true
        lastQuery    = trimmed
        phase        = .thinking
        products     = []

        do {
            // Direct access — same @MainActor context, no await needed
            let userId = AuthManager.shared.currentUser?.id ?? "guest"
            let result = try await AIChatService.shared.chat(message: trimmed, userId: userId)
            lastAIMessage = result.message
            products      = result.products
            phase         = .results(message: result.message)
            isProcessing  = false

            if speakResponse {
                await tts.speak(result.message, mood: result.voiceMood, energy: result.voiceIntensity)
            }
        } catch {
            lastAIMessage = "Connection error. Please try again."
            phase         = .results(message: lastAIMessage!)
            isProcessing  = false
        }
        // Always stay in .results — user taps mic to continue voice conversation
    }

    // MARK: - Cart Tracking

    func trackAddToCart(product: [String: Any]) {
        guard let productId = product["id"] as? Int else { return }
        Task {
            let userId = AuthManager.shared.currentUser?.id ?? "guest"
            await AIChatService.shared.trackInteraction(
                userId:    userId,
                productId: productId,
                query:     lastQuery,
                storeType: product["store_type"] as? String
            )
        }
    }

    // MARK: - Reset

    func reset() {
        isProcessing  = false
        phase         = .welcome
        products      = []
        lastAIMessage = nil
        lastQuery     = nil
        tts.stop()
        Task { await stt.stopListening() }
    }
}
