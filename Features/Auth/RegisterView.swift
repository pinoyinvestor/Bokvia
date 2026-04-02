import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var step: RegisterStep = .roleSelection
    @State private var selectedRole: RegisterRole = .customer
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Provider fields
    @State private var displayName = ""
    @State private var bio = ""
    @State private var phone = ""

    // Salon fields
    @State private var salonName = ""
    @State private var orgNumber = ""

    enum RegisterStep {
        case roleSelection
        case form
    }

    enum RegisterRole: String, CaseIterable {
        case customer = "CUSTOMER"
        case provider = "PROVIDER"
        case salon = "SALON"
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var isValid: Bool {
        guard !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && password.count >= 8 else {
            return false
        }
        switch selectedRole {
        case .customer: return true
        case .provider: return !displayName.isEmpty
        case .salon: return !salonName.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    switch step {
                    case .roleSelection:
                        roleSelectionView
                    case .form:
                        formView
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appState.isSv ? "Avbryt" : "Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Role Selection

    private var roleSelectionView: some View {
        VStack(spacing: 20) {
            Text(appState.isSv ? "Skapa konto" : "Create account")
                .font(.title2.bold())
                .padding(.top, 20)

            Text(appState.isSv ? "Välj kontotyp" : "Choose account type")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                registerRoleCard(
                    role: .customer,
                    icon: "person.fill",
                    title: appState.isSv ? "Kund" : "Customer",
                    desc: appState.isSv ? "Boka behandlingar" : "Book treatments"
                )
                registerRoleCard(
                    role: .provider,
                    icon: "scissors",
                    title: appState.isSv ? "Utövare" : "Provider",
                    desc: appState.isSv ? "Erbjud dina tjänster" : "Offer your services"
                )
                registerRoleCard(
                    role: .salon,
                    icon: "building.2.fill",
                    title: appState.isSv ? "Salong" : "Salon",
                    desc: appState.isSv ? "Hantera din salong" : "Manage your salon"
                )
            }
            .padding(.horizontal, 24)

            Button {
                withAnimation { step = .form }
            } label: {
                Text(appState.isSv ? "Fortsätt" : "Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(BokviaTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
        }
    }

    private func registerRoleCard(role: RegisterRole, icon: String, title: String, desc: String) -> some View {
        Button {
            selectedRole = role
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(selectedRole == role ? .white : BokviaTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(selectedRole == role ? BokviaTheme.accent : BokviaTheme.accentLight)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(.primary)
                    Text(desc).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if selectedRole == role {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BokviaTheme.accent)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedRole == role ? BokviaTheme.accent : .clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Form

    private var formView: some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    withAnimation { step = .roleSelection }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(appState.isSv ? "Tillbaka" : "Back")
                    }
                    .font(.subheadline)
                    .foregroundStyle(BokviaTheme.accent)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Text(appState.isSv ? "Skapa konto" : "Create account")
                .font(.title2.bold())

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    TextField(appState.isSv ? "Förnamn" : "First name", text: $firstName)
                        .textContentType(.givenName)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    TextField(appState.isSv ? "Efternamn" : "Last name", text: $lastName)
                        .textContentType(.familyName)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                TextField(appState.isSv ? "E-post" : "Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField(appState.isSv ? "Lösenord (minst 8 tecken)" : "Password (min 8 characters)", text: $password)
                    .textContentType(.newPassword)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Role-specific fields
                if selectedRole == .provider {
                    providerFields
                } else if selectedRole == .salon {
                    salonFields
                }
            }
            .padding(.horizontal, 24)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Button {
                Task { await register() }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(appState.isSv ? "Registrera" : "Register")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(BokviaTheme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isValid || isLoading)
            .opacity(!isValid ? 0.6 : 1)
            .padding(.horizontal, 24)

            // Legal agreement text
            HStack(spacing: 0) {
                Text(appState.isSv ? "Genom att registrera dig godkänner du våra " : "By registering you agree to our ")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                NavigationLink {
                    TermsView()
                } label: {
                    Text(appState.isSv ? "villkor" : "Terms")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(BokviaTheme.accent)
                }
                Text(appState.isSv ? " och " : " and ")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Text(appState.isSv ? "integritetspolicy" : "Privacy Policy")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(BokviaTheme.accent)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var providerFields: some View {
        VStack(spacing: 12) {
            Text(appState.isSv ? "Utövaruppgifter" : "Provider details")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField(appState.isSv ? "Visningsnamn" : "Display name", text: $displayName)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            TextField(appState.isSv ? "Bio (valfritt)" : "Bio (optional)", text: $bio, axis: .vertical)
                .lineLimit(2...4)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            TextField(appState.isSv ? "Telefon (valfritt)" : "Phone (optional)", text: $phone)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var salonFields: some View {
        VStack(spacing: 12) {
            Text(appState.isSv ? "Salonguppgifter" : "Salon details")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField(appState.isSv ? "Salongnamn" : "Salon name", text: $salonName)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            TextField(appState.isSv ? "Org.nummer (valfritt)" : "Org number (optional)", text: $orgNumber)
                .keyboardType(.numberPad)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Register

    private func register() async {
        isLoading = true
        errorMessage = nil
        do {
            let body = RegisterWithRoleRequest(
                firstName: firstName,
                lastName: lastName,
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                password: password,
                role: selectedRole.rawValue,
                displayName: selectedRole == .provider ? displayName : nil,
                bio: selectedRole == .provider && !bio.isEmpty ? bio : nil,
                phone: selectedRole == .provider && !phone.isEmpty ? phone : nil,
                salonName: selectedRole == .salon ? salonName : nil,
                orgNumber: selectedRole == .salon && !orgNumber.isEmpty ? orgNumber : nil
            )
            let response = try await APIClient.shared.postAuth(
                "/api/auth/register",
                body: body,
                as: AuthResponse.self
            )
            await PushManager.shared.sendPendingToken()
            appState.setUser(response.data.user)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
