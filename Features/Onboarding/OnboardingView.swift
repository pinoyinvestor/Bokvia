import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var step = 1
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Step 1: Role
    @State private var selectedRole: OnboardingRole = .customer

    // Step 2 Customer
    @State private var selectedCategories: Set<String> = []
    @State private var gender = ""
    @State private var dateOfBirth = Date()
    @State private var hasSetDob = false

    // Step 2 Provider
    @State private var displayName = ""
    @State private var bio = ""
    @State private var workModes: Set<String> = []
    @State private var phone = ""

    // Step 2 Salon
    @State private var salonName = ""
    @State private var orgNumber = ""
    @State private var salonDescription = ""
    @State private var salonAddress = ""

    private let categories = [
        ("hair", "scissors", "Hår", "Hair"),
        ("nails", "hand.raised.fill", "Naglar", "Nails"),
        ("lashes", "eye.fill", "Fransar", "Lashes"),
        ("skin", "face.smiling.fill", "Hud", "Skin"),
        ("tattoo", "paintbrush.pointed.fill", "Tatuering", "Tattoo")
    ]

    private let workModeOptions = [
        ("SALON", "building.2.fill", "Salong", "Salon"),
        ("HOME", "house.fill", "Hemma", "Home"),
        ("MOBILE", "car.fill", "Mobil", "Mobile")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    VStack(spacing: 24) {
                        switch step {
                        case 1: roleSelectionStep
                        case 2: detailStep
                        case 3: finalStep
                        default: EmptyView()
                        }
                    }
                    .padding(24)
                }
                // Built by Christos Ferlachidis & Daniel Hedenberg
                navigationButtons
            }
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 4)
                Rectangle()
                    .fill(BokviaTheme.accent)
                    .frame(width: geo.size.width * CGFloat(step) / 3.0, height: 4)
                    .animation(.easeInOut, value: step)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Step 1: Role Selection

    private var roleSelectionStep: some View {
        VStack(spacing: 20) {
            Text(appState.isSv ? "Vad beskriver dig bäst?" : "What best describes you?")
                .font(.title2.bold())

            Text(appState.isSv ? "Du kan alltid ändra detta senare" : "You can always change this later")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                roleCard(
                    role: .customer,
                    icon: "person.fill",
                    title: appState.isSv ? "Kund" : "Customer",
                    desc: appState.isSv ? "Boka skönhetsbehandlingar" : "Book beauty treatments"
                )
                roleCard(
                    role: .provider,
                    icon: "scissors",
                    title: appState.isSv ? "Utövare" : "Provider",
                    desc: appState.isSv ? "Erbjud dina tjänster" : "Offer your services"
                )
                roleCard(
                    role: .salon,
                    icon: "building.2.fill",
                    title: appState.isSv ? "Salong" : "Salon",
                    desc: appState.isSv ? "Hantera din salong" : "Manage your salon"
                )
            }
        }
    }

    private func roleCard(role: OnboardingRole, icon: String, title: String, desc: String) -> some View {
        Button {
            selectedRole = role
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(selectedRole == role ? .white : BokviaTheme.accent)
                    .frame(width: 48, height: 48)
                    .background(selectedRole == role ? BokviaTheme.accent : BokviaTheme.accentLight)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if selectedRole == role {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BokviaTheme.accent)
                        .font(.title3)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedRole == role ? BokviaTheme.accent : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Step 2: Detail Step

    @ViewBuilder
    private var detailStep: some View {
        switch selectedRole {
        case .customer: customerDetailStep
        case .provider: providerDetailStep
        case .salon: salonDetailStep
        }
    }

    private var customerDetailStep: some View {
        VStack(spacing: 20) {
            Text(appState.isSv ? "Berätta om dig" : "Tell us about yourself")
                .font(.title2.bold())

            // Categories
            VStack(alignment: .leading, spacing: 10) {
                Text(appState.isSv ? "Vad är du intresserad av?" : "What are you interested in?")
                    .font(.subheadline.bold())

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                    ForEach(categories, id: \.0) { cat in
                        let selected = selectedCategories.contains(cat.0)
                        Button {
                            if selected { selectedCategories.remove(cat.0) }
                            else { selectedCategories.insert(cat.0) }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: cat.1)
                                    .font(.title3)
                                Text(appState.isSv ? cat.2 : cat.3)
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selected ? BokviaTheme.accentLight : Color(.secondarySystemBackground))
                            .foregroundStyle(selected ? BokviaTheme.accent : .primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selected ? BokviaTheme.accent : .clear, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }

            // Gender
            VStack(alignment: .leading, spacing: 8) {
                Text(appState.isSv ? "Kön" : "Gender")
                    .font(.subheadline.bold())
                Picker("", selection: $gender) {
                    Text(appState.isSv ? "Välj" : "Select").tag("")
                    Text(appState.isSv ? "Kvinna" : "Female").tag("FEMALE")
                    Text(appState.isSv ? "Man" : "Male").tag("MALE")
                    Text(appState.isSv ? "Annat" : "Other").tag("OTHER")
                }
                .pickerStyle(.segmented)
            }

            // Date of birth
            VStack(alignment: .leading, spacing: 8) {
                Text(appState.isSv ? "Födelsedatum" : "Date of birth")
                    .font(.subheadline.bold())
                DatePicker("", selection: $dateOfBirth, in: ...Date.now, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .onChange(of: dateOfBirth) { _, _ in hasSetDob = true }
            }
        }
    }

    private var providerDetailStep: some View {
        VStack(spacing: 20) {
            Text(appState.isSv ? "Din profil" : "Your profile")
                .font(.title2.bold())

            VStack(spacing: 12) {
                TextField(appState.isSv ? "Visningsnamn" : "Display name", text: $displayName)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                TextField(appState.isSv ? "Bio (kort beskrivning)" : "Bio (short description)", text: $bio, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                TextField(appState.isSv ? "Telefon" : "Phone", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Work modes
            VStack(alignment: .leading, spacing: 10) {
                Text(appState.isSv ? "Hur jobbar du?" : "How do you work?")
                    .font(.subheadline.bold())

                ForEach(workModeOptions, id: \.0) { mode in
                    let selected = workModes.contains(mode.0)
                    Button {
                        if selected { workModes.remove(mode.0) }
                        else { workModes.insert(mode.0) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: mode.1)
                                .foregroundStyle(selected ? BokviaTheme.accent : .secondary)
                            Text(appState.isSv ? mode.2 : mode.3)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(BokviaTheme.accent)
                            }
                        }
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selected ? BokviaTheme.accent : .clear, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private var salonDetailStep: some View {
        VStack(spacing: 20) {
            Text(appState.isSv ? "Din salong" : "Your salon")
                .font(.title2.bold())

            VStack(spacing: 12) {
                TextField(appState.isSv ? "Salongnamn" : "Salon name", text: $salonName)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                TextField(appState.isSv ? "Organisationsnummer" : "Organization number", text: $orgNumber)
                    .keyboardType(.numberPad)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                TextField(appState.isSv ? "Beskrivning" : "Description", text: $salonDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                TextField(appState.isSv ? "Adress" : "Address", text: $salonAddress)
                    .textContentType(.fullStreetAddress)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Step 3: Final

    private var finalStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(BokviaTheme.accent)

            Text(appState.isSv ? "Du är redo!" : "You're all set!")
                .font(.title.bold())

            Text(appState.isSv
                 ? "Tryck på slutför för att komma igång"
                 : "Tap finish to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if step > 1 {
                Button {
                    withAnimation { step -= 1 }
                } label: {
                    Text(appState.isSv ? "Tillbaka" : "Back")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.primary)
            }

            Button {
                if step < 3 {
                    withAnimation { step += 1 }
                } else {
                    Task { await submitOnboarding() }
                }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(step == 3
                             ? (appState.isSv ? "Slutför" : "Finish")
                             : (appState.isSv ? "Nästa" : "Next"))
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(BokviaTheme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }

    // MARK: - Submit

    private func submitOnboarding() async {
        isLoading = true
        errorMessage = nil

        let dobString: String? = hasSetDob ? ISO8601DateFormatter().string(from: dateOfBirth) : nil

        let body = OnboardingRequest(
            role: selectedRole.rawValue,
            categories: selectedRole == .customer ? Array(selectedCategories) : nil,
            gender: selectedRole == .customer && !gender.isEmpty ? gender : nil,
            dateOfBirth: selectedRole == .customer ? dobString : nil,
            displayName: selectedRole == .provider ? displayName : nil,
            bio: selectedRole == .provider ? bio : nil,
            workModes: selectedRole == .provider ? Array(workModes) : nil,
            phone: selectedRole == .provider && !phone.isEmpty ? phone : nil,
            salonName: selectedRole == .salon ? salonName : nil,
            orgNumber: selectedRole == .salon && !orgNumber.isEmpty ? orgNumber : nil,
            salonDescription: selectedRole == .salon && !salonDescription.isEmpty ? salonDescription : nil,
            salonAddress: selectedRole == .salon && !salonAddress.isEmpty ? salonAddress : nil
        )

        do {
            let response = try await APIClient.shared.post(
                "/api/auth/onboarding",
                body: body,
                as: OnboardingResponse.self
            )
            if response.success {
                appState.needsOnboarding = false
            } else {
                errorMessage = appState.isSv ? "Något gick fel" : "Something went wrong"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Models

enum OnboardingRole: String, CaseIterable {
    case customer = "CUSTOMER"
    case provider = "PROVIDER"
    case salon = "SALON"
}

struct OnboardingRequest: Encodable {
    let role: String
    let categories: [String]?
    let gender: String?
    let dateOfBirth: String?
    let displayName: String?
    let bio: String?
    let workModes: [String]?
    let phone: String?
    let salonName: String?
    let orgNumber: String?
    let salonDescription: String?
    let salonAddress: String?
}

struct OnboardingResponse: Decodable {
    let success: Bool
}
