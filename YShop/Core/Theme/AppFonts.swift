//
//  AppFonts.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import SwiftUI
import Foundation

extension Font {
    static func tenorSans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Tenor Sans", size: size)
    }

    // Predefined sizes
    static var tenorSansCaption: Font {
        .tenorSans(size: 12)
    }

    static var tenorSansBody: Font {
        .tenorSans(size: 14)
    }

    static var tenorSansSubtitle: Font {
        .tenorSans(size: 16)
    }

    static var tenorSansTitle: Font {
        .tenorSans(size: 18)
    }

    static var tenorSansHeadline: Font {
        .tenorSans(size: 20)
    }

    static var tenorSansLargeTitle: Font {
        .tenorSans(size: 24)
    }

    static var tenorSansDisplay: Font {
        .tenorSans(size: 28)
    }

    static var tenorSansHero: Font {
        .tenorSans(size: 32)
    }
}

// UIFont extension for custom font registration
#if os(iOS)
import UIKit

extension UIFont {
    static func registerCustomFonts() {
        let fontNames = ["TenorSans-Regular"]
        for name in fontNames {
            if let fontPath = Bundle.main.path(forResource: name, ofType: "ttf"),
               let data = try? Data(contentsOf: URL(fileURLWithPath: fontPath)),
               let provider = CGDataProvider(data: data as CFData),
               let font = CGFont(provider) {
                CTFontManagerRegisterGraphicsFont(font, nil)
            }
        }
    }
}
#else
// Non-iOS platforms don't need font registration
#endif
