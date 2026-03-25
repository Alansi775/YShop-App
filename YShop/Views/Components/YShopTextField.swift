import SwiftUI

struct YShopTextField: View {
    let placeholder: String
    let icon: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    @Binding var text: String
    @State private var isSecureFieldVisible = false
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    init(
        placeholder: String,
        icon: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self.placeholder = placeholder
        self.icon = icon
        self._text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with color animation
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isFocused ? Color(.secondaryLabel) : Color(.tertiaryLabel))
                .frame(width: 28)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            // Text Field
            Group {
                if isSecure && !isSecureFieldVisible {
                    SecureField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .focused($isFocused)
                }
            }
            .font(.system(size: 15, weight: .regular))
            .textInputAutocapitalization(.none)
            .disableAutocorrection(true)
            
            // Show/Hide Password Toggle
            if isSecure {
                Button {
                    isSecureFieldVisible.toggle()
                    HapticManager.shared.selection()
                } label: {
                    Image(systemName: isSecureFieldVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isFocused ? Color(.secondaryLabel) : Color(.tertiaryLabel))
                }
                .frame(width: 28)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFocused ? Color(.secondaryLabel) : Color(.tertiaryLabel).opacity(0.1),
                    lineWidth: 1.5
                )
        )
        .frame(height: 54)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    @State var email = ""
    @State var password = ""
    
    VStack(spacing: 14) {
        YShopTextField(
            placeholder: "Email Address",
            icon: "envelope.fill",
            text: $email,
            keyboardType: .emailAddress
        )
        
        YShopTextField(
            placeholder: "Password",
            icon: "lock.fill",
            text: $password,
            isSecure: true
        )
    }
    .padding()
    .background(Color(hex: "F5F7FA"))
}
