import SwiftUI

struct ProviderEditProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var provider: ProviderMeResponse?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    // Editable fields
    @State private var displayName = ""
    @State private var bio = ""
    @State private var bookingMode = "MANUAL"
    @State private var phoneVisible = false
    @State private var preBookingMessages = false
    @State private var acceptSalonBookings = true
    @State private var workModes: Set<String> = []
    @State private var homeVisitCities: [String] = []
    @State private var newCity = ""

    // Auto-book rules
    @State private var autoBookRules: [AutoBookRule] = []
    @State private var showAddRule = false
    @State private var newRuleDay = 1
    @State private var newRuleStart = "09:00"
    @State private var newRuleEnd = "17:00"

    // Services
    @State private var currentServices: [Service] = []
    @State private var availableServices: [Service] = []
    @State private var showAddService = false

    private let workModeOptions = ["AT_SALON", "AT_PROVIDER", "HOME_VISIT"]

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else {
                Form {
                    basicInfoSection
                    bookingModeSection

                    // Built by Christos Ferlachidis & Daniel Hedenberg

                    autoBookSection
                    togglesSection
                    workModesSection
                    homeVisitSection
                    servicesSection

                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle(appState.isSv ? "Redigera profil" : "Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appState.isSv ? "Avbryt" : "Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(appState.isSv ? "Spara" : "Save") {
                    Task { await saveProfile() }
                }
                .disabled(isSaving || displayName.isEmpty)
                .accessibilityLabel(appState.isSv ? "Spara profil" : "Save profile")
            }
        }
        .task { await loadProfile() }
        .sheet(isPresented: $showAddRule) {
            addRuleSheet
        }
    }

    // MARK: - Basic Info

    private var basicInfoSection: some View {
        Section(appState.isSv ? "Grunduppgifter" : "Basic info") {
            TextField(appState.isSv ? "Visningsnamn" : "Display name", text: $displayName)
                .accessibilityLabel(appState.isSv ? "Visningsnamn" : "Display name")
            VStack(alignment: .leading) {
                Text(appState.isSv ? "Bio" : "Bio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $bio)
                    .frame(minHeight: 80)
                    .accessibilityLabel(appState.isSv ? "Biografi" : "Biography")
            }
        }
    }

    // MARK: - Booking Mode

    private var bookingModeSection: some View {
        Section(appState.isSv ? "Bokningsläge" : "Booking mode") {
            Picker(appState.isSv ? "Läge" : "Mode", selection: $bookingMode) {
                Text(appState.isSv ? "Automatisk (direkt)" : "Auto (instant)").tag("INSTANT")
                Text(appState.isSv ? "Manuell (godkänn)" : "Manual (approve)").tag("MANUAL")
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(appState.isSv ? "Bokningsläge" : "Booking mode")
        }
    }

    // MARK: - Auto-Book Rules

    private var autoBookSection: some View {
        Section(appState.isSv ? "Autobokningsregler" : "Auto-book rules") {
            if autoBookRules.isEmpty {
                Text(appState.isSv ? "Inga regler ännu" : "No rules yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(autoBookRules) { rule in
                    HStack {
                        Text(dayName(rule.dayOfWeek))
                            .font(.subheadline)
                        Spacer()
                        Text("\(rule.startTime) - \(rule.endTime)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button(role: .destructive) {
                            Task { await deleteRule(rule.id) }
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .accessibilityLabel(appState.isSv ? "Ta bort regel" : "Delete rule")
                    }
                }
            }

            Button {
                showAddRule = true
            } label: {
                Label(appState.isSv ? "Lägg till regel" : "Add rule", systemImage: "plus")
                    .font(.subheadline)
            }
            .accessibilityLabel(appState.isSv ? "Lägg till autobokningsregel" : "Add auto-book rule")
        }
    }

    private var addRuleSheet: some View {
        NavigationStack {
            Form {
                Picker(appState.isSv ? "Dag" : "Day", selection: $newRuleDay) {
                    ForEach(1...7, id: \.self) { day in
                        Text(dayName(day)).tag(day)
                    }
                }
                .accessibilityLabel(appState.isSv ? "Välj dag" : "Select day")

                TextField(appState.isSv ? "Starttid (HH:MM)" : "Start time (HH:MM)", text: $newRuleStart)
                    .accessibilityLabel(appState.isSv ? "Starttid" : "Start time")
                TextField(appState.isSv ? "Sluttid (HH:MM)" : "End time (HH:MM)", text: $newRuleEnd)
                    .accessibilityLabel(appState.isSv ? "Sluttid" : "End time")
            }
            .navigationTitle(appState.isSv ? "Ny regel" : "New rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appState.isSv ? "Avbryt" : "Cancel") { showAddRule = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(appState.isSv ? "Lägg till" : "Add") {
                        Task { await addRule() }
                    }
                    .accessibilityLabel(appState.isSv ? "Lägg till regel" : "Add rule")
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Toggles

    private var togglesSection: some View {
        Section(appState.isSv ? "Inställningar" : "Settings") {
            Toggle(appState.isSv ? "Telefon synlig" : "Phone visible", isOn: $phoneVisible)
                .accessibilityLabel(appState.isSv ? "Visa telefonnummer" : "Show phone number")
            Toggle(appState.isSv ? "Förbokning meddelanden" : "Pre-booking messages", isOn: $preBookingMessages)
                .accessibilityLabel(appState.isSv ? "Förbokning meddelanden" : "Pre-booking messages")
            Toggle(appState.isSv ? "Acceptera salongsbokningar" : "Accept salon bookings", isOn: $acceptSalonBookings)
                .accessibilityLabel(appState.isSv ? "Acceptera salongsbokningar" : "Accept salon bookings")
        }
    }

    // MARK: - Work Modes

    private var workModesSection: some View {
        Section(appState.isSv ? "Arbetsplatser" : "Work modes") {
            ForEach(workModeOptions, id: \.self) { mode in
                Toggle(workModeLabel(mode), isOn: Binding(
                    get: { workModes.contains(mode) },
                    set: { enabled in
                        if enabled { workModes.insert(mode) } else { workModes.remove(mode) }
                    }
                ))
                .accessibilityLabel(workModeLabel(mode))
            }
        }
    }

    private func workModeLabel(_ mode: String) -> String {
        switch mode {
        case "AT_SALON": return appState.isSv ? "På salong" : "At salon"
        case "AT_PROVIDER": return appState.isSv ? "Hemma / Egen lokal" : "Home / Own premises"
        case "HOME_VISIT": return appState.isSv ? "Hembesök" : "Home visit"
        default: return mode
        }
    }

    // MARK: - Home Visit Cities

    private var homeVisitSection: some View {
        Section(appState.isSv ? "Hembesöksstäder" : "Home visit cities") {
            ForEach(homeVisitCities, id: \.self) { city in
                HStack {
                    Text(city)
                    Spacer()
                    Button(role: .destructive) {
                        homeVisitCities.removeAll { $0 == city }
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel(appState.isSv ? "Ta bort \(city)" : "Remove \(city)")
                }
            }

            HStack {
                TextField(appState.isSv ? "Ny stad..." : "New city...", text: $newCity)
                Button {
                    let city = newCity.trimmingCharacters(in: .whitespaces)
                    guard !city.isEmpty else { return }
                    homeVisitCities.append(city)
                    newCity = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(BokviaTheme.accent)
                }
                .disabled(newCity.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel(appState.isSv ? "Lägg till stad" : "Add city")
            }
        }
    }

    // MARK: - Services

    private var servicesSection: some View {
        Section(appState.isSv ? "Tjänster" : "Services") {
            ForEach(currentServices) { service in
                HStack {
                    VStack(alignment: .leading) {
                        Text(service.name(locale: appState.language))
                            .font(.subheadline)
                        Text(service.priceFormatted)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        Task { await removeService(service.id) }
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel(appState.isSv ? "Ta bort tjänst" : "Remove service")
                }
            }

            Button {
                showAddService = true
            } label: {
                Label(appState.isSv ? "Lägg till tjänst" : "Add service", systemImage: "plus")
                    .font(.subheadline)
            }
            .accessibilityLabel(appState.isSv ? "Lägg till tjänst" : "Add service")
        }
        .sheet(isPresented: $showAddService) {
            NavigationStack {
                List(availableServices.filter { s in !currentServices.contains(where: { $0.id == s.id }) }) { service in
                    Button {
                        Task { await addService(service.id) }
                    } label: {
                        HStack {
                            Text(service.name(locale: appState.language))
                            Spacer()
                            Text(service.priceFormatted)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .navigationTitle(appState.isSv ? "Välj tjänst" : "Select service")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(appState.isSv ? "Stäng" : "Close") { showAddService = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Helpers

    private func dayName(_ day: Int) -> String {
        let svDays = ["", "Måndag", "Tisdag", "Onsdag", "Torsdag", "Fredag", "Lördag", "Söndag"]
        let enDays = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        guard day >= 1 && day <= 7 else { return "" }
        return appState.isSv ? svDays[day] : enDays[day]
    }

    // MARK: - Data Loading

    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await APIClient.shared.get("/api/providers/me", as: ProviderMeResponse.self)
            provider = result
            displayName = result.displayName
            bio = result.bio ?? ""
            bookingMode = result.bookingMode ?? "MANUAL"
            phoneVisible = result.phoneVisible ?? false
            preBookingMessages = result.preBookingMessages ?? false
            acceptSalonBookings = result.acceptSalonBookings ?? true
            workModes = Set(result.workModes ?? [])
            homeVisitCities = result.homeVisitCities ?? []
            currentServices = result.services ?? []
            autoBookRules = result.autoBookRules ?? []

            // Load available services catalog
            if let catalog = try? await APIClient.shared.getNoAuth("/api/services", as: [Service].self) {
                availableServices = catalog
            }
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ladda profilen." : "Failed to load profile."
        }
        isLoading = false
    }

    private func saveProfile() async {
        isSaving = true
        errorMessage = nil
        let body = UpdateProviderBody(
            displayName: displayName,
            bio: bio.isEmpty ? nil : bio,
            bookingMode: bookingMode,
            phoneVisible: phoneVisible,
            acceptSalonBookings: acceptSalonBookings,
            preBookingMessages: preBookingMessages,
            workModes: Array(workModes),
            homeVisitCities: workModes.contains("HOME_VISIT") ? homeVisitCities : nil
        )
        do {
            _ = try await APIClient.shared.patch("/api/providers/me", body: body, as: ProviderMeResponse.self)
            HapticManager.success()
            dismiss()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte spara." : "Failed to save."
            HapticManager.error()
        }
        isSaving = false
    }

    private func addRule() async {
        let body = CreateAutoBookRuleBody(dayOfWeek: newRuleDay, startTime: newRuleStart, endTime: newRuleEnd)
        do {
            let rule = try await APIClient.shared.post("/api/providers/me/auto-book-rules", body: body, as: AutoBookRule.self)
            autoBookRules.append(rule)
            showAddRule = false
            HapticManager.light()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte skapa regel." : "Failed to create rule."
        }
    }

    private func deleteRule(_ ruleId: String) async {
        do {
            try await APIClient.shared.delete("/api/providers/me/auto-book-rules/\(ruleId)")
            autoBookRules.removeAll { $0.id == ruleId }
            HapticManager.light()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ta bort regel." : "Failed to delete rule."
        }
    }

    private func addService(_ serviceId: String) async {
        do {
            _ = try await APIClient.shared.post("/api/providers/me/services", body: AddServiceBody(serviceId: serviceId), as: Service.self)
            if let service = availableServices.first(where: { $0.id == serviceId }) {
                currentServices.append(service)
            }
            showAddService = false
            HapticManager.light()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte lägga till tjänst." : "Failed to add service."
        }
    }

    private func removeService(_ serviceId: String) async {
        do {
            try await APIClient.shared.delete("/api/providers/me/services", body: RemoveServiceBody(serviceId: serviceId))
            currentServices.removeAll { $0.id == serviceId }
            HapticManager.light()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ta bort tjänst." : "Failed to remove service."
        }
    }
}
