import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var step: ForgotStep = .enterEmail
    @State private var showSuccess = false

    enum ForgotStep {
        case enterEmail
        case enterCode
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    switch step {
                    case .enterEmail:
                        emailStep
                    case .enterCode:
                        codeStep
                    }

                    // Built by Christos Ferlachidis & Daniel Hedenberg

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appState.isSv ? "Avbryt" : "Cancel") { dismiss() }
                }
            }
            .alert(
                appState.isSv ? "Lösenord återställt" : "Password reset",
                isPresented: $showSuccess
            ) {
                Button("OK") { dismiss() }
            } message: {
                Text(appState.isSv
                     ? "Ditt lösenord har ändrats. Du kan nu logga in."
                     : "Your password has been changed. You can now log in.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: step == .enterEmail ? "lock.fill" : "envelope.badge.fill")
                .font(.system(size: 44))
                .foregroundStyle(BokviaTheme.accent)
                .padding(.top, 20)

            Text(appState.isSv ? "Glömt lösenord" : "Forgot password")
                .font(.title2.bold())

            Text(step == .enterEmail
                 ? (appState.isSv ? "Ange din e-post så skickar vi en återställningskod" : "Enter your email and we'll send you a reset code")
                 : (appState.isSv ? "Ange koden du fick via e-post" : "Enter the code you received by email"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Step 1: Email

    private var emailStep: some View {
        VStack(spacing: 16) {
            TextField(appState.isSv ? "E-post" : "Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                Task { await requestReset() }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(appState.isSv ? "Skicka kod" : "Send code")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(BokviaTheme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(email.isEmpty || isLoading)
            .opacity(email.isEmpty ? 0.6 : 1)
        }
    }

    // MARK: - Step 2: Code + New Password

    private var codeStep: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(appState.isSv ? "Kolla din e-post" : "Check your email")
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            TextField(appState.isSv ? "Återställningskod" : "Reset code", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            SecureField(appState.isSv ? "Nytt lösenord (minst 8 tecken)" : "New password (min 8 characters)", text: $newPassword)
                .textContentType(.newPassword)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            SecureField(appState.isSv ? "Bekräfta lösenord" : "Confirm password", text: $confirmPassword)
                .textContentType(.newPassword)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                Task { await resetPassword() }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(appState.isSv ? "Återställ lösenord" : "Reset password")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(BokviaTheme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isResetValid || isLoading)
            .opacity(!isResetValid ? 0.6 : 1)

            Button {
                step = .enterEmail
                errorMessage = nil
            } label: {
                Text(appState.isSv ? "Skicka koden igen" : "Resend code")
                    .font(.subheadline)
                    .foregroundStyle(BokviaTheme.accent)
            }
        }
    }

    private var isResetValid: Bool {
        !code.isEmpty && newPassword.count >= 8 && newPassword == confirmPassword
    }

    // MARK: - API Calls

    private func requestReset() async {
        isLoading = true
        errorMessage = nil
        do {
            let body = ForgotPasswordRequest(email: email.lowercased().trimmingCharacters(in: .whitespaces))
            let _ = try await APIClient.shared.postNoAuth(
                "/api/auth/forgot-password",
                body: body,
                as: ForgotPasswordResponse.self
            )
            withAnimation { step = .enterCode }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func resetPassword() async {
        guard newPassword == confirmPassword else {
            errorMessage = appState.isSv ? "Lösenorden matchar inte" : "Passwords don't match"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let body = ResetPasswordRequest(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                code: code,
                newPassword: newPassword
            )
            let _ = try await APIClient.shared.postNoAuth(
                "/api/auth/reset-password",
                body: body,
                as: ForgotPasswordResponse.self
            )
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Request/Response Models

struct ForgotPasswordRequest: Encodable {
    let email: String
}

struct ResetPasswordRequest: Encodable {
    let email: String
    let code: String
    let newPassword: String
}

struct ForgotPasswordResponse: Decodable {
    let success: Bool
}
