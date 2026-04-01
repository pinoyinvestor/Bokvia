import SwiftUI
import Combine

struct ProviderClientDetailView: View {
    let clientUserId: String
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var client: ClientDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var notes: String = ""
    @State private var newTag: String = ""
    @State private var isSaving = false
    @State private var saveDebounceTask: Task<Void, Never>?

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = errorMessage, client == nil {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button(appState.isSv ? "Försök igen" : "Try again") {
                        Task { await loadClient() }
                    }
                    .accessibilityLabel(appState.isSv ? "Försök igen" : "Try again")
                }
            } else if let client = client {
                ScrollView {
                    VStack(spacing: 20) {
                        profileSection(client)
                        toggleButtons(client)
                        statsSection(client)

                        // Built by Christos Ferlachidis & Daniel Hedenberg

                        notesSection
                        tagsSection(client)
                        historySection(client)
                        actionButtons(client)
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle(client?.fullName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadClient() }
    }

    // MARK: - Profile Header

    private func profileSection(_ client: ClientDetail) -> some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: client.avatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.gray200)
                    .overlay(
                        Text(client.initials)
                            .font(.title3.bold())
                            .foregroundStyle(BokviaTheme.gray500)
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())

            Text(client.fullName)
                .font(.title3.bold())

            HStack(spacing: 16) {
                if let phone = client.phone, !phone.isEmpty {
                    Link(destination: URL(string: "tel:\(phone)")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "phone")
                            Text(phone)
                        }
                        .font(.caption)
                        .foregroundStyle(BokviaTheme.accent)
                    }
                    .accessibilityLabel(appState.isSv ? "Ring \(phone)" : "Call \(phone)")
                }
                if let email = client.email, !email.isEmpty {
                    Link(destination: URL(string: "mailto:\(email)")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "envelope")
                            Text(email)
                        }
                        .font(.caption)
                        .foregroundStyle(BokviaTheme.accent)
                    }
                    .accessibilityLabel(appState.isSv ? "Skicka e-post" : "Send email")
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Toggle Buttons

    private func toggleButtons(_ client: ClientDetail) -> some View {
        HStack(spacing: 12) {
            toggleButton(
                icon: "star.fill",
                label: "VIP",
                isActive: client.isVip
            ) {
                await updateClient(ClientUpdateBody(isVip: !client.isVip))
            }

            toggleButton(
                icon: "heart.fill",
                label: appState.isSv ? "Favorit" : "Favorite",
                isActive: client.isFavorite
            ) {
                await updateClient(ClientUpdateBody(isFavorite: !client.isFavorite))
            }

            toggleButton(
                icon: "crown.fill",
                label: appState.isSv ? "Lojal" : "Loyal",
                isActive: client.isLoyal
            ) {
                await updateClient(ClientUpdateBody(isLoyal: !client.isLoyal))
            }
        }
        .padding(.horizontal)
    }

    private func toggleButton(icon: String, label: String, isActive: Bool, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(label)
                    .font(.caption2.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? BokviaTheme.accent : Color(.secondarySystemBackground))
            .foregroundStyle(isActive ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .accessibilityLabel("\(label): \(isActive ? (appState.isSv ? "aktiv" : "active") : (appState.isSv ? "inaktiv" : "inactive"))")
    }

    // MARK: - Stats

    private func statsSection(_ client: ClientDetail) -> some View {
        HStack(spacing: 0) {
            statItem(value: "\(client.totalBookings)", label: appState.isSv ? "Totalt" : "Total")
            Divider().frame(height: 32)
            statItem(value: "\(client.completedBookings)", label: appState.isSv ? "Slutförda" : "Completed")
            Divider().frame(height: 32)
            statItem(value: "\(client.noShows)", label: appState.isSv ? "Uteblivna" : "No-shows")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.isSv ? "Anteckningar" : "Notes")
                .font(.headline)
                .padding(.horizontal)

            TextEditor(text: $notes)
                .frame(minHeight: 80, maxHeight: 150)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .onChange(of: notes) { _, newValue in
                    debounceSaveNotes(newValue)
                }
                .accessibilityLabel(appState.isSv ? "Anteckningar om kund" : "Client notes")

            if isSaving {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                    Text(appState.isSv ? "Sparar..." : "Saving...")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
    }

    private func debounceSaveNotes(_ value: String) {
        saveDebounceTask?.cancel()
        saveDebounceTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await updateClient(ClientUpdateBody(notes: value))
        }
    }

    // MARK: - Tags

    private func tagsSection(_ client: ClientDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.isSv ? "Taggar" : "Tags")
                .font(.headline)
                .padding(.horizontal)

            FlowLayout(client.tags) { tag in
                HStack(spacing: 4) {
                    Text(tag)
                        .font(.caption.weight(.medium))
                    Button {
                        Task { await removeTag(tag, from: client) }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                    }
                    .accessibilityLabel(appState.isSv ? "Ta bort tagg \(tag)" : "Remove tag \(tag)")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(BokviaTheme.accentLight)
                .foregroundStyle(BokviaTheme.accent)
                .clipShape(Capsule())
            }
            .padding(.horizontal)

            HStack {
                TextField(appState.isSv ? "Ny tagg..." : "New tag...", text: $newTag)
                    .textInputAutocapitalization(.never)
                    .font(.subheadline)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    Task { await addTag(to: client) }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(BokviaTheme.accent)
                }
                .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel(appState.isSv ? "Lägg till tagg" : "Add tag")
            }
            .padding(.horizontal)
        }
    }

    private func addTag(to client: ClientDetail) async {
        let tag = newTag.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty else { return }
        var tags = client.tags
        tags.append(tag)
        newTag = ""
        await updateClient(ClientUpdateBody(tags: tags))
    }

    private func removeTag(_ tag: String, from client: ClientDetail) async {
        var tags = client.tags
        tags.removeAll { $0 == tag }
        await updateClient(ClientUpdateBody(tags: tags))
    }

    // MARK: - Booking History

    private func historySection(_ client: ClientDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.isSv ? "Bokningshistorik" : "Booking history")
                .font(.headline)
                .padding(.horizontal)

            if let history = client.bookingHistory, !history.isEmpty {
                ForEach(history) { entry in
                    HStack {
                        Circle()
                            .fill(BokviaTheme.statusColor(for: entry.status))
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.serviceName ?? "")
                                .font(.subheadline.weight(.medium))
                            Text("\(entry.date) · \(entry.startTime)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let price = entry.price {
                            Text("\(Int(price)) kr")
                                .font(.caption.weight(.medium))
                        }
                        StatusBadge(status: entry.status)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            } else {
                Text(appState.isSv ? "Ingen historik ännu" : "No history yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(_ client: ClientDetail) -> some View {
        VStack(spacing: 8) {
            NavigationLink {
                ChatDetailView(userId: client.userId)
            } label: {
                Label(appState.isSv ? "Skicka meddelande" : "Send message", systemImage: "bubble.left")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(BokviaTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityLabel(appState.isSv ? "Skicka meddelande" : "Send message")

            if let phone = client.phone, !phone.isEmpty {
                Link(destination: URL(string: "tel:\(phone)")!) {
                    Label(appState.isSv ? "Ring" : "Call", systemImage: "phone")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .foregroundStyle(.primary)
                .accessibilityLabel(appState.isSv ? "Ring kund" : "Call customer")
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    // MARK: - Data Loading

    private func loadClient() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await APIClient.shared.get("/api/providers/me/clients/\(clientUserId)", as: ClientDetail.self)
            client = result
            notes = result.notes ?? ""
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ladda kundprofil." : "Failed to load client profile."
        }
        isLoading = false
    }

    private func updateClient(_ body: ClientUpdateBody) async {
        isSaving = true
        do {
            let result = try await APIClient.shared.patch("/api/providers/me/clients/\(clientUserId)", body: body, as: ClientDetail.self)
            client = result
            HapticManager.light()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte uppdatera." : "Failed to update."
            HapticManager.error()
        }
        isSaving = false
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: View {
    let items: [String]
    let content: (String) -> AnyView

    init(_ items: [String], @ViewBuilder content: @escaping (String) -> some View) {
        self.items = items
        self.content = { item in AnyView(content(item)) }
    }

    var body: some View {
        var width: CGFloat = 0
        var rows: [[String]] = [[]]

        let _ = items.forEach { item in
            let itemWidth: CGFloat = CGFloat(item.count * 10 + 50)
            if width + itemWidth > UIScreen.main.bounds.width - 32 {
                rows.append([item])
                width = itemWidth
            } else {
                rows[rows.count - 1].append(item)
                width += itemWidth
            }
        }

        VStack(alignment: .leading, spacing: 6) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex], id: \.self) { item in
                        content(item)
                    }
                }
            }
        }
    }
}
