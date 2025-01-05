//
//  HomeViews.swift
//  YShop
//
//  Created by Mohammed on 26.12.2024.
//


import SwiftUI
import Firebase
import FirebaseAuth

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var name = ""
    @State private var surname = ""
    @State private var showSignUp = false
    @State private var message = ""
    @State private var userIsLoggedIn = false

    var body: some View {
        Group {
            if userIsLoggedIn {
                HomeView() // Navigate to HomeView if user is logged in
            } else {
                ZStack {
                    Color.white.edgesIgnoringSafeArea(.all)
                    VStack(spacing: 20) {
                        Text("Welcome")
                            .font(Font.custom("TenorSans", size: 40))
                            .foregroundColor(.black)

                        if showSignUp {
                            TextField("Name", text: $name)
                                .textContentType(.name)
                                .autocapitalization(.words)
                                .foregroundColor(.black)
                                .font(Font.custom("TenorSans", size: 16))
                                .textFieldStyle(.plain)

                            Rectangle()
                                .frame(width: 350, height: 1)
                                .foregroundColor(.gray)

                            TextField("Surname", text: $surname)
                                .textContentType(.name)
                                .autocapitalization(.words)
                                .foregroundColor(.black)
                                .font(Font.custom("TenorSans", size: 16))
                                .textFieldStyle(.plain)

                            Rectangle()
                                .frame(width: 350, height: 1)
                                .foregroundColor(.gray)
                        }

                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(.black)
                            .font(Font.custom("TenorSans", size: 16))
                            .textFieldStyle(.plain)

                        Rectangle()
                            .frame(width: 350, height: 1)
                            .foregroundColor(.gray)

                        HStack {
                            if showPassword {
                                TextField("Password", text: $password)
                                    .foregroundColor(.black)
                                    .font(Font.custom("TenorSans", size: 16))
                            } else {
                                SecureField("Password", text: $password)
                                    .foregroundColor(.black)
                                    .font(Font.custom("TenorSans", size: 16))
                            }
                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.BodyGrey)
                            }
                        }
                        .padding(.horizontal)

                        Rectangle()
                            .frame(width: 350, height: 1)
                            .foregroundColor(.gray)

                        if showSignUp {
                            Button {
                                register()
                            } label: {
                                Text("Sign Up")
                                    .frame(width: 100, height: 30)
                                    .foregroundColor(.white)
                                    .background(
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color.BodyGrey)
                                    )
                            }
                        } else {
                            Button {
                                login()
                            } label: {
                                Text("Login")
                                    .frame(width: 100, height: 30)
                                    .foregroundColor(.white)
                                    .background(
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color.BodyGrey)
                                    )
                            }
                        }

                        Button {
                            showSignUp.toggle()
                        } label: {
                            Text(showSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up")
                                .foregroundColor(.BodyGrey)
                        }

                        Text(message)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, 10)
                    }
                    .frame(width: 350)
                    .onAppear {
                        checkAuthState()
                    }
                }
            }
        }
    }

    func checkAuthState() {
        // Check if user is already logged in
        if Auth.auth().currentUser != nil {
            userIsLoggedIn = true
        }
    }

    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                message = error.localizedDescription
            } else {
                userIsLoggedIn = true // Navigate to HomeView
            }
        }
    }

    func register() {
        guard !name.isEmpty, !surname.isEmpty else {
            message = "Name and Surname cannot be empty."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                message = error.localizedDescription
            } else {
                saveUserData()
                message = "Account created successfully!"
                showSignUp = false
            }
        }
    }

    func saveUserData() {
        let userId = Auth.auth().currentUser?.uid ?? ""
        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.setData(["name": name, "surname": surname, "email": email]) { error in
            if let error = error {
                print("Failed to save user data: \(error.localizedDescription)")
            }
        }
    }
}
