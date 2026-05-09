import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(.secondaryLabel))
                    
                    TextField("Search products", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(Color(.label))
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(Color(.secondaryLabel))
                        
                        Text("Search for Products")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(.label))
                        
                        Text("Find your favorite items")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(0..<5, id: \.self) { _ in
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundColor(Color(.secondarySystemBackground))
                                        .frame(width: 70, height: 70)
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Product Name")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Color(.label))
                                        
                                        Text("$49.99")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color(.label))
                                        
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(.orange)
                                            
                                            Text("4.5 (120)")
                                                .font(.system(size: 11, weight: .regular))
                                                .foregroundColor(Color(.secondaryLabel))
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                        .padding(16)
                    }
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    SearchView()
}
