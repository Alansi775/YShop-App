import SwiftUI

struct ProfileView: View {
    @State private var showProfileSheet = false
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome, \(authManager.currentUser?.name ?? "Customer")!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("This is your profile page. Here you can view your orders, manage your account settings, and more.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Button(action: {
                showProfileSheet = true
            }) {
                Text("View Profile Options")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
            }
            Spacer()
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheetView(isPresented: $showProfileSheet) {
                // Action when "My Orders" is tapped in the sheet
                print("Navigate to My Orders")
            }
        }
    }
}
// MARK: - iOS Native Luxury Option Row
struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let iconBgColor: Color // لون خلفية الأيقونة على طريقة آبل الفاخرة
    
    var body: some View {
        HStack(spacing: 14) {
            // أيقونة داخل مربع دائري ملون بنقاء (طراز الإعدادات الرسمي لآبل)
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(iconBgColor)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: 28, height: 28)
            
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primary) // يتكيف تلقائياً 100% مع النظام
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.yshopInkWhisperDynamic.opacity(0.45))
        }
        .frame(height: 48)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - Profile Sheet View
struct ProfileSheetView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isPresented: Bool
    let onMyOrders: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var glowScale: CGFloat = 0.98
    @State private var glowOpacity: Double = 0.2
    
    var body: some View {
        ZStack {
            // استخدام مواد النظام الشفافة (System Materials) ليتفاعل الـ Blur مع الخلفية وراء الـ Sheet
            if colorScheme == .dark {
                Color(uiColor: .systemBackground)
                    .overlay(Color.black.opacity(0.15))
                    .ignoresSafeArea()
            } else {
                Color(uiColor: .secondarySystemBackground)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // مقبض الـ Sheet الرسمي النحيف
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color(.placeholderText).opacity(0.5))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // MARK: - Micro-Pulse iOS Avatar
                        VStack(spacing: 12) {
                            ZStack {
                                // الشعاع الخلفي: حركة خفيفة جداً تكاد لا تلاحظ بالعين المجردة (Micro-interaction)
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.teal, Color.purple],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 82, height: 82)
                                    .blur(radius: 12)
                                    .opacity(glowOpacity)
                                    .scaleEffect(glowScale)
                                
                                // جسم الأفاتار المبني من مادة الـ Thick Material ليعكس ما خلفه بنقاء الأرستقراطية
                                Circle()
                                    .fill(.ultraThickMaterial)
                                    .frame(width: 76, height: 76)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.6), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
                                
                                Text(profileInitials)
                                    .font(.system(size: 24, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            .onAppear {
                                // حركة تنفس مايكروية فائقة النعومة والبطء
                                withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                                    glowScale = 1.04
                                    glowOpacity = 0.35
                                }
                            }
                            
                            VStack(spacing: 2) {
                                Text(authManager.currentUser?.name ?? "Mohammed Saleh")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(authManager.currentUser?.email ?? "mohamedalezzi6@gmail.com")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 10)
                        
                        // MARK: - Native iOS Menu Block
                        // تصميم القوائم مدمج بالكامل داخل مادة الـ Material المتكيفة مثل إعدادات آيفون الرسمية
                        VStack(spacing: 0) {
                            ProfileOptionRow(icon: "person.fill", title: "My Profile", iconBgColor: .blue)
                            customDivider
                            
                            ProfileOptionRow(icon: "heart.fill", title: "Saved Items", iconBgColor: .pink)
                            customDivider
                            
                            Button(action: onMyOrders) {
                                ProfileOptionRow(icon: "bag.fill", title: "My Orders", iconBgColor: .orange)
                            }
                            .buttonStyle(.plain)
                            customDivider
                            
                            ProfileOptionRow(icon: "creditcard.fill", title: "Payment Methods", iconBgColor: .green)
                            customDivider
                            
                            ProfileOptionRow(icon: "questionmark.circle.fill", title: "Help & Support", iconBgColor: .purple)
                        }
                        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.0 : 0.04), radius: 10, y: 5)
                        
                        // MARK: - Native Styled Sign Out
                        // تحويل الزر إلى صف مدمج أحمر ناصع بنقاء كامل بدون كبسولات غريبة تناسب الاندرويد
                        VStack(spacing: 0) {
                            Button(action: {
                                authManager.logout()
                                isPresented = false
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Sign Out")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .frame(height: 48)
                            }
                        }
                        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.0 : 0.04), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 16) // الحجم القياسي لهوامش الآيفون هو 16
                    .padding(.bottom, 30)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // خط فاصل نحيف يختفي خلف الأيقونة ويبدأ مع بداية النص لحبك الهندسة البصرية
    private var customDivider: some View {
        Divider()
            .padding(.leading, 54)
    }
    
    private var profileInitials: String {
        let fullName = authManager.currentUser?.name ?? ""
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameParts = trimmedName.split(separator: " ")
        let firstInitial = nameParts.first.flatMap { $0.first }.map { String($0) } ?? ""
        let secondInitial = nameParts.dropFirst().first.flatMap { $0.first }.map { String($0) } ?? ""
        let initials = (firstInitial + secondInitial).uppercased()
        return initials.isEmpty ? "Y" : initials
    }
}