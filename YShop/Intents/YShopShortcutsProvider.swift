import AppIntents

struct YShopShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TrackOrderIntent(),
            phrases: [
                "Track my \(.applicationName) order",
                "Where is my \(.applicationName) order",
                "Check my \(.applicationName) delivery",
                "What is the status of my \(.applicationName) order",
                "\(.applicationName) order status",
                "Is my \(.applicationName) order on the way",
                "Where is my \(.applicationName) food",
                "Check \(.applicationName) delivery status",
                "Where is my \(.applicationName) package",
                "Has my \(.applicationName) order arrived"
            ],
            shortTitle: "Track Order",
            systemImageName: "bag.fill"
        )
    }
}
