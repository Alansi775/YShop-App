import Foundation

// Thread-safe disk-backed JSON cache.
// Pattern: stale-while-revalidate — callers show cached data instantly,
// then refresh from the network in the background if the entry is stale.
final class AppCache: @unchecked Sendable {
    static let shared = AppCache()
    private init() { ensureDirectory() }

    private let dir: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("YShopCache", isDirectory: true)
    }()

    private let queue = DispatchQueue(label: "com.yshop.cache", attributes: .concurrent)

    // MARK: - Read

    /// Returns the cached value and whether it is stale.
    /// Returns nil when no entry exists on disk.
    func get<T: Codable>(_ key: Key) -> CacheResult<T>? {
        queue.sync {
            guard let data = try? Data(contentsOf: url(key)),
                  let entry = try? JSONDecoder().decode(Entry<T>.self, from: data)
            else { return nil }
            return CacheResult(value: entry.value, isStale: entry.isStale)
        }
    }

    // MARK: - Write

    func set<T: Codable>(_ key: Key, value: T) {
        queue.async(flags: .barrier) { [self] in
            let entry = Entry(value: value, savedAt: Date(), ttl: key.ttl)
            if let data = try? JSONEncoder().encode(entry) {
                try? data.write(to: url(key), options: .atomic)
            }
        }
    }

    // MARK: - Invalidate

    func invalidate(_ key: Key) {
        queue.async(flags: .barrier) { [self] in
            try? FileManager.default.removeItem(at: url(key))
        }
    }

    /// Wipe all cached data (e.g. on sign-out).
    func invalidateAll() {
        queue.async(flags: .barrier) { [self] in
            try? FileManager.default.removeItem(at: dir)
            ensureDirectory()
        }
    }

    // MARK: - Private

    private func url(_ key: Key) -> URL {
        dir.appendingPathComponent(key.filename + ".cache")
    }

    private func ensureDirectory() {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
}

// MARK: - Supporting types

struct CacheResult<T> {
    let value: T
    let isStale: Bool  // true → show now, fetch fresh in background
}

private struct Entry<T: Codable>: Codable {
    let value: T
    let savedAt: Date
    let ttl: TimeInterval

    var isStale: Bool { Date().timeIntervalSince(savedAt) > ttl }
}

// MARK: - Keys

extension AppCache {
    enum Key {
        case stores(category: String)   // category stores list
        case storeDetail(id: String)    // single store
        case products(storeId: Int)     // products for a store
        case categories(storeId: String)
        case userOrders                 // My Orders list
        case activeOrder(id: String)    // single order (short TTL)

        var filename: String {
            switch self {
            case .stores(let cat):        return "stores_\(cat.lowercased())"
            case .storeDetail(let id):    return "store_\(id)"
            case .products(let id):       return "products_\(id)"
            case .categories(let id):     return "categories_\(id)"
            case .userOrders:             return "user_orders"
            case .activeOrder(let id):    return "order_\(id)"
            }
        }

        var ttl: TimeInterval {
            switch self {
            case .stores:       return 5 * 60    // 5 min — rarely changes
            case .storeDetail:  return 5 * 60
            case .products:     return 10 * 60   // 10 min — even more stable
            case .categories:   return 10 * 60
            case .userOrders:   return 30        // 30 s — changes on every order event
            case .activeOrder:  return 10        // 10 s — live tracking
            }
        }
    }
}
