//
//  AppTheme.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        static let primary = Color.black
        static let secondary = Color(red: 0.2, green: 0.4, blue: 1)
        static let background = Color.white
        static let surface = Color(white: 0.97)
        static let error = Color(red: 1, green: 0.2, blue: 0.2)
        static let success = Color(red: 0.2, green: 0.8, blue: 0.2)
        static let warning = Color(red: 1, green: 0.8, blue: 0.2)
        static let textPrimary = Color.black
        static let textSecondary = Color.gray
        static let border = Color(white: 0.9)
        static let placeholder = Color(white: 0.7)
    }

    // MARK: - Font Sizes
    struct FontSizes {
        static let caption: CGFloat = 12
        static let body: CGFloat = 14
        static let subtitle: CGFloat = 16
        static let title: CGFloat = 18
        static let headline: CGFloat = 20
        static let largeTitle: CGFloat = 24
        static let display: CGFloat = 28
        static let hero: CGFloat = 32
    }

    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    // MARK: - Shadows
    struct Shadows {
        static let light = Shadow(color: .black, radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black, radius: 4, x: 0, y: 2)
        static let heavy = Shadow(color: .black, radius: 8, x: 0, y: 4)
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    func modifier() -> some ViewModifier {
        ShadowModifier(color: color, radius: radius, x: x, y: y)
    }
}

struct ShadowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(color: color.opacity(0.1), radius: radius, x: x, y: y)
    }
}
