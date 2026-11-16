import SwiftUI

/// Home: the kinds of stores that exist right now (a kind with no store is
/// never shown), then that kind's stores as big image cards.
struct HomePreviewView: View {
    let onSignIn: () -> Void

    @Environment(SessionStore.self) private var session
    @State private var types: [API.StoreType] = []
    @State private var selected: String?
    @State private var stores: [String: [API.Store]] = [:]
    @State private var error: String?

    private var current: [API.Store] { selected.flatMap { stores[$0] } ?? [] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let error { InlineError(message: error).padding(.horizontal, 20) }

                    if types.count > 1 {
                        Picker("Kind", selection: $selected) {
                            ForEach(types) { t in
                                Text(StoreKind(t.type).title).tag(Optional(t.type))
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                    }

                    LazyVStack(spacing: 0) {
                        ForEach(current) { store in
                            Button {} label: { StoreRow(store: store) }
                                .buttonStyle(PressableStoreStyle())
                            if store.id != current.last?.id { Divider().padding(.leading, 76) }
                        }
                    }
                    .padding(.horizontal, 20)
                    .animation(.smooth, value: selected)
                }
                .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
            .navigationTitle("YShop")
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
            .sensoryFeedback(.selection, trigger: selected)
        }
    }

    private func load() async {
        do {
            async let t = API.Catalog.storeTypes()
            async let s = API.Catalog.stores()
            let (kinds, all) = try await (t, s)
            types = kinds.sorted { StoreKind($0.type).order < StoreKind($1.type).order }
            stores = Dictionary(grouping: all, by: \.type)
            if selected == nil || !types.contains(where: { $0.type == selected }) { selected = types.first?.type }
            error = nil
        } catch {
            self.error = (error as? API.Failure)?.message ?? error.localizedDescription
        }
    }
}

/// The four kinds YShop sells. Unknown kinds still show, with a neutral look.
struct StoreKind {
    let title: String, symbol: String, order: Int

    init(_ raw: String) {
        switch raw.lowercased() {
        case "food", "restaurant", "restaurants": (title, symbol, order) = ("Restaurants", "fork.knife", 0)
        case "market", "supermarket", "grocery": (title, symbol, order) = ("Supermarkets", "cart", 1)
        case "pharmacy", "pharmacies": (title, symbol, order) = ("Pharmacies", "cross.case", 2)
        case "clothes", "clothing", "fashion": (title, symbol, order) = ("Clothes", "tshirt", 3)
        default: (title, symbol, order) = (raw.capitalized, "bag", 9)
        }
    }
}

/// A store as one calm row: its logo, name and how much it sells.
private struct StoreRow: View {
    let store: API.Store

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: store.iconUrl, transaction: .init(animation: .smooth)) { $0.image?.resizable().scaledToFill() }
                .frame(width: 60, height: 60)
                .background(Color(.secondarySystemFill))
                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5) }
            VStack(alignment: .leading, spacing: 3) {
                Text(store.name).font(.headline).foregroundStyle(.primary)
                Text("\(store.productCount) products").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
        .contentShape(.rect)
    }
}

private struct PressableStoreStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.3), value: configuration.isPressed)
    }
}
