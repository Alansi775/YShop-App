import SwiftUI

struct YShopTextField: View {
    let placeholder: String
    let icon: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false
    
    // YSHOP Brand Blue - يشتغل في Light & Dark Mode
    private var accentBlue: Color {
        Color(red: 0.0, green: 0.48, blue: 1.0)
    }
    
    private var isActive: Bool {
        isFocused || !text.isEmpty
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background + Border
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(backgroundFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: isFocused ? 1.5 : 0.5)
                )
                .shadow(
                    color: isFocused ? accentBlue.opacity(0.12) : .clear,
                    radius: isFocused ? 8 : 0,
                    x: 0,
                    y: 0
                )
            
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                // Floating Label + TextField
                ZStack(alignment: .leading) {
                    Text(placeholder)
                        .font(.system(
                            size: isActive ? 11 : 15,
                            weight: isActive ? .semibold : .regular
                        ))
                        .foregroundColor(isActive ? accentBlue : Color(.secondaryLabel))
                        .offset(y: isActive ? -14 : 0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isActive)
                    
                    Group {
                        if isSecure && !isPasswordVisible {
                            SecureField("", text: $text)
                        } else {
                            TextField("", text: $text)
                                .keyboardType(keyboardType)
                                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .sentences)
                                .autocorrectionDisabled(keyboardType == .emailAddress)
                        }
                    }
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(.label))
                    .focused($isFocused)
                    .offset(y: isActive ? 8 : 0)
                    .opacity(isActive ? 1 : 0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isActive)
                }
                
                // Show/Hide Password
                if isSecure && !text.isEmpty {
                    Button(action: {
                        HapticManager.shared.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPasswordVisible.toggle()
                        }
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(.tertiaryLabel))
                            .frame(width: 24, height: 24)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 56)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isFocused {
                isFocused = true
            }
        }
        .onChange(of: isFocused) { _, newValue in
            if newValue {
                HapticManager.shared.selection()
            }
        }
    }
    
    // MARK: - Adaptive Colors
    
    private var backgroundFillColor: Color {
        if isFocused {
            return Color(.systemBackground)
        } else {
            return Color(.secondarySystemBackground).opacity(0.6)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return accentBlue.opacity(0.5)
        } else {
            return Color(.separator).opacity(0.5)
        }
    }
    
    private var iconColor: Color {
        if isFocused {
            return accentBlue
        } else {
            return Color(.tertiaryLabel)
        }
    }
}