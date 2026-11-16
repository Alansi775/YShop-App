import Foundation

extension API {
    /// Where the v2 API lives.
    ///
    /// Debug builds talk to the Mac on the same Wi-Fi by its Bonjour name, so a
    /// changing IP never breaks the iPhone. Override at runtime with the
    /// `YSHOP_API_URL` scheme environment variable (e.g. the iMac over Tailscale).
    enum Config {
        static let baseURL: URL = {
            if let raw = ProcessInfo.processInfo.environment["YSHOP_API_URL"], let url = URL(string: raw) {
                return url
            }
            #if DEBUG
            return URL(string: "http://mohammeds-mackbook-macbook-air.local:3000/api/v2")!
            #else
            return URL(string: "https://yshop-imac.tail11c7de.ts.net/api/v2")!
            #endif
        }()

        static let timeout: TimeInterval = 15
    }
}
