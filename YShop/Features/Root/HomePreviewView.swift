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
                        ScrollView(.horizontal) {
                            HStack(spacing: 10) {
                                ForEach(types) { t in
                                    KindChip(kind: StoreKind(t.type), selected: selected == t.type) {
                                        withAnimation(.snappy) { selected = t.type }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .scrollIndicators(.hidden)
                    }

                    LazyVStack(spacing: 18) {
                        ForEach(current) { store in
                            Button {} label: { StoreCard(store: store) }
                                .buttonStyle(PressableStoreStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .animation(.smooth, value: selected)
                }
                .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
            .navigationTitle(selected.map { StoreKind($0).title } ?? "YShop")
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

private struct KindChip: View {
    let kind: StoreKind
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(kind.title, systemImage: kind.symbol)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundStyle(selected ? Color(.systemBackground) : .primary)
                .background(selected ? Color(.label) : Color(.secondarySystemFill), in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

private struct StoreCard: View {
    let store: API.Store

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: store.coverUrl ?? store.iconUrl, transaction: .init(animation: .smooth)) { phase in
                if let image = phase.image { image.resizable().scaledToFill() }
                else { Rectangle().fill(Color(.secondarySystemFill)) }
            }
            .frame(height: 170)
            .frame(maxWidth: .infinity)
            .clipShape(.rect(cornerRadius: 22, style: .continuous))

            HStack(spacing: 12) {
                AsyncImage(url: store.iconUrl) { $0.image?.resizable().scaledToFill() }
                    .frame(width: 40, height: 40)
                    .background(Color(.secondarySystemFill))
                    .clipShape(.circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.name).font(.headline).foregroundStyle(.primary)
                    Text("\(store.productCount) products").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
            }
        }
    }
}

private struct PressableStoreStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.3), value: configuration.isPressed)
    }
}
