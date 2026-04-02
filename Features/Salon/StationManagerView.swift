import SwiftUI

struct StationManagerView: View {
    @Environment(AppState.self) private var appState
    @State private var stations: [Station] = []
    @State private var teamMembers: [SalonTeamMember] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCreateSheet = false
    @State private var editingStation: Station?
    @State private var stationToDelete: Station?
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }

            if isLoading {
                LoadingView()
            } else if stations.isEmpty {
                emptyState
            } else {
                stationList
            }
        }
        .navigationTitle(appState.isSv ? "Stationer" : "Stations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(appState.isSv ? "Lägg till station" : "Add station")
            }
        }
        .task { await loadData() }
        .refreshable { await loadData() }
        .sheet(isPresented: $showCreateSheet) {
            StationFormSheet(
                station: nil,
                teamMembers: teamMembers,
                isSv: appState.isSv
            ) {
                Task { await loadData() }
            }
        }
        .sheet(item: $editingStation) { station in
            StationFormSheet(
                station: station,
                teamMembers: teamMembers,
                isSv: appState.isSv
            ) {
                Task { await loadData() }
            }
        }
        .alert(
            appState.isSv ? "Ta bort station?" : "Delete station?",
            isPresented: $showDeleteConfirm
        ) {
            Button(appState.isSv ? "Avbryt" : "Cancel", role: .cancel) {}
            Button(appState.isSv ? "Ta bort" : "Delete", role: .destructive) {
                if let station = stationToDelete {
                    Task { await deleteStation(station) }
                }
            }
        } message: {
            Text(appState.isSv
                ? "Denna åtgärd kan inte ångras."
                : "This action cannot be undone.")
        }
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "chair.lounge")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(appState.isSv ? "Inga stationer" : "No stations")
                .font(.headline)
            Text(appState.isSv
                ? "Lägg till stationer för din salong"
                : "Add stations for your salon")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showCreateSheet = true
            } label: {
                Label(appState.isSv ? "Lägg till station" : "Add station", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(BokviaTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var stationList: some View {
        List {
            ForEach(stations) { station in
                stationRow(station)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            stationToDelete = station
                            showDeleteConfirm = true
                        } label: {
                            Label(appState.isSv ? "Ta bort" : "Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editingStation = station
                        } label: {
                            Label(appState.isSv ? "Redigera" : "Edit", systemImage: "pencil")
                        }
                        .tint(BokviaTheme.accent)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { editingStation = station }
            }
        }
        .listStyle(.plain)
    }

    private func stationRow(_ station: Station) -> some View {
        HStack(spacing: 12) {
            // Station image or icon
            if let imageUrl = station.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(BokviaTheme.gray200)
                        .overlay(Image(systemName: "chair.lounge").foregroundStyle(BokviaTheme.gray400))
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(BokviaTheme.accentLight)
                    .overlay(
                        Image(systemName: "chair.lounge")
                            .font(.title3)
                            .foregroundStyle(BokviaTheme.accent)
                    )
                    .frame(width: 56, height: 56)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(station.name)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Circle()
                        .fill(station.isAvailable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(station.isAvailable
                        ? (appState.isSv ? "Ledig" : "Available")
                        : (appState.isSv ? "Upptagen" : "Occupied"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let desc = station.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    if let priceDay = station.pricePerDay {
                        Text("\(Int(priceDay)) kr/\(appState.isSv ? "dag" : "day")")
                            .font(.caption.weight(.medium))
                    }
                    if let priceMonth = station.pricePerMonth {
                        Text("\(Int(priceMonth)) kr/\(appState.isSv ? "mån" : "mo")")
                            .font(.caption.weight(.medium))
                    }
                }

                if let provider = station.assignedProvider {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text(provider.displayName)
                            .font(.caption)
                    }
                    .foregroundStyle(BokviaTheme.accent)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(station.name), \(station.isAvailable ? (appState.isSv ? "ledig" : "available") : (appState.isSv ? "upptagen" : "occupied"))")
    }

    // MARK: - Actions

    private func loadData() async {
        isLoading = true
        errorMessage = nil

        guard let salonId = appState.currentUser?.activeProfileId else {
            errorMessage = appState.isSv ? "Kunde inte hitta salong-ID" : "Could not find salon ID"
            isLoading = false
            return
        }

        async let stationsResult: StationsResponse? = try? await APIClient.shared.get(
            "/api/stations/salon/\(salonId)/list",
            as: StationsResponse.self
        )
        async let teamResult: SalonTeamResponse? = try? await APIClient.shared.get(
            "/api/salons/me/team",
            as: SalonTeamResponse.self
        )

        stations = await stationsResult?.items ?? []
        teamMembers = await teamResult?.items ?? []

        if stations.isEmpty && errorMessage == nil {
            // Not an error, just empty
        }
        isLoading = false
    }

    private func deleteStation(_ station: Station) async {
        errorMessage = nil
        do {
            try await APIClient.shared.delete("/api/stations/\(station.id)")
            HapticManager.success()
            await loadData()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ta bort stationen." : "Failed to delete station."
            HapticManager.error()
        }
    }
}

// MARK: - Station Form Sheet

struct StationFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let station: Station?
    let teamMembers: [SalonTeamMember]
    let isSv: Bool
    let onSaved: () -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var equipmentText = ""
    @State private var pricePerDay = ""
    @State private var pricePerMonth = ""
    @State private var pricingType = "BOTH"
    @State private var category = ""
    @State private var imageUrl = ""
    @State private var isAvailable = true
    @State private var assignedProviderId: String?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var isEditing: Bool { station != nil }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var body: some View {
        NavigationStack {
            Form {
                Section(isSv ? "Grundinfo" : "Basic info") {
                    TextField(isSv ? "Namn" : "Name", text: $name)
                    TextField(isSv ? "Beskrivning" : "Description", text: $description)
                    TextField(isSv ? "Kategori" : "Category", text: $category)
                    TextField(isSv ? "Bild-URL" : "Image URL", text: $imageUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }

                Section(isSv ? "Utrustning" : "Equipment") {
                    TextField(
                        isSv ? "Stol, Spegel, Torkhuv (kommaseparerat)" : "Chair, Mirror, Hood dryer (comma separated)",
                        text: $equipmentText
                    )
                }

                Section(isSv ? "Prissättning" : "Pricing") {
                    Picker(isSv ? "Prismodell" : "Pricing model", selection: $pricingType) {
                        Text(isSv ? "Per dag" : "Per day").tag("DAILY")
                        Text(isSv ? "Per månad" : "Per month").tag("MONTHLY")
                        Text(isSv ? "Båda" : "Both").tag("BOTH")
                    }
                    if pricingType == "DAILY" || pricingType == "BOTH" {
                        TextField(isSv ? "Pris per dag (kr)" : "Price per day (kr)", text: $pricePerDay)
                            .keyboardType(.decimalPad)
                    }
                    if pricingType == "MONTHLY" || pricingType == "BOTH" {
                        TextField(isSv ? "Pris per månad (kr)" : "Price per month (kr)", text: $pricePerMonth)
                            .keyboardType(.decimalPad)
                    }
                }

                Section(isSv ? "Status" : "Status") {
                    Toggle(isSv ? "Tillgänglig" : "Available", isOn: $isAvailable)

                    if !teamMembers.isEmpty {
                        Picker(isSv ? "Tilldelad" : "Assigned to", selection: $assignedProviderId) {
                            Text(isSv ? "Ingen" : "None").tag(nil as String?)
                            ForEach(teamMembers) { member in
                                Text(member.displayName).tag(member.id as String?)
                            }
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing
                ? (isSv ? "Redigera station" : "Edit station")
                : (isSv ? "Ny station" : "New station"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isSv ? "Avbryt" : "Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSv ? "Spara" : "Save") {
                        Task { await save() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .onAppear { populateFields() }
        }
    }

    private func populateFields() {
        guard let s = station else { return }
        name = s.name
        description = s.description ?? ""
        equipmentText = s.equipment?.joined(separator: ", ") ?? ""
        pricePerDay = s.pricePerDay.map { "\(Int($0))" } ?? ""
        pricePerMonth = s.pricePerMonth.map { "\(Int($0))" } ?? ""
        pricingType = s.pricingType ?? "BOTH"
        category = s.category ?? ""
        imageUrl = s.imageUrl ?? ""
        isAvailable = s.isAvailable
        assignedProviderId = s.assignedProviderId
    }

    private func save() async {
        isSaving = true
        errorMessage = nil

        let equipmentList = equipmentText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if isEditing, let stationId = station?.id {
            let body = UpdateStationRequest(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.isEmpty ? nil : description,
                equipment: equipmentList.isEmpty ? nil : equipmentList,
                pricePerDay: Double(pricePerDay),
                pricePerMonth: Double(pricePerMonth),
                pricingType: pricingType,
                isAvailable: isAvailable,
                category: category.isEmpty ? nil : category,
                imageUrl: imageUrl.isEmpty ? nil : imageUrl
            )
            do {
                _ = try await APIClient.shared.patch("/api/stations/\(stationId)", body: body, as: Station.self)

                // Handle assignment change
                if assignedProviderId != station?.assignedProviderId {
                    let assignBody = AssignStationRequest(providerId: assignedProviderId)
                    _ = try await APIClient.shared.patch("/api/stations/\(stationId)/assign", body: assignBody, as: Station.self)
                }

                HapticManager.success()
                onSaved()
                dismiss()
            } catch {
                errorMessage = isSv ? "Kunde inte uppdatera stationen." : "Failed to update station."
                HapticManager.error()
            }
        } else {
            let body = CreateStationRequest(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.isEmpty ? nil : description,
                equipment: equipmentList.isEmpty ? nil : equipmentList,
                pricePerDay: Double(pricePerDay),
                pricePerMonth: Double(pricePerMonth),
                pricingType: pricingType,
                category: category.isEmpty ? nil : category,
                imageUrl: imageUrl.isEmpty ? nil : imageUrl
            )
            do {
                let newStation = try await APIClient.shared.post("/api/stations", body: body, as: Station.self)
                // Assign provider if selected
                if let providerId = assignedProviderId {
                    let assignBody = AssignStationRequest(providerId: providerId)
                    _ = try await APIClient.shared.patch("/api/stations/\(newStation.id)/assign", body: assignBody, as: Station.self)
                }
                HapticManager.success()
                onSaved()
                dismiss()
            } catch {
                errorMessage = isSv ? "Kunde inte skapa stationen." : "Failed to create station."
                HapticManager.error()
            }
        }
        isSaving = false
    }
}
