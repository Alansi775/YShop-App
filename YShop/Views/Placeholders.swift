//
//  Placeholders.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import SwiftUI

// Placeholder preview helper
struct PlaceholderPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag.fill")
                .font(.system(size: 44))
                .foregroundColor(AppTheme.Colors.primary)

            Text("Coming Soon...")
                .font(.tenorSansBody)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
    }
}

#Preview {
    PlaceholderPreview()
}
