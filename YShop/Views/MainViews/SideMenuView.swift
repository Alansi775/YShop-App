//
//  SideMenuView.swift
//  YShop
//
//  Created by Mohammed on 27.12.2024.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct SideMenuViewTemp: View {
    @State var presentSideMenu = true
    
    var body: some View {
        ZStack {
            SideMenuView()
        }.background(.black)
    }
    
    @ViewBuilder
    private func SideMenuView() -> some View {
        SideView(isShowing: $presentSideMenu, content: AnyView(SideMenuViewContents(presentSideMenu: $presentSideMenu)), direction: .leading)
    }
}

struct SideMenuViewTemp_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuViewTemp()
    }
}

struct SideMenuViewContents: View {
    @Binding var presentSideMenu: Bool
    
    @State private var selectedCategory: Int = 0
    @State private var name: String = ""
    @State private var surname: String = ""

    var categories = ["All", "Apparel", "Dress", "T-Shirt", "Bag"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Top Section: Account Info and Close Button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)

                    Text("\(name) \(surname)")
                        .font(Font.custom("TenorSans", size: 16))
                        .foregroundColor(.black)

                    Text("Account")
                        .font(Font.custom("TenorSans", size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                Button {
                    presentSideMenu.toggle()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal)
            .padding(.top, 40)

            // Categories Section
            HStack(spacing: 10) {
                GenderView(isSelected: selectedCategory == 0, title: "WOMEN")
                    .onTapGesture {
                        selectedCategory = 0
                    }
                GenderView(isSelected: selectedCategory == 1, title: "MEN")
                    .onTapGesture {
                        selectedCategory = 1
                    }
                GenderView(isSelected: selectedCategory == 2, title: "KIDS")
                    .onTapGesture {
                        selectedCategory = 2
                    }
            }
            .padding(.horizontal)

            ForEach(categories, id: \.self) { category in
                CategoryItem(title: category) {
                    // Category action
                }
            }

            Spacer()

            // Store Section
            VStack(spacing: 10) {
                Button {
                    // Call action
                } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray)

                        Text("(+90) 39 255 4609")
                            .font(Font.custom("TenorSans", size: 16))
                            .foregroundColor(.black)
                    }
                }

                Button {
                    // Store locator action
                } label: {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray)

                        Text("Store Locator")
                            .font(Font.custom("TenorSans", size: 16))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // Logout Button
            Button {
                logout()
            } label: {
                HStack {
                    Image(systemName: "arrow.backward.square")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.BodyGrey)

                    Text("Logout")
                        .font(Font.custom("TenorSans", size: 16))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding([.leading, .trailing], 20)
        .background(Color.white)
        .onAppear {
            fetchUserData()
        }
    }

    func fetchUserData() {
        // Replace this with Firestore data fetching
        let userId = Auth.auth().currentUser?.uid ?? ""
        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.getDocument { snapshot, error in
            if let data = snapshot?.data() {
                name = data["name"] as? String ?? "Unknown"
                surname = data["surname"] as? String ?? "User"
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            presentSideMenu = false // Close side menu
            // Navigate back to the sign-in screen if needed
        } catch let error as NSError {
            print("Logout failed: \(error.localizedDescription)")
        }
    }

    @ViewBuilder
    func CategoryItem(title: String, action: @escaping (() -> Void)) -> some View {
        Button {
            action()
        } label: {
            VStack(alignment: .leading) {
                Text(title)
                    .font(Font.custom("TenorSans", size: 16))
                    .foregroundColor(.BodyGrey)
            }
        }
        .frame(height: 50)
        .padding(.leading, 30)
    }
}
