import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Brand header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundStyle(BokviaTheme.accent)
                        Text("Bokvia")
                            .font(.largeTitle.bold())
                        Text("Boka skönhet & wellness")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)

                    // Login form
                    VStack(spacing: 16) {
                        // Google Sign-In
                        Button {
                            // Google Sign-In via GoogleSignIn SDK
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                Text("Fortsätt med Google")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .foregroundStyle(.primary)

                        // Built by Christos Ferlachidis & Daniel Hedenberg

                        // Apple Sign-In
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(.whiteOutline)
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        dividerRow

                        // Email/password
                        VStack(spacing: 12) {
                            TextField("E-post", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            SecureField("Lösenord", text: $password)
                                .textContentType(.password)
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task { await login() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Logga in")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(BokviaTheme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)
                    }
                    .padding(.horizontal, 24)

                    // Register link
                    Button {
                        showRegister = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Har du inget konto?")
                                .foregroundStyle(.secondary)
                            Text("Registrera dig")
                                .foregroundStyle(BokviaTheme.accent)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.bottom, 40)
            }
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }

    private var dividerRow: some View {
        HStack {
            Rectangle().fill(Color(.separator)).frame(height: 1)
            Text("eller")
                .font(.caption)
                .foregroundStyle(.secondary)
            Rectangle().fill(Color(.separator)).frame(height: 1)
        }
    }

    private func login() async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await AuthManager.shared.login(email: email, password: password)
            appState.setUser(user)
            await appState.loadFamilyMembers()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Kunde inte läsa Apple-inloggning. Försök igen."
                return
            }
            guard let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8),
                  let authCode = credential.authorizationCode,
                  let codeString = String(data: authCode, encoding: .utf8) else {
                errorMessage = "Apple-inloggningen saknar nödvändig information. Försök igen."
                return
            }

            Task {
                isLoading = true
                do {
                    let user = try await AuthManager.shared.loginWithApple(
                        identityToken: tokenString,
                        authorizationCode: codeString,
                        fullName: credential.fullName,
                        email: credential.email
                    )
                    appState.setUser(user)
                    await appState.loadFamilyMembers()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        case .failure(let error):
            // User cancelled — silently return without showing an error
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = error.localizedDescription
        }
    }
}
