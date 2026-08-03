//
//  SignInView.swift
//  WorkoutApp
//
//  Created by Oliver Barta on 2026-08-03.
//

import SwiftUI

struct SignInView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var password = ""
    @State private var isSigningUp = false
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 16) {
            Text(isSigningUp ? "Create Account" : "Sign In")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 40)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            Button {
                Task { await submit() }
            } label: {
                if isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(isSigningUp ? "Sign Up" : "Sign In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.liquidGlass(tintColor: Theme.primary))
            .disabled(email.isEmpty || password.isEmpty || isSubmitting)

            Button {
                isSigningUp.toggle()
                errorMessage = nil
            } label: {
                Text(isSigningUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.footnote)
            }
            .buttonStyle(.liquidGlass(tintColor: Theme.grey))
        }
        .padding()
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil

        do {
            if isSigningUp {
                try await authManager.signUp(email: email, password: password)
            } else {
                try await authManager.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}

#Preview {
    SignInView()
        .environment(AuthManager())
}
