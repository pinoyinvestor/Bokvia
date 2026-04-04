import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var step = 1
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Step 1: Role
    @State private var selectedRole: OnboardingRole = .customer

    // Customer Steps
    @State private var selectedCategories: Set<String> = []
    @State private var genderChoice: GenderChoice = .everyone
    @State private var locationGranted = false
    @State private var selectedCity = ""

    // Provider fields
    @State private var displayName = ""
    @State private var bio = ""
    @State private var workModes: Set<String> = []
    @State private var phone = ""

    // Salon fields
    @State private var salonName = ""
    @State private var orgNumber = ""
    @State private var salonDescription = ""
    @State private var salonAddress = ""

    private let categoryVisuals: [(slug: String, icon: String, emoji: String, svLabel: String, enLabel: String)] = [
        ("hair", "scissors", "\uD83D\uDC87", "H\u{00e5}r", "Hair"),
        ("nails", "hand.raised.fill", "\uD83D\uDC85", "Naglar", "Nails"),
        ("lashes", "eye.fill", "\uD83D\uDC41\uFE0F", "Fransar", "Lashes"),
        ("skin", "face.smiling.fill", "\uD83E\uDDF4", "Hud", "Skin"),
        ("tattoo", "paintbrush.pointed.fill", "\uD83C\uDFA8", "Tatuering", "Tattoo")
    ]

    private let workModeOptions = [
        ("SALON", "building.2.fill", "Salong", "Salon"),
        ("HOME", "house.fill", "Hemma", "Home"),
        ("MOBILE", "car.fill", "Mobil", "Mobile")
    ]

    // Built by Christos Ferlachidis & Daniel Hedenberg

    private let swedishCities = [
        "Stockholm", "G\u{00f6}teborg", "Malm\u{00f6}", "Uppsala", "Link\u{00f6}ping",
        "\u{00d6}rebro", "V\u{00e4}ster\u{00e5}s", "Helsingborg", "Norrk\u{00f6}ping", "J\u{00f6}nk\u{00f6}ping",
        "Ume\u{00e5}", "Lund", "Bor\u{00e5}s", "Sundsvall", "G\u{00e4}vle"
    ]

    private var totalSteps: Int {
        selectedRole == .customer ? 5 : 3
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if step > 1 {
                    progressBar
                }
                ScrollView {
                    VStack(spacing: 24) {
                        switch step {
                        case 1: roleSelectionStep
                        case 2: detailStep
                        case 3: step3View
                        case 4: step4View
                        case 5: step5View
                        default: EmptyView()
                        }
                    }
                    .padding(24)
                }
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
                    .frame(width: geo.size.width * CGFloat(step - 1) / CGFloat(totalSteps - 1), height: 4)
                    .animation(.easeInOut, value: step)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Step 1: Role Selection

    private var roleSelectionStep: some View {
        VStack(spacing: 20) {
            Text(appState.isSv ? "Vad beskriver dig b\u{00e4}st?" : "What best describes you?")
                .font(.title2.bold())

            Text(appState.isSv ? "Du kan alltid \u{00e4}ndra detta senare" : "You can always change this later")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                roleCard(
                    role: .customer,
                    icon: "person.fill",
                    title: appState.isSv ? "Kund" : "Customer",
                    desc: appState.isSv ? "Boka sk\u{00f6}nhetsbehandlingar" : "Book beauty treatments"
                )
                roleCard(
                    role: .provider,
                    icon: "scissors",
                    title: appState.isSv ? "Ut\u{00f6}vare" : "Provider",
                    desc: appState.isSv ? "Erbjud dina tj\u{00e4}nster" : "Offer your services"
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
        case .customer: customerCategoryStep
        case .provider: providerDetailStep
        case .salon: salonDetailStep
        }
    }

    // MARK: - Customer Step 2: Category Visual Cards

    private var customerCategoryStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(appState.isSv ? "Vad \u{00e4}r du intresserad av?" : "What are you interested in?")
                    .font(.title2.bold())
                Text(appState.isSv ? "V\u{00e4}lj en eller flera kategorier" : "Select one or more categories")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                ForEach(categoryVisuals, id: \.slug) { cat in
                    let selected = selectedCategories.contains(cat.slug)
                    Button {
                        if selected { selectedCategories.remove(cat.slug) }
                        else { selectedCategories.insert(cat.slug) }
                    } label: {
                        VStack(spacing: 8) {
                            Text(cat.emoji)
                                .font(.system(size: 36))
                            Text(appState.isSv ? cat.svLabel : cat.enLabel)
                                .font(.subheadline.bold())
                                .foregroundStyle(selected ? BokviaTheme.accent : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(selected ? BokviaTheme.accentLight : Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selected ? BokviaTheme.accent : .clear, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(alignment: .topTrailing) {
                            if selected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.caption)
                                    .frame(width: 22, height: 22)
                                    .background(BokviaTheme.accent)
                                    .clipShape(Circle())
                                    .padding(6)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Customer Step 3: Gender Selection

    @ViewBuilder
    private var step3View: some View {
        if selectedRole == .customer {
            customerGenderStep
        } else {
            customerFinalStep
        }
    }

    private var customerGenderStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(appState.isSv ? "Vem bokar du f\u{00f6}r?" : "Who are you booking for?")
                    .font(.title2.bold())
                Text(appState.isSv ? "Detta hj\u{00e4}lper oss visa r\u{00e4}tt behandlare" : "This helps us show the right providers")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                ForEach(GenderChoice.allCases, id: \.self) { choice in
                    let isOn = genderChoice == choice
                    Button {
                        genderChoice = choice
                    } label: {
                        VStack(spacing: 10) {
                            Text(choice.emoji)
                                .font(.system(size: 40))
                            Text(choice.label(isSv: appState.isSv))
                                .font(.subheadline.bold())
                                .foregroundStyle(isOn ? BokviaTheme.accent : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(isOn ? BokviaTheme.accentLight : Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isOn ? BokviaTheme.accent : .clear, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(alignment: .topTrailing) {
                            if isOn {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.caption)
                                    .frame(width: 22, height: 22)
                                    .background(BokviaTheme.accent)
                                    .clipShape(Circle())
                                    .padding(6)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Customer Step 4: Location

    @ViewBuilder
    private var step4View: some View {
        if selectedRole == .customer {
            customerLocationStep
        } else {
            EmptyView()
        }
    }

    private var customerLocationStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(appState.isSv ? "Var befinner du dig?" : "Where are you?")
                    .font(.title2.bold())
                Text(appState.isSv ? "Hitta behandlare n\u{00e4}ra dig" : "Find providers near you")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !locationGranted {
                // Request GPS button
                Button {
                    requestLocationPermission()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .font(.title3)
                        Text(appState.isSv ? "Till\u{00e5}t plats" : "Allow location")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(BokviaTheme.accent)
                    .background(BokviaTheme.accentLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(BokviaTheme.accent.opacity(0.4), lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Divider
                HStack {
                    Rectangle().fill(Color(.separator)).frame(height: 1)
                    Text(appState.isSv ? "eller v\u{00e4}lj stad" : "or select city")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Rectangle().fill(Color(.separator)).frame(height: 1)
                }

                // City picker
                Picker(appState.isSv ? "V\u{00e4}lj stad" : "Select city", selection: $selectedCity) {
                    Text(appState.isSv ? "V\u{00e4}lj stad..." : "Select city...").tag("")
                    ForEach(swedishCities, id: \.self) { city in
                        Text(city).tag(city)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title2)
                    Text(appState.isSv ? "Plats aktiverad" : "Location enabled")
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Customer Step 5 / Provider+Salon Step 3: Final

    @ViewBuilder
    private var step5View: some View {
        customerFinalStep
    }

    private var customerFinalStep: some View {
        VStack(spacing: 24) {
            if selectedRole == .customer {
                Text("\uD83C\uDF89")
                    .font(.system(size: 56))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(BokviaTheme.accent)
            }

            Text(appState.isSv ? "Du \u{00e4}r redo!" : "You're all set!")
                .font(.title.bold())

            if selectedRole == .customer {
                // Summary
                VStack(spacing: 1) {
                    if !selectedCategories.isEmpty {
                        summaryRow(
                            label: appState.isSv ? "Dina kategorier" : "Your categories",
                            value: selectedCategories.compactMap { slug in
                                categoryVisuals.first(where: { $0.slug == slug })?.emoji
                            }.joined(separator: " ")
                        )
                    }
                    summaryRow(
                        label: appState.isSv ? "Bokar f\u{00f6}r" : "Booking for",
                        value: genderChoice.emojiLabel(isSv: appState.isSv)
                    )
                    if locationGranted || !selectedCity.isEmpty {
                        summaryRow(
                            label: appState.isSv ? "Plats" : "Location",
                            value: locationGranted
                                ? (appState.isSv ? "\uD83D\uDCCD GPS aktivt" : "\uD83D\uDCCD GPS active")
                                : "\uD83D\uDCCD \(selectedCity)"
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                Text(appState.isSv
                     ? "Tryck p\u{00e5} slutf\u{00f6}r f\u{00f6}r att komma ig\u{00e5}ng"
                     : "Tap finish to get started")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.top, 20)
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Provider Detail Step

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

    // MARK: - Salon Detail Step

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

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        let maxStep = selectedRole == .customer ? 5 : 3
        let canContinue: Bool = {
            if step == 2 && selectedRole == .customer {
                return !selectedCategories.isEmpty
            }
            return true
        }()

        return HStack(spacing: 12) {
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
                if step < maxStep {
                    withAnimation { step += 1 }
                } else {
                    Task { await submitOnboarding() }
                }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(step == maxStep
                             ? (selectedRole == .customer
                                ? (appState.isSv ? "Utforska nu" : "Explore now")
                                : (appState.isSv ? "Slutf\u{00f6}r" : "Finish"))
                             : (appState.isSv ? "N\u{00e4}sta" : "Next"))
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canContinue ? BokviaTheme.accent : BokviaTheme.accent.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading || !canContinue)

            // Skip for location step
            if step == 4 && selectedRole == .customer && !locationGranted && selectedCity.isEmpty {
                Button {
                    withAnimation { step += 1 }
                } label: {
                    Text(appState.isSv ? "Hoppa \u{00f6}ver" : "Skip")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }

    // MARK: - Location Permission

    private func requestLocationPermission() {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        // Check after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let status = manager.authorizationStatus
            locationGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
        }
    }

    // MARK: - Submit

    private func submitOnboarding() async {
        isLoading = true
        errorMessage = nil

        var body: OnboardingRequest

        if selectedRole == .customer {
            let genderMap: [String: String] = ["WOMAN": "female", "MAN": "male"]
            let genderValue: String? = genderChoice == .everyone ? nil : genderMap[genderChoice.rawValue]
            body = OnboardingRequest(
                role: "CUSTOMER",
                categories: Array(selectedCategories),
                gender: genderValue,
                preferredCategoryIds: Array(selectedCategories)
            )
        } else if selectedRole == .provider {
            body = OnboardingRequest(
                role: "PROVIDER",
                displayName: displayName.isEmpty ? nil : displayName,
                bio: bio.isEmpty ? nil : bio,
                workModes: Array(workModes),
                phone: phone.isEmpty ? nil : phone
            )
        } else {
            body = OnboardingRequest(
                role: "SALON",
                salonName: salonName.isEmpty ? nil : salonName,
                orgNumber: orgNumber.isEmpty ? nil : orgNumber,
                salonDescription: salonDescription.isEmpty ? nil : salonDescription,
                salonAddress: salonAddress.isEmpty ? nil : salonAddress
            )
        }

        do {
            let response = try await APIClient.shared.post(
                "/api/auth/onboarding",
                body: body,
                as: OnboardingResponse.self
            )
            if response.success {
                appState.needsOnboarding = false
            } else {
                errorMessage = appState.isSv ? "N\u{00e5}got gick fel" : "Something went wrong"
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

enum GenderChoice: String, CaseIterable {
    case woman = "WOMAN"
    case man = "MAN"
    case everyone = "EVERYONE"

    var emoji: String {
        switch self {
        case .woman: return "\uD83D\uDC69"
        case .man: return "\uD83D\uDC68"
        case .everyone: return "\uD83D\uDC64"
        }
    }

    func label(isSv: Bool) -> String {
        switch self {
        case .woman: return isSv ? "Kvinna" : "Woman"
        case .man: return isSv ? "Man" : "Man"
        case .everyone: return isSv ? "Alla" : "Everyone"
        }
    }

    func emojiLabel(isSv: Bool) -> String {
        "\(emoji) \(label(isSv: isSv))"
    }
}

struct OnboardingRequest: Encodable {
    var role: String
    var categories: [String]?
    var gender: String?
    var dateOfBirth: String?
    var displayName: String?
    var bio: String?
    var workModes: [String]?
    var phone: String?
    var salonName: String?
    var orgNumber: String?
    var salonDescription: String?
    var salonAddress: String?
    var preferredCategoryIds: [String]?
}

struct OnboardingResponse: Decodable {
    let success: Bool
}
