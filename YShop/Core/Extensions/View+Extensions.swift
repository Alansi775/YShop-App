//
//  View+Extensions.swift
//  YShop
//
//  Created by AI Assistant on 2026-03-14.
//

import SwiftUI
import Foundation

// MARK: - Theme Colors (Inline)
private struct ThemeColors {
    static let primary = Color.black
    static let secondary = Color(red: 0.2, green: 0.5, blue: 1)
    static let background = Color.white
    static let surface = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let error = Color.red
    static let success = Color.green
    static let warning = Color.orange
    static let border = Color(red: 0.9, green: 0.9, blue: 0.9)
    static let placeholder = Color(red: 0.8, green: 0.8, blue: 0.8)
}

extension Font {
    static func tenorSansBold(size: CGFloat) -> Font {
        .custom("TenorSans", size: size)
    }
}

extension View {
    // MARK: - Styling
    func cardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(ThemeColors.surface)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    func primaryButtonStyle(
        isLoading: Bool = false,
        isEnabled: Bool = true
    ) -> some View {
        self
            .font(.tenorSansBold(size: 16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(isEnabled ? ThemeColors.primary : ThemeColors.placeholder)
            .cornerRadius(12)
            .opacity(isLoading ? 0.7 : 1)
            .disabled(!isEnabled || isLoading)
    }

    func secondaryButtonStyle(isEnabled: Bool = true) -> some View {
        self
            .font(.tenorSansBold(size: 16))
            .foregroundColor(ThemeColors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(ThemeColors.surface)
            .cornerRadius(12)
            .border(ThemeColors.border, width: 1)
            .opacity(isEnabled ? 1 : 0.5)
            .disabled(!isEnabled)
    }

    // MARK: - Layout
    func fillMaxFrameWidth(alignment: Alignment = .center) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
    }

    func fillMaxFrame(alignment: Alignment = .center) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }

    // MARK: - Background
    func appBackground() -> some View {
        background(ThemeColors.background.ignoresSafeArea())
    }

    // MARK: - Conditional
    @ViewBuilder
    func visible(if condition: Bool) -> some View {
        if condition {
            self
        }
    }

    // MARK: - Safe Area
    func ignoresSafeAreaEdges(_ edges: Edge.Set = .all) -> some View {
        ignoresSafeArea(edges: edges)
    }

    // MARK: - Error Handling
    func withErrorBorder(_ hasError: Bool) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(hasError ? ThemeColors.error : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Loading Overlay
    func withLoadingOverlay(_ isLoading: Bool) -> some View {
        ZStack {
            self

            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }
        }
    } 

    // MARK: - Toast/Alert Presentation
    func withAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String?
    ) -> some View {
        alert(title, isPresented: isPresented, actions: {
            Button("OK") { isPresented.wrappedValue = false }
        }, message: {
            if let message = message {
                Text(message)
            }
        })
    }
}
