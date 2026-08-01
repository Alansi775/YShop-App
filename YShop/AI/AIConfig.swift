import Foundation

struct AIConfig {
    // Voice synthesis goes through our own backend's /ai/speak proxy
    // (see TTSService.fetchAudio) — no provider key or URL needed client-side.
    static let ttsModelID   = "eleven_turbo_v2_5"
    static let ttsMaxChars  = 300

    struct Voice {
        let id: String
        let name: String
        let gender: String
    }

    // Free-tier ElevenLabs voices only
    static let voices: [Voice] = [
        Voice(id: "JBFqnCBsd6RMkjVDRZzb", name: "Karim", gender: "male"),
        Voice(id: "EXAVITQu4vr4xnSDxMaL", name: "Sara",  gender: "female"),
        Voice(id: "pNInz6obpgDQGcFmaJgB", name: "Rami",  gender: "male"),
    ]

    static let fallbackVoiceID = voices[0].id
}
