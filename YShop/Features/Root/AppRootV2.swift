import SwiftUI

/// Root of the redesigned app. Debug builds show it; release builds keep the
/// old app until every screen is replaced (`AppFlags.useV2`).
struct AppRootV2: View {
    @State private var session = SessionStore.shared
    @State private var showSignIn = false
    @AppStorage("v2.didOfferSignIn") private var didOfferSignIn = false

    var body: some View {
        ZStack {
            switch session.phase {
            case .launching:
                BrandBackground()
                    .overlay { BrandWordmark(size: 40) }
                    .transition(.opacity)
            case .guest, .signedIn:
                HomePreviewView(onSignIn: { showSignIn = true })
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.5), value: session.phase)
        .environment(session)
        .fullScreenCover(isPresented: $showSignIn) {
            SignInView(onClose: { showSignIn = false })
                .environment(session)
        }
        .onChange(of: session.phase) { _, phase in
            if case .signedIn = phase { showSignIn = false }
        }
        .task {
            await session.restore()
            // First launch: offer sign-in once; after that guests browse freely.
            if session.user == nil && !didOfferSignIn {
                didOfferSignIn = true
                showSignIn = true
            }
        }
    }
}

enum AppFlags {
    /// `YSHOP_V2=0` in the scheme's environment brings the old app back in debug.
    static var useV2: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["YSHOP_V2"] != "0"
        #else
        return false
        #endif
    }
}
