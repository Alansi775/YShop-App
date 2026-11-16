import SwiftUI

/// Root of the redesigned app. Debug builds show it; release builds keep the
/// old app until every screen is replaced (`AppFlags.useV2`).
struct AppRootV2: View {
    @State private var session = SessionStore.shared
    @State private var showSignIn = false
    @State private var splashDone = false
    @AppStorage("v2.didOfferSignIn") private var didOfferSignIn = false

    var body: some View {
        ZStack {
            if session.phase != .launching {
                HomePreviewView(onSignIn: { showSignIn = true })
            }
            if !splashDone {
                LaunchSplash { splashDone = true }
                    .zIndex(1)
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
            // Sign-in waits until the opening shot is over.
            while !splashDone { try? await Task.sleep(for: .milliseconds(100)) }
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
