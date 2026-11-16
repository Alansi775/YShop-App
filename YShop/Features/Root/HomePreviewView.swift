import SwiftUI

/// Temporary home: proves the new stack end to end (session + catalog API +
/// optimized images) until the real Home screen lands.
struct HomePreviewView: View {
    let onSignIn: () -> Void

    @Environment(SessionStore.self) private var session
    @State private var stores: [API.Store] = []
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                if let error {
                    Section { InlineError(message: error) }
                }
                Section("Stores") {
                    ForEach(stores) { store in
                        HStack(spacing: 14) {
                            AsyncImage(url: store.iconUrl, transaction: .init(animation: .smooth)) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    Color(.tertiarySystemFill)
                                }
                            }
                            .frame(width: 52, height: 52)
                            .clipShape(.rect(cornerRadius: 14, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.name).font(.headline)
                                Text("\(store.type) · \(store.productCount) products")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(session.user.map { "Hi, \($0.firstName ?? $0.displayName)" } ?? "YShop")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let user = session.user {
                        Menu {
                            Text(user.email)
                            Button("Sign out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                                Task { await session.signOut() }
                            }
                        } label: {
                            Text(user.initials)
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 32, height: 32)
                        }
                    } else {
                        Button("Sign in", action: onSignIn)
                    }
                }
            }
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private func load() async {
        do {
            stores = try await API.Catalog.stores()
            error = nil
        } catch {
            self.error = (error as? API.Failure)?.message ?? error.localizedDescription
        }
    }
}
