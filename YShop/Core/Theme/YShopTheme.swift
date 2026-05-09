//
//  YShopTheme.swift
//  YSHOP
//
//  Minimal luxury design system.
//  Light mode: White + Black text + Light Blue accents
//  Dark mode: Black + White text + Light Blue accents
//

import SwiftUI

// MARK: - Brand Colors

extension Color {
    
    // MARK: Backgrounds
    
    /// Primary canvas. Light: white. Dark: black.
    static let yshopCanvas = Color("yshopCanvas", bundle: nil)
    
    /// Elevated surfaces. Light: white. Dark: dark gray.
    static let yshopSurface = Color("yshopSurface", bundle: nil)
    
    /// Background for splash.
    static let yshopVoid = Color("yshopVoid", bundle: nil)
    
    // MARK: Ink (text)
    
    /// Primary text. Light: black. Dark: white.
    static let yshopInk = Color("yshopInk", bundle: nil)
    
    /// Secondary text.
    static let yshopInkMuted = Color("yshopInkMuted", bundle: nil)
    
    /// Tertiary text.
    static let yshopInkWhisper = Color("yshopInkWhisper", bundle: nil)
    
    // MARK: Accent — Light Blue
    
    /// Signature accent. Light blue only.
    static let yshopGold = Color("yshopGold", bundle: nil)
    
    /// Soft blue for backgrounds.
    static let yshopGoldSoft = Color("yshopGoldSoft", bundle: nil)
    
    // MARK: Hairlines
    
    /// Divider line.
    static let yshopHairline = Color("yshopHairline", bundle: nil)
}

// MARK: - Programmatic fallback colors

extension Color {
    
    static let yshopCanvasDynamic = Color(
        light: Color(red: 1.0, green: 1.0, blue: 1.0),         // #FFFFFF white
        dark:  Color(red: 0.10, green: 0.10, blue: 0.10)       // #1A1A1A black
    )
    
    static let yshopSurfaceDynamic = Color(
        light: Color(red: 1.0, green: 1.0, blue: 1.0),         // #FFFFFF white
        dark:  Color(red: 0.12, green: 0.12, blue: 0.12)       // #1F1F1F dark gray
    )
    
    static let yshopVoidDynamic = Color(
        light: Color(red: 1.0, green: 1.0, blue: 1.0),         // #FFFFFF white
        dark:  Color(red: 0.08, green: 0.08, blue: 0.08)       // #141414 very dark
    )
    
    static let yshopInkDynamic = Color(
        light: Color(red: 0.10, green: 0.10, blue: 0.10),      // #1A1A1A black
        dark:  Color(red: 0.98, green: 0.98, blue: 0.98)       // #FAFAFA white
    )
    
    static let yshopInkMutedDynamic = Color(
        light: Color(red: 0.50, green: 0.50, blue: 0.50),      // #808080 gray
        dark:  Color(red: 0.70, green: 0.70, blue: 0.70)       // #B3B3B3 light gray
    )
    
    static let yshopInkWhisperDynamic = Color(
        light: Color(red: 0.70, green: 0.70, blue: 0.70),      // #B3B3B3 light gray
        dark:  Color(red: 0.50, green: 0.50, blue: 0.50)       // #808080 gray
    )
    
    static let yshopGoldDynamic = Color(
        light: Color(red: 0.258, green: 0.647, blue: 0.961),   // #42A5F5 light blue
        dark:  Color(red: 0.298, green: 0.682, blue: 0.996)    // #4CAFF5 bright light blue
    )
    
    static let yshopGoldSoftDynamic = Color(
        light: Color(red: 0.941, green: 0.973, blue: 1.0),     // #F1F8FF very light blue
        dark:  Color(red: 0.15, green: 0.25, blue: 0.35)       // #264158 dark blue tint
    )
    
    static let yshopHairlineDynamic = Color(
        light: Color(red: 0.90, green: 0.90, blue: 0.90),      // #E6E6E6 light gray
        dark:  Color(red: 0.25, green: 0.25, blue: 0.25)       // #404040 dark gray
    )
    
    // MARK: - Color light/dark initializer
    
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - Metrics

enum YShopMetrics {
    static let cornerSmall: CGFloat = 6
    static let cornerMedium: CGFloat = 12
    static let cornerLarge: CGFloat = 18
    static let hairline: CGFloat = 0.6
}
