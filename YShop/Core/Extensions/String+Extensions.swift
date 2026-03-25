//
//  String+Extensions.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import Foundation

extension String {
    // MARK: - Validation
    var isValidEmail: Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: self)
    }

    var isValidPhone: Bool {
        let pattern = "^[+]?[0-9]{7,15}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: self)
    }

    var isValidPassword: Bool {
        // Minimum 8 characters, at least one uppercase, one lowercase, one digit
        let pattern = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: self)
    }

    var isValidURL: Bool {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(location: 0, length: utf16.count)
        return detector?.firstMatch(in: self, options: [], range: range) != nil
    }

    // MARK: - Formatting
    var capitalized: String {
        prefix(1).uppercased() + dropFirst().lowercased()
    }

    func truncated(to length: Int, trailing: String = "...") -> String {
        if count > length {
            return String(prefix(length - trailing.count)) + trailing
        }
        return self
    }

    // MARK: - Utilities
    var isBlank: Bool {
        trimmingCharacters(in: .whitespaces).isEmpty
    }

    var trimmed: String {
        trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Price Formatting
    static func formattedPrice(_ value: Double, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
