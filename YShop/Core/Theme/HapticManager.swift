//
//  HapticManager.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

#if os(iOS)
import UIKit

class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Impact Feedback
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback
    func notification(type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    // MARK: - Selection Feedback
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Common Patterns
    func buttonTap() {
        impact(style: .light)
    }

    func success() {
        notification(type: .success)
    }

    func error() {
        notification(type: .error)
    }

    func warning() {
        notification(type: .warning)
    }
}
#else
// Fallback for non-iOS platforms
class HapticManager {
    static let shared = HapticManager()
    private init() {}
    func impact(style: Any = ()) {}
    func notification(type: Any = ()) {}
    func selection() {}
    func buttonTap() {}
    func success() {}
    func error() {}
    func warning() {}
}
#endif
