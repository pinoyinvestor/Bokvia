import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showLanguagePicker = false
    @State private var showDeleteWarning = false
    @State private var showDeleteSheet = false
    @State private var showChangePassword = false
    @State private var showFamilyManager = false
    @State private var showRoleSwitcher = false
    @State private var showAvatarActionSheet = false
    @State private var imagePicker = ImagePickerManager()
    @State private var photoSelection: PhotosPickerItem?
    @State private var isUploadingAvatar = false

    var body: some View {
        List {
            // User header
            Section {
                HStack(spacing: 14) {
                    ZStack(alignment: .bottomTrailing) {
                        AsyncImage(url: URL(string: appState.currentUser?.avatarUrl ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(BokviaTheme.accentLight)
                                .overlay(Text(appState.currentUser?.initials ?? "?").font(.title3.bold()).foregroundStyle(BokviaTheme.accent))
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                        .overlay {
                            if isUploadingAvatar {
                                Circle().fill(.ultraThinMaterial)
                                ProgressView()
                            }
                        }

                        Image(systemName: "camera.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(BokviaTheme.accent)
                            .clipShape(Circle())
                    }
                    .onTapGesture { showAvatarActionSheet = true }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.currentUser?.fullName ?? "")
                            .font(.headline)
                        Text(appState.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Role switcher — only show if user has multiple profiles
                if appState.profiles.count > 1 {
                    Button {
                        showRoleSwitcher = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: roleIcon(appState.activeProfileType))
                                .foregroundStyle(BokviaTheme.accent)
                            Text(roleLabel(appState.activeProfileType))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(appState.isSv ? "Byt roll" : "Switch role")
                                .font(.caption)
                                .foregroundStyle(BokviaTheme.accent)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .accessibilityLabel(appState.isSv ? "Byt roll" : "Switch role")
                }
            }

            // Features
            Section {
                NavigationLink {
                    SavedView()
                } label: {
                    Label(appState.isSv ? "Sparade" : "Saved", systemImage: "bookmark")
                }

                // Built by Christos Ferlachidis & Daniel Hedenberg

                NavigationLink {
                    NotificationsView()
                } label: {
                    Label(appState.isSv ? "Notiser" : "Notifications", systemImage: "bell")
                }

                Button {
                    showFamilyManager = true
                } label: {
                    Label(appState.isSv ? "Familjemedlemmar" : "Family members", systemImage: "person.2")
                        .foregroundStyle(.primary)
                }
            }

            // Settings
            Section(appState.isSv ? "Inställningar" : "Settings") {
                Button {
                    showLanguagePicker = true
                } label: {
                    HStack {
                        Label(appState.isSv ? "Språk" : "Language", systemImage: "globe")
                        Spacer()
                        Text(appState.language == "sv" ? "Svenska" : "English")
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                }

                HStack {
                    Label(appState.isSv ? "Utseende" : "Appearance", systemImage: "paintbrush")
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { appState.darkMode },
                        set: { appState.darkMode = $0 }
                    ))
                }

                Button {
                    showChangePassword = true
                } label: {
                    Label(appState.isSv ? "Byt lösenord" : "Change password", systemImage: "lock")
                        .foregroundStyle(.primary)
                }
            }

            // Support
            Section {
                NavigationLink {
                    SupportView()
                } label: {
                    Label(appState.isSv ? "Hjälp & support" : "Help & support", systemImage: "questionmark.circle")
                }

                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label(appState.isSv ? "Integritetspolicy" : "Privacy Policy", systemImage: "lock.shield")
                }

                NavigationLink {
                    TermsView()
                } label: {
                    Label(appState.isSv ? "Användarvillkor" : "Terms of Service", systemImage: "doc.text")
                }
            }

            // Danger zone
            Section {
                Button(role: .destructive) {
                    appState.logout()
                } label: {
                    Label(appState.isSv ? "Logga ut" : "Log out", systemImage: "rectangle.portrait.and.arrow.right")
                }

                Button(role: .destructive) {
                    showDeleteWarning = true
                } label: {
                    Label(appState.isSv ? "Radera konto" : "Delete account", systemImage: "trash")
                }
            }
        }
        .navigationTitle(appState.isSv ? "Profil" : "Profile")
        .confirmationDialog(appState.isSv ? "Välj språk" : "Choose language", isPresented: $showLanguagePicker) {
            Button("Svenska") { appState.language = "sv" }
            Button("English") { appState.language = "en" }
        }
        .alert(appState.isSv ? "Radera konto?" : "Delete account?", isPresented: $showDeleteWarning) {
            Button(appState.isSv ? "Fortsätt" : "Continue", role: .destructive) {
                showDeleteSheet = true
            }
            Button(appState.isSv ? "Avbryt" : "Cancel", role: .cancel) {}
        } message: {
            Text(appState.isSv
                 ? "All din data kommer att raderas permanent: bokningar, profil, chatthistorik och foton. Denna åtgärd kan inte ångras."
                 : "All your data will be permanently deleted: bookings, profile, chat history, and photos. This action cannot be undone.")
        }
        .sheet(isPresented: $showDeleteSheet) {
            NavigationStack { DeleteAccountView() }
        }
        .sheet(isPresented: $showFamilyManager) {
            NavigationStack { FamilyView() }
        }
        .sheet(isPresented: $showChangePassword) {
            NavigationStack { ChangePasswordView() }
        }
        .sheet(isPresented: $showRoleSwitcher) {
            NavigationStack { RoleSwitcherView() }
        }
        .confirmationDialog(
            appState.isSv ? "Byt profilbild" : "Change profile photo",
            isPresented: $showAvatarActionSheet,
            titleVisibility: .visible
        ) {
            Button(appState.isSv ? "Ta foto" : "Take photo") {
                imagePicker.requestCamera()
            }
            Button(appState.isSv ? "Välj från bibliotek" : "Choose from library") {
                imagePicker.requestPhotoLibrary()
            }
        }
        .fullScreenCover(isPresented: $imagePicker.showCameraSheet) {
            CameraView(image: $imagePicker.selectedImage)
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $imagePicker.showPhotoPicker, selection: $photoSelection, matching: .images)
        .onChange(of: photoSelection) { _, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    imagePicker.selectedImage = uiImage
                }
            }
        }
        .onChange(of: imagePicker.selectedImage) { _, newImage in
            guard let image = newImage else { return }
            Task { await uploadAvatar(image) }
        }
        .alert(appState.isSv ? "Åtkomst nekad" : "Access denied", isPresented: $imagePicker.showPermissionAlert) {
            Button(appState.isSv ? "Inställningar" : "Settings") { imagePicker.openSettings() }
            Button(appState.isSv ? "Avbryt" : "Cancel", role: .cancel) {}
        } message: {
            Text(imagePicker.permissionAlertMessage)
        }
    }

    private func uploadAvatar(_ image: UIImage) async {
        guard let data = imagePicker.compressImage(image) else { return }
        isUploadingAvatar = true
        do {
            struct AvatarResponse: Decodable { let avatarUrl: String }
            let response = try await APIClient.shared.uploadImage(
                "/api/users/me/avatar",
                imageData: data,
                filename: "avatar.jpg",
                as: AvatarResponse.self
            )
            appState.currentUser = UserSession(
                id: appState.currentUser!.id,
                email: appState.currentUser!.email,
                firstName: appState.currentUser!.firstName,
                lastName: appState.currentUser!.lastName,
                avatarUrl: response.avatarUrl,
                phone: appState.currentUser!.phone,
                gender: appState.currentUser!.gender,
                dateOfBirth: appState.currentUser!.dateOfBirth,
                locale: appState.currentUser!.locale,
                roles: appState.currentUser!.roles,
                activeProfileId: appState.currentUser!.activeProfileId,
                activeProfileType: appState.currentUser!.activeProfileType,
                needsOnboarding: appState.currentUser!.needsOnboarding,
                profiles: appState.currentUser!.profiles
            )
            HapticManager.success()
        } catch {
            HapticManager.error()
        }
        isUploadingAvatar = false
        imagePicker.selectedImage = nil
    }

    private func roleIcon(_ type: String) -> String {
        switch type {
        case "CUSTOMER": return "person.fill"
        case "PROVIDER": return "scissors"
        case "SALON": return "building.2.fill"
        default: return "person.fill"
        }
    }

    private func roleLabel(_ type: String) -> String {
        switch type {
        case "CUSTOMER": return appState.isSv ? "Kund" : "Customer"
        case "PROVIDER": return appState.isSv ? "Frisör" : "Provider"
        case "SALON": return appState.isSv ? "Salong" : "Salon"
        default: return type
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var success = false

    var body: some View {
        Form {
            SecureField("Nuvarande lösenord", text: $currentPassword)
            SecureField("Nytt lösenord (minst 8 tecken)", text: $newPassword)
            // Built by Christos Ferlachidis & Daniel Hedenberg
            if let error = errorMessage {
                Text(error).foregroundStyle(.red).font(.caption)
            }
            if success {
                Text("Lösenord ändrat!").foregroundStyle(.green).font(.caption)
            }
        }
        .navigationTitle("Byt lösenord")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Avbryt") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Spara") {
                    Task { await changePassword() }
                }
                .disabled(currentPassword.isEmpty || newPassword.count < 8 || isLoading)
            }
        }
    }

    private func changePassword() async {
        isLoading = true
        struct Body: Encodable { let currentPassword: String; let newPassword: String }
        do {
            _ = try await APIClient.shared.post("/api/users/me/change-password", body: Body(currentPassword: currentPassword, newPassword: newPassword), as: EmptyResponse.self)
            success = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var confirmText = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var deleted = false

    private var requiredText: String {
        appState.isSv ? "RADERA" : "DELETE"
    }

    private var canDelete: Bool {
        confirmText.trimmingCharacters(in: .whitespaces).uppercased() == requiredText && !isDeleting
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Warning icon
                HStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.top, 8)

                // What gets deleted
                VStack(alignment: .leading, spacing: 12) {
                    Text(appState.isSv ? "Följande data raderas permanent:" : "The following data will be permanently deleted:")
                        .font(.headline)

                    deletionItem(icon: "calendar", text: appState.isSv ? "Alla bokningar och bokningshistorik" : "All bookings and booking history")
                    deletionItem(icon: "person.crop.circle", text: appState.isSv ? "Din profil och kontoinformation" : "Your profile and account information")
                    deletionItem(icon: "bubble.left.and.bubble.right", text: appState.isSv ? "All chatthistorik" : "All chat history")
                    deletionItem(icon: "photo.on.rectangle", text: appState.isSv ? "Uppladdade foton och bilder" : "Uploaded photos and images")
                    deletionItem(icon: "bell", text: appState.isSv ? "Notifikationsinställningar" : "Notification preferences")
                    // Built by Christos Ferlachidis & Daniel Hedenberg
                    deletionItem(icon: "bookmark", text: appState.isSv ? "Sparade favoriter" : "Saved favorites")
                }

                // Data retention notice
                VStack(alignment: .leading, spacing: 8) {
                    Text(appState.isSv ? "Lagringsperiod" : "Data retention")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    Text(appState.isSv
                         ? "Anonymiserade transaktionsuppgifter kan behållas i enlighet med lagkrav (t.ex. bokföringsskyldighet). Dessa kan inte kopplas tillbaka till dig."
                         : "Anonymized transaction records may be retained as required by law (e.g. accounting obligations). These cannot be linked back to you.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Divider()

                // Confirmation input
                VStack(alignment: .leading, spacing: 8) {
                    Text(appState.isSv
                         ? "Skriv \"\(requiredText)\" nedan för att bekräfta:"
                         : "Type \"\(requiredText)\" below to confirm:")
                        .font(.subheadline.bold())

                    TextField(requiredText, text: $confirmText)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 4)
                }

                // Delete button
                Button {
                    Task { await deleteAccount() }
                } label: {
                    HStack {
                        if isDeleting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(appState.isSv ? "Radera mitt konto permanent" : "Permanently delete my account")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canDelete ? Color.red : Color.red.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canDelete)
            }
            .padding(20)
        }
        .navigationTitle(appState.isSv ? "Radera konto" : "Delete account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appState.isSv ? "Avbryt" : "Cancel") { dismiss() }
            }
        }
        .interactiveDismissDisabled(isDeleting)
        .onChange(of: deleted) { _, done in
            if done {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                    KeychainHelper.deleteToken()
                    appState.logout()
                }
            }
        }
        .overlay {
            if deleted {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text(appState.isSv ? "Kontot har raderats" : "Account deleted")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
            }
        }
    }

    @ViewBuilder
    private func deletionItem(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.red.opacity(0.8))
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        errorMessage = nil

        do {
            try await APIClient.shared.delete("/api/users/me")
            deleted = true
        } catch {
            errorMessage = appState.isSv
                ? "Kunde inte radera kontot. Försök igen senare."
                : "Failed to delete account. Please try again later."
        }

        isDeleting = false
    }
}
