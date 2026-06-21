import Foundation

struct AIConfig {
    // Add YSHOP_TTS_KEY to your Xcode scheme env vars (Product > Scheme > Edit Scheme > Run > Environment Variables)
    // or to Info.plist — never hardcode keys in source files
    static var ttsKey: String {
        ProcessInfo.processInfo.environment["YSHOP_TTS_KEY"]
            ?? (Bundle.main.object(forInfoDictionaryKey: "YSHOP_TTS_KEY") as? String ?? "")
    }

    static let ttsBaseURL   = "https://api.elevenlabs.io/v1"
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
